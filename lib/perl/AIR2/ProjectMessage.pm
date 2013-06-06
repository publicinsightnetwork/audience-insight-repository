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

package AIR2::ProjectMessage;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'project_message',

    columns => [
        pm_id    => { type => 'serial',  not_null => 1 },
        pm_pj_id => { type => 'integer', default  => '0', not_null => 1 },
        pm_type => {
            type     => 'character',
            default  => '',
            length   => 1,
            not_null => 1
        },
        pm_channel => {
            type     => 'character',
            default  => '',
            length   => 1,
            not_null => 1
        },
        pm_channel_xid => { type => 'integer' },
        pm_cre_user    => { type => 'integer', not_null => 1 },
        pm_upd_user    => { type => 'integer' },
        pm_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        pm_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['pm_id'],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { pm_cre_user => 'user_id' },
        },

        project => {
            class       => 'AIR2::Project',
            key_columns => { pm_pj_id => 'prj_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { pm_upd_user => 'user_id' },
        },
    ],
);

1;

