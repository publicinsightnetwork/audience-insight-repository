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

package AIR2::SrcUri;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'src_uri',

    columns => [
        suri_id     => { type => 'serial',  not_null => 1 },
        suri_src_id => { type => 'integer', default  => '0', not_null => 1 },
        suri_primary_flag =>
            { type => 'integer', default => 1, not_null => 1 },
        suri_context => { type => 'character', length => 1 },
        suri_type    => {
            type     => 'character',
            default  => '',  # TODO
            length   => 1,
            not_null => 1
        },
        suri_value => {
            type     => 'varchar',
            default  => '',  # TODO
            length   => 255,
            not_null => 1
        },
        suri_handle => {
            type     => 'varchar',
            default  => '',  # TODO
            length   => 128,
            not_null => 1
        },
        suri_feed    => { type => 'varchar', length => 255 },
        suri_upd_int => { type => 'integer' },
        suri_status  => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        suri_cre_user => { type => 'integer', not_null => 1 },
        suri_upd_user => { type => 'integer' },
        suri_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        suri_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['suri_id'],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { suri_cre_user => 'user_id' },
        },

        source => {
            class       => 'AIR2::Source',
            key_columns => { suri_src_id => 'src_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { suri_upd_user => 'user_id' },
        },
    ],
);

1;

