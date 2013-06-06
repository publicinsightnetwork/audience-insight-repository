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

package AIR2::ProjectInquiry;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'project_inquiry',

    columns => [
        pinq_prj_id => { type => 'integer', not_null => 1 },
        pinq_inq_id => { type => 'integer', not_null => 1 },
        pinq_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        pinq_cre_user => { type => 'integer', not_null => 1 },
        pinq_upd_user => { type => 'integer' },
        pinq_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        pinq_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => [ 'pinq_prj_id', 'pinq_inq_id' ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { pinq_cre_user => 'user_id' },
        },

        inquiry => {
            class       => 'AIR2::Inquiry',
            key_columns => { pinq_inq_id => 'inq_id' },
        },

        project => {
            class       => 'AIR2::Project',
            key_columns => { pinq_prj_id => 'prj_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { pinq_upd_user => 'user_id' },
        },
    ],
);

# memoize
my %projects;

sub get_project {
    my $self   = shift;
    my $prj_id = $self->pinq_prj_id;
    if ( exists $projects{$prj_id} ) {
        return $projects{$prj_id};
    }
    $projects{$prj_id} = $self->project;
    return $projects{$prj_id};
}

1;

