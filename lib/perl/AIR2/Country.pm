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

package AIR2::Country;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'country',

    columns => [
        cntry_id   => { type => 'serial', not_null => 1 },
        cntry_name => {
            type     => 'varchar',
            default  => '',
            length   => 128,
            not_null => 1
        },
        cntry_code => {
            type     => 'character',
            default  => '',
            length   => 2,
            not_null => 1
        },
        cntry_disp_seq =>
            { type => 'integer', default => '0', not_null => 1 },
    ],

    primary_key_columns => ['cntry_id'],
);

sub get_all_by_code {
    my $class = shift;
    my %all;
    my $cs = $class->fetch_all_iterator();
    while ( my $c = $cs->next ) {
        $all{ $c->cntry_code } = $c->cntry_name;
    }
    return \%all;
}

1;

