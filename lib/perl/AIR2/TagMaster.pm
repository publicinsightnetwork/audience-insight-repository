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

package AIR2::TagMaster;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'tag_master',

    columns => [
        tm_id   => { type => 'serial', not_null => 1 },
        tm_type => {
            type     => 'character',
            default  => 'J',
            length   => 1,
            not_null => 1
        },
        tm_name     => { type => 'varchar', length   => 32 },
        tm_iptc_id  => { type => 'integer' },
        tm_cre_user => { type => 'integer', not_null => 1 },
        tm_upd_user => { type => 'integer' },
        tm_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        tm_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['tm_id'],

    unique_keys => [ ['tm_iptc_id'], ['tm_name'], ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { tm_cre_user => 'user_id' },
        },

        iptcmaster => {
            class       => 'AIR2::IptcMaster',
            key_columns => { tm_iptc_id => 'iptc_id' },
            rel_type    => 'one to one',
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { tm_upd_user => 'user_id' },
        },
    ],

    relationships => [
        tag => {
            class      => 'AIR2::Tag',
            column_map => { tm_id => 'tag_tm_id' },
            type       => 'one to many',
        },
    ],
);

sub popularity {
    my $self = shift;
    return $self->tag_count();
}

sub get_name {
    my $self = shift;
    my $name = $self->tm_name;
    if ( $self->tm_type eq 'I' and $self->tm_iptc_id ) {
        $name = $self->iptcmaster->iptc_name;
        $name =~ s,.+/\ *,,;  # only most specific in hierarchy. redmine #2793
    }
    return $name;
}

1;

