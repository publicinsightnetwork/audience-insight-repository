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

package AIR2::SrcEmail;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'src_email',

    columns => [
        sem_id     => { type => 'serial',    not_null => 1 },
        sem_uuid   => { type => 'character', length   => 12, not_null => 1 },
        sem_src_id => { type => 'integer',   default  => '0', not_null => 1 },
        sem_primary_flag =>
            { type => 'integer', default => 0, not_null => 1 },
        sem_context => { type => 'character', length => 1 },
        sem_email   => {
            type     => 'varchar',
            length   => 255,
            not_null => 1
        },
        sem_effective_date => { type => 'date' },
        sem_expire_date    => { type => 'date' },
        sem_status         => {
            type     => 'character',
            default  => 'G',
            length   => 1,
            not_null => 1
        },
        sem_cre_user => { type => 'integer', not_null => 1 },
        sem_upd_user => { type => 'integer' },
        sem_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        sem_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['sem_id'],

    unique_keys => [ ['sem_uuid'], ['sem_email'] ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { sem_cre_user => 'user_id' },
        },

        source => {
            class       => 'AIR2::Source',
            key_columns => { sem_src_id => 'src_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { sem_upd_user => 'user_id' },
        },
    ],

    relationships => [
        src_org_emails => {
            class      => 'AIR2::SrcOrgEmail',
            column_map => { sem_id => 'soe_sem_id' },
            type       => 'one to many',
        },

        lyris_src_org_emails => {
            class      => 'AIR2::SrcOrgEmail',
            column_map => { sem_id => 'soe_sem_id' },
            query_args => [ soe_type => 'L' ],
            type       => 'one to many',
        },

        mailchimp_src_org_emails => {
            class      => 'AIR2::SrcOrgEmail',
            column_map => { sem_id => 'soe_sem_id' },
            query_args => [ soe_type => 'M' ],
            type       => 'one to many',
        },
    ],

);

# determine "who is primary" on insert
sub insert {
    my $self = shift;

    my $src_has_primary = $self->sem_primary_flag;
    for my $sem ( $self->source->emails ) {
        if ( $sem->sem_id ) {
            if ($src_has_primary) {
                $sem->sem_primary_flag(0);
                $sem->save();
            }
            $src_has_primary = 1 if $sem->sem_primary_flag;
        }
    }
    $self->sem_primary_flag(1) unless $src_has_primary;

    return $self->SUPER::insert(@_);
}

sub unsubscribe {
    my $self = shift;
    $self->sem_status('U');
    $self->save();
}

sub bounce {
    my $self = shift;
    $self->sem_status('B');
    $self->save();
}

sub confirm_bad {
    my $self = shift;
    $self->sem_status('C');
    $self->save();
}

sub confirm_good {
    my $self = shift;
    $self->sem_status('G');
    $self->save();
}

sub subscribe {
    shift->confirm_good();
}

1;

