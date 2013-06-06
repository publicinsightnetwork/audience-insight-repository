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

package AIR2::UserSignature;
use strict;
use base qw(AIR2::DB);
use Carp;

__PACKAGE__->meta->setup(
    table => 'user_signature',

    columns => [

        # identifiers
        usig_id      => { type => 'serial',    not_null => 1 },
        usig_uuid    => { type => 'character', not_null => 1, length => 12 },
        usig_user_id => { type => 'integer',   not_null => 1 },
        usig_text => { type => 'text', not_null => 1, length => 65535 },

        # meta
        usig_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        usig_cre_user => { type => 'integer',  not_null => 1 },
        usig_upd_user => { type => 'integer' },
        usig_cre_dtim => { type => 'datetime', not_null => 1 },
        usig_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['usig_id'],

    unique_key => ['usig_uuid'],

    foreign_keys => [
        user => {
            class       => 'AIR2::User',
            key_columns => { usig_user_id => 'user_id' },
        },

        cre_user => {
            class       => 'AIR2::User',
            key_columns => { usig_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { usig_upd_user => 'user_id' },
        },
    ],

    relationships => [
        emails => {
            class      => 'AIR2::Email',
            column_map => { usig_id => 'email_usig_id' },
            type       => 'one to many',
        },
    ],
);

1;
