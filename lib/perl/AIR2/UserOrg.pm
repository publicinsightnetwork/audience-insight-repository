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

package AIR2::UserOrg;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'user_org',

    columns => [
        uo_id      => { type => 'serial',  not_null => 1 },
        uo_org_id  => { type => 'integer', default  => '', not_null => 1 },
        uo_user_id => { type => 'integer', default  => '', not_null => 1 },
        uo_ar_id   => { type => 'integer', default  => 1, not_null => 1 },
        uo_uuid => {
            type     => 'character',
            default  => '',
            length   => 12,
            not_null => 1
        },
        uo_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        uo_notify_flag => { type => 'integer', default => 0, not_null => 1 },
        uo_home_flag   => { type => 'integer', default => 0, not_null => 1 },
        uo_cre_user => { type => 'integer', not_null => 1 },
        uo_upd_user => { type => 'integer' },
        uo_cre_dtim => {
            type     => 'datetime',
            default  => '1970-01-01 00:00:00',
            not_null => 1
        },
        uo_upd_dtim   => { type => 'datetime' },
        uo_user_title => { type => 'varchar', length => '255', },
    ],

    primary_key_columns => ['uo_id'],

    unique_keys => [ [ 'uo_org_id', 'uo_user_id' ], ['uo_uuid'], ],

    foreign_keys => [
        adminrole => {
            class       => 'AIR2::AdminRole',
            key_columns => { uo_ar_id => 'ar_id' },
        },

        cre_user => {
            class       => 'AIR2::User',
            key_columns => { uo_cre_user => 'user_id' },
        },

        organization => {
            class       => 'AIR2::Organization',
            key_columns => { uo_org_id => 'org_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { uo_upd_user => 'user_id' },
        },

        user => {
            class       => 'AIR2::User',
            key_columns => { uo_user_id => 'user_id' },
        },
    ],
);

1;

