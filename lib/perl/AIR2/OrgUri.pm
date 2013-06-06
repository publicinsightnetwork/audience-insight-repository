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
package AIR2::OrgUri;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'org_uri',

    columns => [
        ouri_id   => { type => 'serial', not_null => 1 },
        ouri_uuid => {
            type     => 'character',
            default  => '',
            length   => 12,
            not_null => 1
        },
        ouri_org_id => { type => 'integer', default => '', not_null => 1 },
        ouri_type   => {
            type     => 'character',
            default  => '',
            length   => 1,
            not_null => 1
        },
        ouri_value => {
            type     => 'varchar',
            default  => '',
            length   => 255,
            not_null => 1
        },
        ouri_feed    => { type => 'varchar', length => 255 },
        ouri_upd_int => { type => 'integer' },
        ouri_handle  => { type => 'varchar', length => 128 },
    ],

    primary_key_columns => ['ouri_id'],

    unique_key => ['ouri_uuid'],
);

1;

