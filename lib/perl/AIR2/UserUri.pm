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

package AIR2::UserUri;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'user_uri',

    columns => [
        uuri_id   => { type => 'serial', not_null => 1 },
        uuri_uuid => {
            type     => 'character',
            default  => '',
            length   => 12,
            not_null => 1
        },
        uuri_user_id => { type => 'integer', default => '0', not_null => 1 },
        uuri_type    => {
            type     => 'character',
            default  => '',
            length   => 1,
            not_null => 1
        },
        uuri_value => {
            type     => 'varchar',
            default  => '',
            length   => 255,
            not_null => 1
        },
        uuri_feed    => { type => 'varchar', length => 255 },
        uuri_upd_int => { type => 'integer' },
        uuri_handle  => {
            type     => 'varchar',
            default  => '',
            length   => 128,
            not_null => 1
        },
    ],

    primary_key_columns => ['uuri_id'],

    unique_key => ['uuri_uuid'],

    foreign_keys => [
        user => {
            class       => 'AIR2::User',
            key_columns => { uuri_user_id => 'user_id' },
        },
    ],
);

1;

