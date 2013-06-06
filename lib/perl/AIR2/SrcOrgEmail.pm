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
package AIR2::SrcOrgEmail;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'src_org_email',

    columns => [
        soe_id     => { type => 'serial',    not_null => 1 },
        soe_sem_id => { type => 'integer',   not_null => 1 },
        soe_org_id => { type => 'integer',   not_null => 1 },
        soe_status => { type => 'character', length   => 1, not_null => 1 },
        soe_status_dtim => { type => 'datetime', not_null => 1 },
        soe_type        => {
            type     => 'character',
            default  => 'L',
            length   => 1,
            not_null => 1
        },
    ],

    primary_key_columns => ['soe_id'],

    unique_key => [ 'soe_sem_id', 'soe_org_id', 'soe_type' ],

    foreign_keys => [
        email => {
            class       => 'AIR2::SrcEmail',
            key_columns => { soe_sem_id => 'sem_id' },
        },

        organization => {
            class       => 'AIR2::Organization',
            key_columns => { soe_org_id => 'org_id' },
        },

    ],
);

1;

