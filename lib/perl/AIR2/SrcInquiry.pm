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

package AIR2::SrcInquiry;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'src_inquiry',

    columns => [
        si_id      => { type => 'serial',  not_null => 1 },
        si_src_id  => { type => 'integer', default  => '0', not_null => 1 },
        si_inq_id  => { type => 'integer', default  => '0', not_null => 1 },
        si_sent_by => { type => 'varchar', length   => 255 },
        si_status => {
            type     => 'character',
            length   => 1,
            default  => 'P',
            not_null => 1,
        },
        si_cre_user => { type => 'integer', not_null => 1 },
        si_upd_user => { type => 'integer' },
        si_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        si_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['si_id'],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { si_cre_user => 'user_id' },
        },

        inquiry => {
            class       => 'AIR2::Inquiry',
            key_columns => { si_inq_id => 'inq_id' },
        },

        source => {
            class       => 'AIR2::Source',
            key_columns => { si_src_id => 'src_id' },
        },

        src_export => {
            class       => 'AIR2::SrcExport',
            key_columns => { si_sent_by => 'se_name' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { si_upd_user => 'user_id' },
        },
    ],
);

1;

