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
package AIR2::TankPreference;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'tank_preference',

    columns => [
        tp_id      => { type => 'serial',  not_null => 1 },
        tp_tsrc_id => { type => 'integer', default  => '', not_null => 1 },
        sp_ptv_id  => { type => 'integer', not_null => 1 },
        sp_uuid => {
            type     => 'character',
            default  => '',
            length   => 12,
            not_null => 1
        },
        sp_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        sp_lock_flag => { type => 'integer', default => '0', not_null => 1 },
    ],

    primary_key_columns => [ 'tp_id', 'sp_ptv_id' ],

    unique_key => ['sp_uuid'],
);

1;

