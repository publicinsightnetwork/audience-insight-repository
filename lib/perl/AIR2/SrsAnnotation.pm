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

package AIR2::SrsAnnotation;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'srs_annotation',

    columns => [
        srsan_id     => { type => 'serial',  not_null => 1 },
        srsan_srs_id => { type => 'integer', default  => '0', not_null => 1 },
        srsan_value  => { type => 'text',    length   => 65535 },
        srsan_cre_user => { type => 'integer', not_null => 1 },
        srsan_upd_user => { type => 'integer' },
        srsan_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        srsan_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['srsan_id'],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { srsan_cre_user => 'user_id' },
        },

        srcresponseset => {
            class       => 'AIR2::SrcResponseSet',
            key_columns => { srsan_srs_id => 'srs_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { srsan_upd_user => 'user_id' },
        },
    ],
);

1;

