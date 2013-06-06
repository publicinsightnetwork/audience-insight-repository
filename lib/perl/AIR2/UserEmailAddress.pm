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

package AIR2::UserEmailAddress;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'user_email_address',

    columns => [
        uem_id      => { type => 'serial',    not_null => 1 },
        uem_user_id => { type => 'integer',   not_null => 1 },
        uem_uuid    => { type => 'character', not_null => 1, length => 12 },
        uem_address => { type => 'varchar',   not_null => 1, length => 255 },
        uem_primary_flag =>
            { type => 'integer', not_null => 1, default => 1 },
        uem_signature => { type => 'text', length => 65535 },
    ],

    primary_key_columns => ['uem_id'],

    unique_key => ['uem_uuid'],

    foreign_keys => [
        user => {
            class       => 'AIR2::User',
            key_columns => { uem_user_id => 'user_id' },
        },
    ],
);

1;

