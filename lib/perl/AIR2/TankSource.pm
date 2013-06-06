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

package AIR2::TankSource;
use strict;
use base qw(AIR2::DB);
use Carp;
use JSON;
use Data::Dump qw( dump );
use AIR2::Discriminator;
use Class::Inspector;

my $STATUS_NEW      = 'N';
my $STATUS_CONFLICT = 'C';
my $STATUS_RESOLVED = 'R';
my $STATUS_LOCKED   = 'L';
my $STATUS_DONE     = 'D';
my $STATUS_ERROR    = 'E';

my @STATS_READY = ( $STATUS_NEW, $STATUS_CONFLICT, $STATUS_ERROR, );
my @STATS_DONE = ( $STATUS_RESOLVED, $STATUS_DONE, );

__PACKAGE__->meta->setup(
    table => 'tank_source',

    columns => [
        tsrc_id      => { type => 'serial',  not_null => 1 },
        tsrc_tank_id => { type => 'integer', not_null => 1 },
        tsrc_status  => {
            type     => 'character',
            default  => 'N',
            length   => 1,
            not_null => 1
        },
        tsrc_created_flag => {
            type     => 'integer',
            default  => 0,
            not_null => 1
        },
        tsrc_errors        => { type => 'text',      length    => 65535 },
        tsrc_cre_user      => { type => 'integer',   not_null  => 1 },
        tsrc_upd_user      => { type => 'integer' },
        tsrc_cre_dtim      => { type => 'datetime',  not_null  => 1 },
        tsrc_upd_dtim      => { type => 'datetime' },
        tsrc_tags          => { type => 'varchar',   length    => 255 },
        src_id             => { type => 'integer' },
        src_uuid           => { type => 'character', length    => 12 },
        src_username       => { type => 'varchar',   length    => 255 },
        src_first_name     => { type => 'varchar',   length    => 64 },
        src_last_name      => { type => 'varchar',   length    => 64 },
        src_middle_initial => { type => 'character', length    => 1 },
        src_pre_name       => { type => 'varchar',   length    => 64 },
        src_post_name      => { type => 'varchar',   length    => 64 },
        src_status         => { type => 'character', length    => 1 },
        src_channel        => { type => 'character', length    => 1 },
        smadd_uuid         => { type => 'character', length    => 12 },
        smadd_primary_flag => { type => 'integer' },
        smadd_context      => { type => 'character', length    => 1 },
        smadd_line_1       => { type => 'varchar',   length    => 128 },
        smadd_line_2       => { type => 'varchar',   length    => 128 },
        smadd_city         => { type => 'varchar',   length    => 128 },
        smadd_state        => { type => 'character', length    => 2 },
        smadd_cntry        => { type => 'character', length    => 2 },
        smadd_zip          => { type => 'varchar',   length    => 10 },
        smadd_lat          => { type => 'float',     precision => 32 },
        smadd_long         => { type => 'float',     precision => 32 },
        sph_uuid           => { type => 'character', length    => 12 },
        sph_primary_flag   => { type => 'integer' },
        sph_context        => { type => 'character', length    => 1 },
        sph_country        => { type => 'character', length    => 3 },
        sph_number         => { type => 'varchar',   length    => 16 },
        sph_ext            => { type => 'varchar',   length    => 12 },
        sem_uuid           => { type => 'character', length    => 12 },
        sem_primary_flag   => { type => 'integer' },
        sem_context        => { type => 'character', length    => 1 },
        sem_email          => { type => 'varchar',   length    => 255 },
        sem_effective_date => { type => 'date' },
        sem_expire_date    => { type => 'date' },
        suri_primary_flag  => { type => 'integer' },
        suri_context       => { type => 'character', length    => 1 },
        suri_type          => { type => 'character', length    => 1 },
        suri_value         => { type => 'varchar',   length    => 255 },
        suri_handle        => { type => 'varchar',   length    => 128 },
        suri_feed          => { type => 'varchar',   length    => 255 },
        srcan_type         => { type => 'character', length    => 1 },
        srcan_value        => { type => 'text',      length    => 65535 },
    ],

    primary_key_columns => ['tsrc_id'],

    foreign_keys => [
        tank => {
            class       => 'AIR2::Tank',
            key_columns => { tsrc_tank_id => 'tank_id' },
        },
        source => {
            class       => 'AIR2::Source',
            key_columns => { src_id => 'src_id' },
        },
    ],

    relationships => [
        facts => {
            class      => 'AIR2::TankFact',
            column_map => { tsrc_id => 'tf_tsrc_id' },
            type       => 'one to many',
        },
        vitas => {
            class      => 'AIR2::TankVita',
            column_map => { tsrc_id => 'tv_tsrc_id' },
            type       => 'one to many',
        },
        preferences => {
            class      => 'AIR2::TankPreference',
            column_map => { tsrc_id => 'tp_tsrc_id' },
            type       => 'one to many',
        },
        response_sets => {
            class      => 'AIR2::TankResponseSet',
            column_map => { tsrc_id => 'trs_tsrc_id' },
            type       => 'one to many',
        },
        responses => {
            class      => 'AIR2::TankResponse',
            column_map => { tsrc_id => 'tr_tsrc_id' },
            type       => 'one to many',
        },
    ],
);

