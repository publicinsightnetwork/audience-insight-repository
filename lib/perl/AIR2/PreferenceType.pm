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

package AIR2::PreferenceType;

use strict;

use base qw(AIR2::DB);

# preferred language
our $LANG_ID = 4;

__PACKAGE__->meta->setup(
    table => 'preference_type',

    columns => [
        pt_id   => { type => 'serial', not_null => 1 },
        pt_uuid => {
            type     => 'character',
            length   => 12,
            not_null => 1
        },
        pt_name => {
            type     => 'varchar',
            length   => 128,
            not_null => 1
        },
        pt_identifier => {
            type     => 'varchar',
            length   => 128,
            not_null => 1
        },
        pt_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        pt_cre_user => { type => 'integer', not_null => 1 },
        pt_upd_user => { type => 'integer' },
        pt_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        pt_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['pt_id'],

    unique_keys => [ ['pt_uuid'], ['pt_identifier'] ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { pt_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { pt_upd_user => 'user_id' },
        },
    ],

    relationships => [
        preference_type_values => {
            class      => 'AIR2::PreferenceTypeValue',
            column_map => { pt_id => 'ptv_pt_id' },
            type       => 'one to many',
        },
    ],
);

1;

