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

package AIR2::Tag;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'tag',

    columns => [
        tag_tm_id    => { type => 'integer', not_null => 1 },
        tag_xid      => { type => 'integer', not_null => 1 },
        tag_ref_type => { type => 'varchar', length   => 1, not_null => 1 },
        tag_cre_user => { type => 'integer', not_null => 1 },
        tag_upd_user => { type => 'integer' },
        tag_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        tag_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => [ 'tag_tm_id', 'tag_xid', 'tag_ref_type' ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { tag_cre_user => 'user_id' },
        },

        tagmaster => {
            class       => 'AIR2::TagMaster',
            key_columns => { tag_tm_id => 'tm_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { tag_upd_user => 'user_id' },
        },
    ],
);

1;

