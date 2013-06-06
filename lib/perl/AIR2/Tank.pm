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

package AIR2::Tank;
use strict;
use base qw(AIR2::DB);
use Carp;
use JSON;
use Data::Dump qw( dump );

# status
my $STATUS_TSRC_ERRORS    = 'E';
my $STATUS_TSRC_CONFLICTS = 'C';
my $STATUS_READY          = 'R';
my $STATUS_LOCKED         = 'L';
my $STATUS_LOCKED_ERROR   = 'K';

my @STATS_READY
    = ( $STATUS_TSRC_ERRORS, $STATUS_TSRC_CONFLICTS, $STATUS_READY, );

__PACKAGE__->meta->setup(
    table => 'tank',

    columns => [
        tank_id   => { type => 'serial', not_null => 1 },
        tank_uuid => {
            type     => 'character',
            default  => '',
            length   => 12,
            not_null => 1
        },
        tank_name    => { type => 'varchar', length  => 255, },
        tank_user_id => { type => 'integer', default => '', not_null => 1 },
        tank_notes   => { type => 'text',    length  => 65535 },
        tank_meta    => { type => 'text',    length  => 65535 },
        tank_type => {
            type     => 'character',
            default  => '',
            length   => 1,
            not_null => 1
        },
        tank_status => {
            type     => 'character',
            default  => 'R',
            length   => 1,
            not_null => 1
        },
        tank_xuuid    => { type => 'varchar',  length   => 255 },
        tank_errors   => { type => 'text',     length   => 65535 },
        tank_cre_user => { type => 'integer' },
        tank_upd_user => { type => 'integer' },
        tank_cre_dtim => { type => 'datetime', not_null => 1 },
        tank_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['tank_id'],

    unique_key => ['tank_uuid'],

    foreign_keys => [
        user => {
            class       => 'AIR2::User',
            key_columns => { tank_user_id => 'user_id' },
        },
    ],

    relationships => [
        sources => {
            class      => 'AIR2::TankSource',
            column_map => { tank_id => 'tsrc_tank_id' },
            type       => 'one to many',
        },

        orgs => {
            class      => 'AIR2::TankOrg',
            column_map => { tank_id => 'to_tank_id' },
            type       => 'one to many',
        },

        activities => {
            class      => 'AIR2::TankActivity',
            column_map => { tank_id => 'tact_tank_id', },
            type       => 'one to many',
        },
    ],
);

sub contains_source {
    my $self = shift;
    my $tsrc = shift or croak "TankSource required";
    for my $ts ( @{ $self->sources } ) {
        if ( $ts->sem_email eq $tsrc->sem_email ) {
            return $ts;
        }
    }
    return 0;
}

sub get_lock {
    my $self    = shift;
    my $tank_id = $self->tank_id;
    my $dbh     = $self->db->get_write_handle->retain_dbh;

    # get lock
    my $rdy = join ',', map {qq/'$_'/} @STATS_READY;
    my $lk  = $STATUS_LOCKED;
    my $whr = "tank_status in ($rdy) and tank_id=$tank_id";
    my $n   = $dbh->do("update tank set tank_status='$lk' where $whr");
    return ( $n == 1 );
}

sub update_status {
    my $self    = shift;
    my $tank_id = $self->tank_id;
    my $dbh     = $self->db->get_write_handle->retain_dbh;

    # Only concerned with errors/conflicts. Locked rows may be legitimately
    # used by another process.
    my $sel = "select tsrc_status, count(*) as num from tank_source where "
        . "tsrc_tank_id=$tank_id group by tsrc_status";
    my $tsrcs = $dbh->selectall_hashref( $sel, 'tsrc_status' );
    if ( $tsrcs->{'E'} ) {
        $self->tank_errors(undef);
        $self->tank_status($STATUS_TSRC_ERRORS);
    }
    elsif ( $tsrcs->{'C'} ) {
        $self->tank_errors(undef);
        $self->tank_status($STATUS_TSRC_CONFLICTS);
    }
    else {
        $self->tank_errors(undef);
        $self->tank_status($STATUS_READY);
    }
    $self->save();
}

=head2 discriminate( I<tank_id> )

Optionally static method that attempts to move tank_sources into the actual
database tables.  Returns a hashref report if the tank locked, ran, and
unlocked successfully.  Otherwise returns 0, and tank is left in a locked
state.  (Or maybe it started in a locked state).  The tank_errors should be
interrogated to find out why the tank did not unlock.

=cut

sub discriminate {
    my $self = shift;
    if ( $self eq 'AIR2::Tank' ) {
        my $tid = shift or croak "static calls must include a tank_id";
        $self = AIR2::Tank->new( tank_id => $tid )->load;
    }
    my $tank_id = $self->tank_id;
    my %report  = (
        submissions => [],
        done_upd    => 0,
        done_cre    => 0,
        conflict    => 0,
        error       => 0,
        skipped     => 0,
    );

    # run as the tank-user
    AIR2::DB->set_current_user( $self->user );

    # lock the tank (and verify no tank_sources are locked)
    return 0 unless $self->get_lock();

    # We theoretically got the lock! Any exceptions that happen after this are
    # FATAL and should be logged to tank_errors. The tank STAYS LOCKED!
    my $last_tsrc_id = 0;
    eval {
        for my $tsrc ( @{ $self->sources } ) {
            $last_tsrc_id = $tsrc->tsrc_id;

            # only process new rows
            if ( $tsrc->tsrc_status eq 'N' ) {
                my $newstat = $tsrc->discriminate( undef, 1 );

                if ( $newstat eq 'D' or $newstat eq 'R' ) {
                    if ( $tsrc->tsrc_created_flag ) {
                        $report{done_cre}++;
                    }
                    else {
                        $report{done_upd}++;
                    }
                    push @{ $report{submissions} },
                        map { $_->srs_uuid } @{ $tsrc->response_sets };
                }
                elsif ( $newstat eq 'C' ) {
                    $report{conflict}++;
                }
                elsif ( $newstat eq 'E' ) {
                    $report{error}++;
                }
                else {
                    # how the heck did this happen?
                    croak "Row ended with status of '$newstat'!!??!";
                }
            }
            else {
                $report{skipped}++;
            }
        }
    };

    # stay uber-locked, if we caught an error
    if ($@) {
        $self->tank_errors("Error on tank_source($last_tsrc_id) - $@");
        $self->tank_status($STATUS_LOCKED_ERROR);
        $self->save();
        return 0;
    }

    # unlock and return the report
    $self->update_status();
    return \%report;
}

1;

