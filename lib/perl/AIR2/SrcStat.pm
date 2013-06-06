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

package AIR2::SrcStat;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'src_stat',

    columns => [
        sstat_src_id       => { type => 'integer', not_null => 1 },
        sstat_export_dtim  => { type => 'datetime' },
        sstat_contact_dtim => { type => 'datetime' },
        sstat_submit_dtim  => { type => 'datetime' },
        sstat_bh_play_dtim   => { type => 'datetime' },
        sstat_bh_signup_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['sstat_src_id'],

    foreign_keys => [
        source => {
            class       => 'AIR2::Source',
            key_columns => { sstat_src_id => 'src_id' },
        },
    ]
);

1;

