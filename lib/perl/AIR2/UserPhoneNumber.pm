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

package AIR2::UserPhoneNumber;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'user_phone_number',

    columns => [
        uph_id   => { type => 'serial', not_null => 1 },
        uph_uuid => {
            type     => 'character',
            default  => '',
            length   => 12,
            not_null => 1
        },
        uph_user_id => { type => 'integer', default => '0', not_null => 1 },
        uph_country => {
            type     => 'character',
            default  => '',
            length   => 3,
            not_null => 1
        },
        uph_number =>
            { type => 'varchar', default => '', length => 12, not_null => 1 },
        uph_ext => { type => 'varchar', length => 12 },
        uph_primary_flag =>
            { type => 'integer', default => 1, not_null => 1 },
    ],

    primary_key_columns => ['uph_id'],

    unique_key => ['uph_uuid'],

    foreign_keys => [
        user => {
            class       => 'AIR2::User',
            key_columns => { uph_user_id => 'user_id' },
        },
    ],
);

sub as_string {
    my $self = shift;
    if ( $self->uph_ext ) {
        return sprintf( "%s x%s", $self->uph_number, $self->uph_ext );
    }
    else {
        return $self->uph_number;
    }
}

1;

