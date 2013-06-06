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
package AIR2::TankFact;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'tank_fact',

    columns => [
        tf_id      => { type => 'serial',  not_null => 1 },
        tf_fact_id => { type => 'integer', default  => '', not_null => 1 },
        tf_tsrc_id => { type => 'integer', default  => '', not_null => 1 },
        sf_fv_id     => { type => 'integer' },
        sf_src_value => { type => 'text', length => 65535 },
        sf_src_fv_id => { type => 'integer' },
    ],

    primary_key_columns => ['tf_id'],

    foreign_keys => [
        tank_source => {
            class       => 'AIR2::TankSource',
            key_columns => { tf_tsrc_id => 'tsrc_id' },
        },
        fact => {
            class       => 'AIR2::Fact',
            key_columns => { tf_fact_id => 'fact_id' },
        },
    ],
);

1;

