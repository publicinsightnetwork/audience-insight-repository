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

package AIR2::SystemMessage;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'system_message',

    columns => [
        smsg_id     => { type => 'integer',   not_null => 1 },
        smsg_value  => { type => 'varchar',   length   => 255 },
        smsg_status => { type => 'character', length   => 1, default => 'A' },
        smsg_cre_user => { type => 'integer', not_null => 1 },
        smsg_upd_user => { type => 'integer' },
        smsg_cre_dtim => {
            type     => 'datetime',
            default  => '1970-01-01 00:00:00',
            not_null => 1
        },
        smsg_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['smsg_id'],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { smsg_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { smsg_upd_user => 'user_id' },
        },
    ],
);

1;

