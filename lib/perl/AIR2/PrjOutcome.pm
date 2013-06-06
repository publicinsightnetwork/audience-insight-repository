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
package AIR2::PrjOutcome;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'prj_outcome',

    columns => [
        pout_prj_id => { type => 'integer', not_null => 1 },
        pout_out_id => { type => 'integer', not_null => 1 },
        pout_type   => {
            type     => 'character',
            default  => 'I',
            length   => 1,
            not_null => 1
        },
        pout_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        pout_notes    => { type => 'text',     length => 65535 },
        pout_cre_user => { type => 'integer',  not_null => 1 },
        pout_upd_user => { type => 'integer' },
        pout_cre_dtim => { type => 'datetime', not_null => 1 },
        pout_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => [ 'pout_prj_id', 'pout_out_id' ],

    foreign_keys => [
        project => {
            class       => 'AIR2::Project',
            key_columns => { pout_prj_id => 'prj_id' },
        },

        outcome => {
            class       => 'AIR2::Outcome',
            key_columns => { pout_out_id => 'out_id' },
        },
    ],
);

1;

