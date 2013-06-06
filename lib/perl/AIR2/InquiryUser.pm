###########################################################################
#
#   Copyright 2013 American Public Media Group
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

package AIR2::InquiryUser;
use strict;
use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'inquiry_user',

    columns => [
        iu_id      => { type => 'serial',  not_null => 1 },
        iu_inq_id  => { type => 'integer', not_null => 1 },
        iu_user_id => { type => 'integer', not_null => 1 },
        iu_type    => {
            type     => 'character',
            default  => 'W',
            length   => 1,
            not_null => 1
        },
        iu_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1,
        },
        iu_cre_user => { type => 'integer',  not_null => 1 },
        iu_cre_dtim => { type => 'datetime', not_null => 1 },
        iu_upd_user => { type => 'integer',  not_null => 1 },
        iu_upd_dtim => { type => 'datetime', not_null => 1 },
    ],

    primary_key_columns => ['iu_id'],

    unique_keys => [ [qw( iu_inq_id iu_user_id iu_type )] ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { iu_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { iu_upd_user => 'user_id' },
        },
        inquiry => {
            class       => 'AIR2::Inquiry',
            key_columns => { iu_inq_id => 'inq_id' },
        },
        user => {
            class       => 'AIR2::User',
            key_columns => { iu_user_id => 'user_id' },
        },

    ],
);

1;

