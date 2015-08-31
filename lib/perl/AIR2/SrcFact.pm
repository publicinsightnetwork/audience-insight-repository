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

package AIR2::SrcFact;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'src_fact',

    columns => [
        sf_src_id    => { type => 'integer', not_null => 1 },
        sf_fact_id   => { type => 'integer', not_null => 1 },

        # user-mapped value, via translation map, etc.
        sf_fv_id     => { type => 'integer' },

        # source-supplied raw value
        sf_src_value => { type => 'text',    length   => 65535 },

        # source-supplied mapped value (from picklist, e.g. income)
        sf_src_fv_id => { type => 'integer' },

        sf_lock_flag   => { type => 'integer', default => 1, not_null => 1 },
        sf_public_flag => { type => 'integer', default => 1, not_null => 1 },
        sf_cre_user => { type => 'integer', not_null => 1 },
        sf_upd_user => { type => 'integer' },
        sf_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        sf_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => [ 'sf_src_id', 'sf_fact_id' ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { sf_cre_user => 'user_id' },
        },

        fact => {
            class       => 'AIR2::Fact',
            key_columns => { sf_fact_id => 'fact_id' },
        },

        fact_value => {
            class       => 'AIR2::FactValue',
            key_columns => { sf_fv_id => 'fv_id' },
        },

        source => {
            class       => 'AIR2::Source',
            key_columns => { sf_src_id => 'src_id' },
        },

        source_fact_value => {
            class       => 'AIR2::FactValue',
            key_columns => { sf_src_fv_id => 'fv_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { sf_upd_user => 'user_id' },
        },
    ],
);

1;

