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

package AIR2::GeoLookup;
use strict;
use base qw(AIR2::DB);
use Carp;

__PACKAGE__->meta->setup(
    table => 'geo_lookup',

    columns => [
        zip_code => { type => 'varchar', length => 16, not_null => 1 },
        state    => {
            type     => 'varchar',
            default  => '',
            length   => 128,
            not_null => 1
        },
        city => {
            type     => 'varchar',
            default  => '',
            length   => 255,
            not_null => 1
        },
        county     => { type => 'varchar', length    => 128 },
        latitude   => { type => 'float',   precision => 32 },
        longitude  => { type => 'float',   precision => 32 },
        population => { type => 'integer' },
    ],

    primary_key_columns => ['zip_code'],
);

my %cache;

sub find {
    my $class = shift;
    my %args  = @_;
    if ( !$args{zip_code} ) {
        croak "must provide a zip_code";
    }
    if ( exists $cache{ $args{zip_code} } ) {
        return $cache{ $args{zip_code} };
    }
    my $self = $class->new(%args);
    $self->load_speculative;
    if ( $self->load_speculative ) {
        $cache{ $args{zip_code} } = $self;
        return $self;
    }

    return undef;
}

1;

