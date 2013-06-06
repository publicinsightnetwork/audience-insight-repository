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

package AIR2::SrcMailAddress;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'src_mail_address',

    columns => [
        smadd_id   => { type => 'serial',    not_null => 1 },
        smadd_uuid => { type => 'character', length   => 12, not_null => 1 },
        smadd_src_id => { type => 'integer', default => '0', not_null => 1 },
        smadd_primary_flag =>
            { type => 'integer', default => 0, not_null => 1 },
        smadd_context => { type => 'character', length    => 1 },
        smadd_line_1  => { type => 'varchar',   length    => 128 },
        smadd_line_2  => { type => 'varchar',   length    => 128 },
        smadd_city    => { type => 'varchar',   length    => 128 },
        smadd_state   => { type => 'character', length    => 2 },
        smadd_cntry   => { type => 'character', length    => 2 },
        smadd_county  => { type => 'varchar',   length    => 128 },
        smadd_zip     => { type => 'varchar',   length    => 10 },
        smadd_lat     => { type => 'float',     precision => 32 },
        smadd_long    => { type => 'float',     precision => 32 },
        smadd_status  => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        smadd_cre_user => { type => 'integer', not_null => 1 },
        smadd_upd_user => { type => 'integer' },
        smadd_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        smadd_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['smadd_id'],

    unique_keys => [ ['smadd_uuid'], ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { smadd_cre_user => 'user_id' },
        },

        source => {
            class       => 'AIR2::Source',
            key_columns => { smadd_src_id => 'src_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { smadd_upd_user => 'user_id' },
        },
    ],
);

1;

