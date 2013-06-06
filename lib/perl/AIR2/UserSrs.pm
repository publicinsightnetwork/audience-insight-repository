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
package AIR2::UserSrs;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'user_srs',

    columns => [
        usrs_user_id => { type => 'integer', not_null => 1 },
        usrs_srs_id  => { type => 'integer', not_null => 1 },
        usrs_read_flag =>
            { type => 'integer', default => '0', not_null => 1 },
        usrs_favorite_flag =>
            { type => 'integer', default => '0', not_null => 1 },
        usrs_cre_dtim => { type => 'datetime', not_null => 1 },
        usrs_upd_dtim => { type => 'datetime', },
    ],

    primary_key_columns => [ 'usrs_user_id', 'usrs_srs_id' ],

    foreign_keys => [
        user => {
            class       => 'AIR2::User',
            key_columns => { usrs_user_id => 'user_id' },
        },
        srs => {
            class       => 'AIR2::SrcResponseSet',
            key_columns => { usrs_srs_id => 'srs_id' },
        },
    ],
);

1;

