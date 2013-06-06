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

package AIR2::PreferenceTypeValue;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'preference_type_value',

    columns => [
        ptv_id    => { type => 'serial',  not_null => 1 },
        ptv_pt_id => { type => 'integer', default  => '0', not_null => 1 },
        ptv_uuid => {
            type     => 'character',
            length   => 12,
            not_null => 1
        },
        ptv_seq    => { type => 'integer', default => 10, not_null => 1 },
        ptv_value  => { type => 'varchar', length  => 255 },
        ptv_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        ptv_cre_user => { type => 'integer', not_null => 1 },
        ptv_upd_user => { type => 'integer' },
        ptv_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        ptv_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['ptv_id'],

    unique_key => ['ptv_uuid'],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { ptv_cre_user => 'user_id' },
        },

        preference_type => {
            class       => 'AIR2::PreferenceType',
            key_columns => { ptv_pt_id => 'pt_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { ptv_upd_user => 'user_id' },
        },
    ],

    relationships => [
        src_preference => {
            class      => 'AIR2::SrcPreference',
            column_map => { ptv_id => 'sp_ptv_id' },
            type       => 'one to many',
        },
    ],
);

1;

