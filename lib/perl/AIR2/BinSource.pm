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

package AIR2::BinSource;

use strict;
use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'bin_source',

    columns => [
        bsrc_bin_id => { type => 'integer', default => '', not_null => 1 },
        bsrc_src_id => { type => 'integer', default => '', not_null => 1 },
        bsrc_notes  => { type => 'varchar', length   => 255 },
        bsrc_meta   => { type => 'varchar', length   => 255 },
    ],

    primary_key_columns => ['bsrc_bin_id', 'bsrc_src_id'],

    foreign_keys => [
        bin => {
            class       => 'AIR2::Bin',
            key_columns => { bsrc_bin_id => 'bin_id' },
        },

        source => {
            class       => 'AIR2::Source',
            key_columns => { bsrc_src_id => 'src_id' },
        },
    ],

);

1;
