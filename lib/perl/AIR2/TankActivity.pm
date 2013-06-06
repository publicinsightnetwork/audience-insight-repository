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
package AIR2::TankActivity;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'tank_activity',

    columns => [
        tact_id      => { type => 'serial',  not_null => 1 },
        tact_tank_id => { type => 'integer', not_null => 1 },
        tact_type    => {
            type     => 'character',
            default  => 'S',
            length   => 1,
            not_null => 1
        },
        tact_actm_id  => { type => 'integer',   not_null => 1 },
        tact_prj_id   => { type => 'integer' },
        tact_dtim     => { type => 'datetime' },
        tact_desc     => { type => 'varchar',   length   => 255 },
        tact_notes    => { type => 'text',      length   => 65535 },
        tact_xid      => { type => 'integer' },
        tact_ref_type => { type => 'character', length   => 1 },
    ],

    primary_key_columns => ['tact_id'],

    foreign_keys => [
        tank => {
            class       => 'AIR2::Tank',
            key_columns => { tact_tank_id => 'tank_id' },
        },

        activity => {
            class       => 'AIR2::ActivityMaster',
            key_columns => { tact_actm_id => 'actm_id', }
        },

        project => {
            class       => 'AIR2::Project',
            key_columns => { tact_prj_id => 'prj_id' },
        },
    ],

);

1;