sub save {
    my $self  = shift;
    my $phone = AIR2::Utils::parse_phone_number( $self->sph_number );
    $phone->{number} =~ s/\D//g;
    $self->sph_number( $phone->{number} );
    if ( $phone->{ext} ) {

        # if already set, check that it is different
        # set based on unknown rules
        $self->sph_ext( $phone->{ext} );

    }

    my $zip = $self->smadd_zip;
    if (length($zip) == 4) {
        $self->smadd_zip('0'.$zip);
    }

    my $ret = $self->SUPER::save(@_);
    return $ret;
}

sub apply_defaults {
    my $self   = shift;
    my $is_new = shift;

    # avoid setting any UUID columns
    my @col_undefs;
    for my $column ( $self->meta->columns ) {
        my $name       = $column->name;
        my $set_method = $column->mutator_method_name;
        my $get_method = $column->accessor_method_name;

        if ( $name =~ m/_uuid$/ && !defined $self->$get_method ) {
            push( @col_undefs, $set_method );
        }
    }

    # call AIR::DB method
    $self->SUPER::apply_defaults($is_new);

    # unset any default-set uuid columns
    for my $set_method (@col_undefs) {
        $self->$set_method(undef);
    }
}

=head2 set_conflicts( I<conflicts>, I<initial> )

Set json-encoded conflict data in the tsrc_errors field

=cut

sub set_conflicts {
    my $self      = shift;
    my $conflicts = shift;
    my $initial   = shift;
    my $ops       = shift;

    # attempt to set json conflict data
    my $data = {};
    eval { $data = decode_json( $self->tsrc_errors ) || {}; };
    $data->{initial} = $conflicts if $initial;
    $data->{last}     = $conflicts unless $initial;
    $data->{last_ops} = $ops       unless $initial;
    $self->tsrc_errors( encode_json($data) );

    # sanity check
    if ( !$data->{initial} ) {
        $self->tsrc_errors('No initial conflict data set!!!');
        $self->tsrc_status($STATUS_ERROR);
    }
}

=head2 identify_source

This tank_source will attempt to identify itself.  If an existing source cannot
be found, it will try to create a new one.  Changes will be saved.

=cut

sub identify_source {
    my $self = shift;
    if ( $self->src_id ) {
        my $src = AIR2::Source->new( src_id => $self->src_id );
        $src->load_speculative;
        croak 'Invalid src_id(' . $self->src_id . ')' unless $src->src_uuid;
    }
    elsif ( $self->src_uuid ) {
        my $src = AIR2::Source->new( src_uuid => $self->src_uuid );
        $src->load_speculative;
        croak 'Invalid src_uuid(' . $self->src_uuid . ')' unless $src->src_id;
        $self->src_id( $src->src_id );
        $self->save();
    }
    elsif ( $self->src_username ) {
        my $src = AIR2::Source->new( src_username => $self->src_username );
        $src->load_speculative();
        unless ( $src->src_id ) {
            $src->save();
            $self->tsrc_created_flag(1);
        }
        $self->src_id( $src->src_id );
        $self->save();
    }
    elsif ( $self->sem_email ) {
        my $eml = AIR2::SrcEmail->new( sem_email => $self->sem_email );
        $eml->load_speculative();
        if ( $eml->sem_id ) {
            $self->src_id( $eml->sem_src_id );
            $self->save();
        }
        else {
            my $uuid  = lc AIR2::Utils->random_str();
            my $uname = lc $self->sem_email;

            # super-special domain
            if ( $uname =~ m/\@nosuchemail.org$/ ) {
                $uname = $uuid . '@nosuchemail.org';
                $self->sem_email($uname);
                $self->src_username($uname);
            }

            # don't duplicate usernames!!
            my $dup = AIR2::Source->new( src_username => $uname );
            $dup->load_speculative();
            if ( $dup->src_id ) {
                $uname = $uuid . '@' . $uname;
            }

            # create a new source
            my $src = AIR2::Source->new(
                src_uuid     => $uuid,
                src_username => $uname
            );
            $src->save();

            # update self
            $self->src_id( $src->src_id );
            $self->tsrc_created_flag(1);
            $self->save();
        }
    }
    else {
        my $ident_columns = 'src_id, src_uuid, src_username or src_email';
        croak "No identifier! Must provide $ident_columns.";
    }
}

