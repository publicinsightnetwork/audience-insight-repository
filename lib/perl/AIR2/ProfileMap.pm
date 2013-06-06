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
package AIR2::ProfileMap;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table   => 'profile_map',

    columns => [
        pmap_id           => { type => 'serial', not_null => 1 },
        pmap_name         => { type => 'varchar', default => '', length => 32, not_null => 1 },
        pmap_display_name => { type => 'varchar', default => '', length => 255, not_null => 1 },
        pmap_meta         => { type => 'text', length => 65535 },
        pmap_status       => { type => 'character', default => 'A', length => 1, not_null => 1 },
        pmap_cre_user     => { type => 'integer', default => '', not_null => 1 },
        pmap_upd_user     => { type => 'integer' },
        pmap_cre_dtim     => { type => 'datetime', default => '', not_null => 1 },
        pmap_upd_dtim     => { type => 'datetime' },
    ],

    primary_key_columns => [ 'pmap_id' ],

    unique_keys => [
        [ 'pmap_display_name' ],
        [ 'pmap_name' ],
    ],
);

1;

