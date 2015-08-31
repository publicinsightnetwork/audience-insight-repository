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

package AIR2::Locale;
use strict;
use base qw(AIR2::DB);
use Carp;

__PACKAGE__->meta->setup(
    table => 'locale',

    columns => [
        loc_id     => { type => 'serial',  not_null => 1 },
        loc_key    => { type => 'varchar', length   => 5, not_null => 1 },
        loc_lang   => { type => 'varchar', length   => 255, },
        loc_region => { type => 'varchar', length   => 255, },
    ],

    primary_key_columns => ['loc_id'],

    unique_key => ['loc_key'],
);

my %locales;

sub get_by_key {
    my $self = shift;
    my $key = shift or croak "loc_key required";
    return $locales{$key} if $locales{$key};
    my $locale = $self->new( loc_key => $key )->load;
    $locales{$key} = $locale;
    return $locale;
}

1;

