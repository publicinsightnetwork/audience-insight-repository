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
package AIR2::TankResponseSet;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'tank_response_set',

    columns => [
        trs_id      => { type => 'serial',   not_null => 1 },
        trs_tsrc_id => { type => 'integer',  default  => '', not_null => 1 },
        srs_inq_id  => { type => 'integer',  default  => '', not_null => 1 },
        srs_date    => { type => 'datetime', default  => '', not_null => 1 },
        srs_uri     => { type => 'text',     length   => 65535 },
        srs_uuid => {
            type   => 'character',
            length => 12,
        },
        srs_xuuid => {
            type   => 'varchar',
            length => 255,
        },
        srs_type => {
            type     => 'character',
            default  => '',
            length   => 1,
            not_null => 1
        },
        srs_public_flag =>
            { type => 'integer', default => '0', not_null => 1 },
        srs_delete_flag =>
            { type => 'integer', default => '0', not_null => 1 },
        srs_translated_flag =>
            { type => 'integer', default => '0', not_null => 1 },
        srs_export_flag =>
            { type => 'integer', default => '0', not_null => 1 },
        srs_fb_approved_flag =>
            { type => 'integer', default => 0, not_null => 1 },
        srs_loc_id => { type => 'integer', default => 52, not_null => 1 },
        srs_conf_level => { type => 'character', length => 1 },
    ],

    primary_key_columns => ['trs_id'],

    foreign_keys => [
        tanksource => {
            class       => 'AIR2::TankSource',
            key_columns => { trs_tsrc_id => 'tsrc_id' },
        },
    ],

    relationships => [
        responses => {
            class      => 'AIR2::TankResponse',
            column_map => { trs_id => 'tr_trs_id' },
            type       => 'one to many',
        },
    ],

);

1;

