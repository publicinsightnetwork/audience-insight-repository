###########################################################################
#
#   Copyright 2010 American Public Media Group
#
#   This file is part of AIR2.
#
#   AIR2 is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   AIR2 is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
#
###########################################################################

package AIR2::JobQueue;

use strict;
use base qw(AIR2::DB);
use Carp;
use IPC::Cmd ();
use AIR2::Config;

__PACKAGE__->meta->setup(
    table => 'job_queue',

    columns => [
        jq_id               => { type => 'serial',   not_null => 1 },
        jq_host             => { type => 'varchar',  length   => 255, },
        jq_pid              => { type => 'integer', },
        jq_job              => { type => 'text',     length   => 65535 },
        jq_error_msg        => { type => 'text',     length   => 65535, },
        jq_cre_user         => { type => 'integer',  not_null => 1 },
        jq_cre_dtim         => { type => 'datetime', not_null => 1, },
        jq_start_after_dtim => { type => 'datetime', },
        jq_start_dtim       => { type => 'datetime' },
        jq_complete_dtim    => { type => 'datetime' },
    ],

    primary_key_columns => ['jq_id'],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { jq_cre_user => 'user_id' },
        },

    ],

);

=head2 add_job( I<cmd>[, I<start_after>] )

Class method. Creates a new object for I<cmd> and returns $jobqueue object.

Optional I<start_after> value should be a valid value for jq_start_after_dtim.

=cut

sub add_job {
    my $class = shift;
    my $cmd   = shift or croak "cmd required";
    my $after = shift;
    my $self  = $class->new( jq_job => $cmd, jq_start_after_dtim => $after );
    $self->save();
    return $self;
}

sub run {
    my $self = shift;
    my $cmd  = $self->jq_job;

    my $air2_root = AIR2::Config::get_app_root();
    my $perl      = $^X;
    my $php       = AIR2::Config::get_php_path();

    # simple interpolation
    $cmd =~ s/PHP /$php /;
    $cmd =~ s/PERL /$perl /;
    $cmd =~ s/AIR2_ROOT/$air2_root/g;

    if ( !$cmd ) {
        croak "jq_job is empty for jq_id " . $self->jq_id;
    }

    my $debug = $ENV{AIR2_DEBUG} || 0;

    # job meta
    $self->jq_pid($$);
    $self->jq_host( AIR2::Config->get_hostname() );
    $self->jq_start_dtim( time() );
    $self->save();

    my ( $success, $error_msg, $full_buf, $stdout_buf, $stderr_buf )
        = IPC::Cmd::run( command => $cmd, verbose => $debug );

    #warn "success=$success error_msg=$error_msg \$\?=$? \$\!=$!\n";

    $self->jq_complete_dtim( time() );

    if ( !$success ) {

        # truncate any overly-long error messages
        my $jq_error_msg = join( "\n", $error_msg, @$full_buf );
        if ( length $jq_error_msg > 65535 ) {
            my $cmd_err = join( "\n", @$full_buf );
            $cmd_err = substr( $cmd_err, length($cmd_err) - 60000, 60000 );
            $jq_error_msg = join( "\n", $error_msg, $cmd_err );
        }

        $self->jq_error_msg($jq_error_msg);
    }

    # since this can be a long-running process, ping the server
    # before we try and save.
    if ( !$self->db->dbh->ping ) {

        # Refresh db connection.
        $self->db->dbh(undef);
    }

    $self->save();

    if ( !$success ) {
        if ($debug) {
            warn "$cmd failed: " . $self->jq_error_msg() . "\n";
        }
    }

    return $success;
}

sub lock {
    my $self = shift;
    if ( $self->is_locked ) {
        croak sprintf( "job %s is already locked", $self->jq_id );
    }
    $self->jq_start_dtim( time() );
    $self->save();
}

sub get_queued {
    my $self   = shift;              # object or class method
    my $queued = $self->fetch_all(
        query => [
            jq_start_dtim       => undef,
            jq_start_after_dtim => { le => [ undef, time() ] }
        ],
        sort_by => 'jq_cre_dtim ASC'
    );
    return $queued;
}

sub get_queued_with_locks {
    my $self = shift;

    # TODO race condition here if we ran multiple processes
    # simultaneously, since between fetch and lock another fetch
    # could happen.
    my $queued = $self->get_queued();
    for my $job (@$queued) {
        $job->lock();
    }
    return $queued;
}

sub get_locked {
    my $self   = shift;
    my $locked = $self->fetch_all(
        logic => 'AND',
        query => [
            '!jq_start_dtim' => undef,    # is not null
            jq_complete_dtim => undef,    # is null
        ],
        sort_by => 'jq_cre_dtim ASC'
    );
    return $locked;
}

sub is_locked {
    my $self = shift;
    if ( $self->jq_start_dtim && !$self->jq_complete_dtim ) {
        return 1;
    }
    else {
        return 0;
    }
}

1;

