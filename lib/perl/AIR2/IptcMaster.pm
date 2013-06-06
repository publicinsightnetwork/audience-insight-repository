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

package AIR2::IptcMaster;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'iptc_master',

    columns => [
        iptc_id => { type => 'serial', not_null => 1 },
        iptc_concept_code =>
            { type => 'varchar', default => '', length => 32, not_null => 1 },
        iptc_name => {
            type     => 'varchar',
            default  => '',
            length   => 255,
            not_null => 1
        },
        iptc_cre_user => { type => 'integer', not_null => 1 },
        iptc_upd_user => { type => 'integer' },
        iptc_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        iptc_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['iptc_id'],

    unique_key => ['iptc_name'],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { iptc_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { iptc_upd_user => 'user_id' },
        },
    ],

    relationships => [
        tag_master => {
            class                => 'AIR2::TagMaster',
            column_map           => { iptc_id => 'tm_iptc_id' },
            type                 => 'one to one',
            with_column_triggers => '0',
        },
    ],
);

1;

