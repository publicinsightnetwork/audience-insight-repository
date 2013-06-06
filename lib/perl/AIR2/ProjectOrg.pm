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

package AIR2::ProjectOrg;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'project_org',

    columns => [
        porg_prj_id          => { type => 'integer', not_null => 1 },
        porg_org_id          => { type => 'integer', not_null => 1 },
        porg_contact_user_id => { type => 'integer', not_null => 1 },
        porg_status          => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        porg_cre_user => { type => 'integer', not_null => 1 },
        porg_upd_user => { type => 'integer' },
        porg_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        porg_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => [ 'porg_prj_id', 'porg_org_id' ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { porg_cre_user => 'user_id' },
        },

        organization => {
            class       => 'AIR2::Organization',
            key_columns => { porg_org_id => 'org_id' },
        },

        project => {
            class       => 'AIR2::Project',
            key_columns => { porg_prj_id => 'prj_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { porg_upd_user => 'user_id' },
        },

        user => {
            class       => 'AIR2::User',
            key_columns => { porg_contact_user_id => 'user_id' },
        },
    ],
);

# cache the org data to reduce db overhead. they rarely change.
my %org_names;
my %org_uuids;

sub get_org_name {
    my $self = shift;
    if ( exists $org_names{ $self->porg_org_id } ) {
        return $org_names{ $self->porg_org_id };
    }
    $org_names{ $self->porg_org_id } = $self->organization->org_name;
    return $org_names{ $self->porg_org_id };
}

sub get_org_uuid {
    my $self = shift;
    if ( exists $org_uuids{ $self->porg_org_id } ) {
        return $org_uuids{ $self->porg_org_id };
    }
    $org_uuids{ $self->porg_org_id } = $self->organization->org_uuid;
    return $org_uuids{ $self->porg_org_id };
}

1;

