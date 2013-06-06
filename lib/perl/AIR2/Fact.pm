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

package AIR2::Fact;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'fact',

    columns => [
        fact_id   => { type => 'serial', not_null => 1 },
        fact_uuid => {
            type     => 'character',
            default  => '',
            length   => 12,
            not_null => 1
        },
        fact_name => {
            type     => 'varchar',
            default  => '',
            length   => 128,
            not_null => 1
        },
        fact_identifier => {
            type     => 'varchar',
            default  => '',          # TODO
            length   => 128,
            not_null => 1
        },
        fact_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        fact_cre_user => { type => 'integer', not_null => 1 },
        fact_upd_user => { type => 'integer' },
        fact_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        fact_upd_dtim => { type => 'datetime' },
        fact_fv_type  => {
            type     => 'character',
            default  => '',
            length   => 1,
            not_null => 1
        },
    ],

    primary_key_columns => ['fact_id'],

    unique_key => ['fact_uuid'],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { fact_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { fact_upd_user => 'user_id' },
        },
    ],

    relationships => [
        fact_values => {
            class      => 'AIR2::FactValue',
            column_map => { fact_id => 'fv_fact_id' },
            type       => 'one to many',
        },

        src_facts => {
            class      => 'AIR2::SrcFact',
            column_map => { fact_id => 'sf_fact_id' },
            type       => 'one to many',
        },
    ],
);

1;

