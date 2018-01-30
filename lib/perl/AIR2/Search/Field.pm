###########################################################################
#
#   Copyright 2012 American Public Media Group
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
package AIR2::Search::Field;
use strict;
use base 'Search::Query::Field::Lucy';
use Carp;
use Data::Dump qw( dump );

my %requires_min_len = map { $_ => 1 } qw(
    qa
    email
    phone
    src_last_name
    src_first_name
    src_username
    src_pre_name
    src_post_name
    src_uuid
    sa_first_name
    sa_last_name
    birth_year
    experience_where
    experience_what
    interest
    tag
    annotation
    primary_city
    primary_state
    primary_country
    primary_county
    primary_zip
    smadd_line_1
    smadd_line_2
);

sub validate {
    my ( $self, $value ) = @_;
    if ( exists $requires_min_len{ $self->name } and length $value < 2 ) {
        $self->error("Search terms must be at least 2 characters long");
        return 0;
    }
    return 1;
}

1;

