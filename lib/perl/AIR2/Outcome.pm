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
package AIR2::Outcome;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'outcome',

    columns => [
        out_id   => { type => 'serial', not_null => 1 },
        out_uuid => {
            type     => 'character',
            length   => 12,
            not_null => 1
        },
        out_org_id   => { type => 'integer', not_null => 1, default => 1 },
        out_headline => { type => 'varchar', length => 255, not_null => 1 },
        out_internal_headline => { type => 'varchar', length => 255 },
        out_url      => { type => 'varchar', length => 255 },
        out_teaser   => { type => 'text',    length => 65535, not_null => 1 },
        out_internal_teaser   => { type => 'text',    length => 65535 },
        out_show     => { type => 'varchar', length => 255 },
        out_survey   => { type => 'text',    length => 65535 },
        out_dtim     => { type => 'datetime' },
        out_meta     => { type => 'text',    length => 65535 },
        out_type     => {
            type     => 'character',
            default  => 'S',
            length   => 1,
            not_null => 1
        },
        out_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        out_cre_user => { type => 'integer',  not_null => 1 },
        out_upd_user => { type => 'integer' },
        out_cre_dtim => { type => 'datetime', not_null => 1 },
        out_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['out_id'],

    unique_key => ['out_uuid'],

    foreign_keys => [
        organization => {
            class       => 'AIR2::Organization',
            key_columns => { out_org_id => 'org_id' },
        },

        cre_user => {
            class       => 'AIR2::User',
            key_columns => { out_cre_user => 'user_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { out_upd_user => 'user_id' },
        },
    ],

    relationships => [

        # Projects
        prj_outcomes => {
            class      => 'AIR2::PrjOutcome',
            column_map => { out_id => 'pout_out_id' },
            type       => 'one to many',
        },
        projects => {
            map_class => 'AIR2::PrjOutcome',
            map_from  => 'outcome',
            map_to    => 'project',
            type      => 'many to many',
        },

        # Inquiries
        inq_outcomes => {
            class      => 'AIR2::InqOutcome',
            column_map => { out_id => 'iout_out_id' },
            type       => 'one to many',
        },
        inquiries => {
            map_class => 'AIR2::InqOutcome',
            map_from  => 'outcome',
            map_to    => 'inquiry',
            type      => 'many to many',
        },

        # Sources
        src_outcomes => {
            class      => 'AIR2::SrcOutcome',
            column_map => { out_id => 'sout_out_id' },
            type       => 'one to many',
        },
        sources => {
            map_class => 'AIR2::SrcOutcome',
            map_from  => 'outcome',
            map_to    => 'source',
            type      => 'many to many',
        },
    ],
);

1;

