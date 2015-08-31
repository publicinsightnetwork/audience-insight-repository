###########################################################################
#
#   Copyright 2015 American Public Media Group
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

package AIR2::OutAnnotation;
use strict;
use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table   => 'out_annotation',

    columns => [
        oa_id       => { type => 'serial', not_null => 1 },
        oa_out_id   => { type => 'integer', default => 1, not_null => 1 },
        oa_value => {
            type     => 'varchar',
            default  => '',
            length   => 255,
            not_null => 1
        },
        oa_cre_user => { type => 'integer',  not_null => 1 },
        oa_upd_user => { type => 'integer' },
        oa_cre_dtim => { type => 'datetime', not_null => 1 },
        oa_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => [ 'oa_id' ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { oa_cre_user => 'user_id' },
        },

        outcome => {
            class       => 'AIR2::Outcome',
            key_columns => { oa_out_id => 'out_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { oa_upd_user => 'user_id' },
        },
    ],
);

1;

