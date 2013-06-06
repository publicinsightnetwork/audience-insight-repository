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
package AIR2::TankVita;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table   => 'tank_vita',

    columns => [
        tv_id         => { type => 'serial', not_null => 1 },
        tv_tsrc_id    => { type => 'integer', default => '', not_null => 1 },
        sv_type       => { type => 'character', default => 'I', length => 1, not_null => 1 },
        sv_origin     => { type => 'character', default => 2, length => 1, not_null => 1 },
        sv_start_date => { type => 'date' },
        sv_end_date   => { type => 'date' },
        sv_lat        => { type => 'float', precision => 32 },
        sv_long       => { type => 'float', precision => 32 },
        sv_value      => { type => 'text', length => 65535 },
        sv_basis      => { type => 'text', length => 65535 },
        sv_notes      => { type => 'text', length => 65535 },
    ],

    primary_key_columns => [ 'tv_id' ],
);

1;

