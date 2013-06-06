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

package AIR2::SrcActivity;

use strict;

use base qw(AIR2::DB);

__PACKAGE__->meta->setup(
    table => 'src_activity',

    columns => [
        sact_id       => { type => 'serial',  not_null => 1 },
        sact_actm_id  => { type => 'integer' },
        sact_src_id   => { type => 'integer' },
        sact_prj_id   => { type => 'integer' },
        sact_dtim     => { type => 'datetime' },
        sact_desc     => { type => 'varchar', length   => 255 },
        sact_notes    => { type => 'text',    length   => 65535 },
        sact_cre_user => { type => 'integer', not_null => 1 },
        sact_upd_user => { type => 'integer' },
        sact_cre_dtim => {
            type     => 'datetime',
            not_null => 1
        },
        sact_upd_dtim => { type => 'datetime' },
        sact_xid      => { type => 'integer' },
        sact_ref_type => { type => 'character', length => 1 },
    ],

    primary_key_columns => ['sact_id'],

    foreign_keys => [
        activitymaster => {
            class       => 'AIR2::ActivityMaster',
            key_columns => { sact_actm_id => 'actm_id' },
        },

        cre_user => {
            class       => 'AIR2::User',
            key_columns => { sact_cre_user => 'user_id' },
        },

        project => {
            class       => 'AIR2::Project',
            key_columns => { sact_prj_id => 'prj_id' },
        },

        source => {
            class       => 'AIR2::Source',
            key_columns => { sact_src_id => 'src_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { sact_upd_user => 'user_id' },
        },
    ],
);

my @indexables = qw(
    activitymaster
);

# cache to avoid repeated db calls
my %actmasters = ();

sub get_master {
    my $self = shift;
    if ( exists $actmasters{ $self->sact_actm_id } ) {
        $self->activitymaster( $actmasters{ $self->sact_actm_id } );
    }
    else {
        $actmasters{ $self->sact_actm_id } = $self->activitymaster;
    }
    return $self->activitymaster;
}

sub load_indexable_rels {
    my $self = shift;
    for my $rel (@indexables) {
        if ( $rel eq 'activitymaster' ) {
            $self->get_master;
            next;
        }
        $self->$rel;
    }
}

sub sact_cre_date {
    return shift->_date_as_ymd('sact_cre_dtim');
}

sub sact_upd_date {
    return shift->_date_as_ymd('sact_upd_dtim');
}

sub sact_date {
    return shift->_date_as_ymd('sact_dtim');
}

sub apply_defaults {
    my $self = shift;
    if ( $self->{__air2_admin_update} ) {
        return $self;    # do not set values
    }
    $self->SUPER::apply_defaults(@_);
    if ( !defined $self->sact_dtim() ) {
        $self->sact_dtim( time() );
    }
    return $self;
}

1;

