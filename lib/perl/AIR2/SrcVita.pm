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

package AIR2::SrcVita;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'src_vita',

    columns => [
        sv_id     => { type => 'serial',  not_null => 1 },
        sv_src_id => { type => 'integer', default  => '', not_null => 1 },
        sv_uuid => {
            type     => 'character',
            default  => '',
            length   => 12,
            not_null => 1
        },
        sv_seq  => { type => 'integer', default => 10, not_null => 1 },
        sv_type => {
            type     => 'character',
            default  => 'I',
            length   => 1,
            not_null => 1
        },
        sv_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        sv_origin =>
            { type => 'character', default => 2, length => 1, not_null => 1 },
        sv_conf_level => {
            type     => 'character',
            default  => 'U',
            length   => 1,
            not_null => 1
        },
        sv_lock_flag  => { type => 'integer', default => '0', not_null => 1 },
        sv_start_date => { type => 'date' },
        sv_end_date   => { type => 'date' },
        sv_lat      => { type => 'float',    precision => 32 },
        sv_long     => { type => 'float',    precision => 32 },
        sv_value    => { type => 'text',     length    => 65535 },
        sv_basis    => { type => 'text',     length    => 65535 },
        sv_notes    => { type => 'text',     length    => 65535 },
        sv_cre_user => { type => 'integer',  not_null  => 1 },
        sv_upd_user => { type => 'integer' },
        sv_cre_dtim => { type => 'datetime', not_null  => 1 },
        sv_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['sv_id'],

    unique_key => ['sv_uuid'],
);

1;

