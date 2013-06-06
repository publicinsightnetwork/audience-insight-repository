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

package AIR2::SrcPhoneNumber;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'src_phone_number',

    columns => [
        sph_id     => { type => 'serial',    not_null => 1 },
        sph_uuid   => { type => 'character', length   => 12, not_null => 1 },
        sph_src_id => { type => 'integer',   default  => '0', not_null => 1 },
        sph_primary_flag =>
            { type => 'integer', default => 0, not_null => 1 },
        sph_context => { type => 'character', length => 1 },
        sph_country => { type => 'character', length => 3 },
        sph_number =>
            { type => 'varchar', default => '', length => 16, not_null => 1 },
        sph_ext    => { type => 'varchar', length => 12 },
        sph_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        sph_cre_user => { type => 'integer', not_null => 1 },
        sph_upd_user => { type => 'integer' },
        sph_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        sph_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['sph_id'],

    unique_keys => [ ['sph_uuid'], ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { sph_cre_user => 'user_id' },
        },

        source => {
            class       => 'AIR2::Source',
            key_columns => { sph_src_id => 'src_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { sph_upd_user => 'user_id' },
        },
    ],
);

sub save {
    my $self  = shift;
    my $phone = AIR2::Utils::parse_phone_number( $self->sph_number );
    $phone->{number} =~ s/\D//g;
    $self->sph_number( $phone->{number} );
    if ( $phone->{ext} ) {

        # if already set, check that it is different
        # set based on unknown rules
        $self->sph_ext( $phone->{ext} );

    }
    my $ret = $self->SUPER::save(@_);
    return $ret;
}

1;

