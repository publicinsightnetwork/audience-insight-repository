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

package AIR2::ProjectActivity;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'project_activity',

    columns => [
        pa_id       => { type => 'serial',  not_null => 1 },
        pa_actm_id  => { type => 'integer' },
        pa_prj_id   => { type => 'integer' },
        pa_dtim     => { type => 'datetime' },
        pa_desc     => { type => 'varchar', length   => 255 },
        pa_notes    => { type => 'text',    length   => 65535 },
        pa_cre_user => { type => 'integer', not_null => 1 },
        pa_upd_user => { type => 'integer' },
        pa_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        pa_upd_dtim => { type => 'datetime' },
        pa_xid      => { type => 'integer' },
        pa_ref_type => { type => 'character', length => 1 },
    ],

    primary_key_columns => ['pa_id'],

    foreign_keys => [
        activitymaster => {
            class       => 'AIR2::ActivityMaster',
            key_columns => { pa_actm_id => 'actm_id' },
        },

        cre_user => {
            class       => 'AIR2::User',
            key_columns => { pa_cre_user => 'user_id' },
        },

        project => {
            class       => 'AIR2::Project',
            key_columns => { pa_prj_id => 'prj_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { pa_upd_user => 'user_id' },
        },

    ],
);

1;

