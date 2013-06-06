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
package AIR2::TankResponse;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'tank_response',

    columns => [
        tr_id      => { type => 'serial',  not_null => 1 },
        tr_tsrc_id => { type => 'integer', not_null => 1 },
        tr_trs_id  => { type => 'integer', not_null => 1 },
        sr_ques_id => { type => 'integer', not_null => 1 },
        sr_media_asset_flag =>
            { type => 'integer', default => '0', not_null => 1 },
        sr_orig_value => { type => 'text', length => 65535 },
        sr_mod_value  => { type => 'text', length => 65535 },
        sr_status     => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        sr_public_flag => {
            type     => 'integer',
            default  => '0',
            not_null => 1,
        },
        sr_uuid => {
            type   => 'character',
            length => 12,
        },
    ],

    primary_key_columns => ['tr_id'],

    foreign_keys => [
        response_set => {
            class       => 'AIR2::TankResponseSet',
            key_columns => { tr_trs_id => 'trs_id' },
        },
        source => {
            class       => 'AIR2::TankSource',
            key_columns => { tr_tsrc_id => 'tsrc_id' },
        },
        question => {
            class       => 'AIR2::Question',
            key_columns => { sr_ques_id => 'ques_id' },
        },
    ],
);

1;

