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

package AIR2::ActivityMaster;
use strict;
use base qw(AIR2::DB);

our $QUERY_RESPONSE = 4;

__PACKAGE__->meta->setup(
    table => 'activity_master',

    columns => [
        actm_id     => { type => 'serial', not_null => 1 },
        actm_status => {
            type     => 'character',
            default  => '',
            length   => 1,
            not_null => 1
        },
        actm_name => {
            type     => 'varchar',
            default  => '',
            length   => 128,
            not_null => 1
        },
        actm_type => {
            type     => 'character',
            default  => '',
            length   => 1,
            not_null => 1
        },
        actm_table_type => { type => 'varchar', length => 1 },
        actm_contact_rule_flag =>
            { type => 'integer', default => 1, not_null => 1 },
        actm_disp_seq => { type => 'integer', default => '0', not_null => 1 },
        actm_cre_user => { type => 'integer', not_null => 1 },
        actm_upd_user => { type => 'integer' },
        actm_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        actm_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['actm_id'],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { actm_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { actm_upd_user => 'user_id' },
        },
    ],

    relationships => [
        project_activity => {
            class      => 'AIR2::ProjectActivity',
            column_map => { actm_id => 'pa_actm_id' },
            type       => 'one to many',
        },

        src_activity => {
            class      => 'AIR2::SrcActivity',
            column_map => { actm_id => 'sact_actm_id' },
            type       => 'one to many',
        },
    ],
);

my %outgoing_codes = map { $_ => $_ } qw(
    O
    A
);

sub is_outgoing {
    my $self = shift;
    return exists $outgoing_codes{ $self->actm_type };
}

1;