=head2 discriminate( I<tsrc_id>, I<operations>, I<no_tank_status_update> )

Optionally static method that moves a tank_source into the actual
database tables.  Will croak if the row is locked.  Returns the ending status
of the tank_source.

For rows in conflict status, you may pass in a set of operations to apply
when moving data (update, ignore, add-as-primary, etc).  The conflicts (stored
in tsrc_errors) will only be set on NEW rows, so subsequent attempts to resolve
conflicts will not alter the tsrc_errors.

=cut

sub discriminate {
    my $self = shift;
    if ( $self eq 'AIR2::TankSource' ) {
        my $tsid = shift or die "static calls must include a tsrc_id";
        $self = AIR2::TankSource->new( tsrc_id => $tsid )->load;
    }
    my $ops                  = shift;
    my $skip_tank_status_upd = shift;
    my $start                = $self->tsrc_status;

    # make sure we have a valid status to lock the row
    if ( grep { $_ eq $start } @STATS_DONE ) {
        return $start;
    }
    unless ( grep { $_ eq $start } @STATS_READY ) {
        croak "Unable to discriminate row with tsrc_status($start)";
    }
    if ( $ops && $start ne $STATUS_CONFLICT ) {
        croak "Resolver operations may only be used on conflict rows";
    }
    $self->tsrc_status($STATUS_LOCKED);
    $self->save();

    # run a first transaction to identify and opt-into orgs (commit changes)
    my $db      = $self->db->get_write_handle();
    my $idented = $db->do_transaction(
        sub {
            $self->identify_source();
            $self->source->load(
                with_objects => [
                    qw(aliases emails facts mail_addresses phone_numbers src_orgs vitas preferences)
                ],
                multi_many_ok => 1,
            );
            AIR2::Discriminator->organizations($self);
            $self->source->save();    # updates src_org_cache/src_status
        }
    );
    if ( !$idented ) {
        $self->tsrc_status($STATUS_ERROR);
        $self->tsrc_errors( $db->error );
    }
    else {

        # run a second transaction to catch conflicts
        my %conflicts;
        my $it_worked = $db->do_transaction(
            sub {

                # conflict-throwing updates
                AIR2::Discriminator->email( $self, $ops, \%conflicts );
                AIR2::Discriminator->phone( $self, $ops, \%conflicts );
                AIR2::Discriminator->address( $self, $ops, \%conflicts );
                AIR2::Discriminator->fact( $self, $ops, \%conflicts );
                AIR2::Discriminator->vita( $self, $ops, \%conflicts );
                AIR2::Discriminator->preference( $self, $ops, \%conflicts );

                # made it this far! move submissions, and activity
                AIR2::Discriminator->tags($self);
                AIR2::Discriminator->submissions($self);
                AIR2::Discriminator->activity($self);

                # saving source sets src_status/src_org_cache, so DO IT LAST
                AIR2::Discriminator->source( $self, $ops, \%conflicts );

                # abort the transaction if there are any conflicts
                croak "unresolved conflicts exist" if %conflicts;
            }
        );

        # unlock row
        if ($it_worked) {
            if ( $start eq $STATUS_NEW || $start eq $STATUS_ERROR ) {
                $self->tsrc_status($STATUS_DONE);
                $self->tsrc_errors(undef);
            }
            else {
                $self->tsrc_status($STATUS_RESOLVED);
                $self->tsrc_errors(undef);
            }
        }
        else {
            if ( $db->error =~ m/unresolved conflicts exist/ ) {
                my $is_initial
                    = ( $start eq $STATUS_NEW || $start eq $STATUS_ERROR );
                $self->tsrc_status($STATUS_CONFLICT);
                $self->set_conflicts( \%conflicts, $is_initial, $ops );
            }
            else {
                $self->tsrc_status($STATUS_ERROR);

                # TODO: trim the return to hide file and linenum in DEV
                my $msg = $db->error;

                #$msg =~ s/^do_transaction\(\) failed \- //s;
                #$msg =~ s/ at \/[\w\/\.]+ line \d+\.?.*$//s;
                $self->tsrc_errors($msg);
            }
        }
    }
    $self->save();

    # update the status (unless Tank.pm tells us to skip it)
    unless ($skip_tank_status_upd) {
        $self->tank->update_status();
    }

    # return the new status
    return $self->tsrc_status;
}

1;
