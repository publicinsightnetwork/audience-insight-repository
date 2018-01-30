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

package AIR2::Organization;
use strict;
use base qw(AIR2::DB);
use Carp;

__PACKAGE__->meta->setup(
    table => 'organization',

    columns => [
        org_id             => { type => 'serial', not_null => 1 },
        org_parent_id      => { type => 'integer' },
        org_default_prj_id => { type => 'integer' },
        org_uuid => { type => 'character', not_null => 1, length => 12 },
        org_name => { type => 'varchar',   not_null => 1, length => 128 },

        org_display_name => { type => 'varchar',   length => 128 },
        org_summary      => { type => 'varchar',   length => 255 },
        org_desc         => { type => 'text',      length => 65535 },
        org_welcome_msg  => { type => 'text',      length => 65535 },
        org_email        => { type => 'varchar',   length => 255 },
        org_address      => { type => 'varchar',   length => 255 },
        org_zip          => { type => 'varchar',   length => 32 },
        org_city         => { type => 'varchar',   length => 128 },
        org_state        => { type => 'character', length => 2 },

        org_logo_uri   => { type => 'varchar', length => 255 },
        org_site_uri   => { type => 'varchar', length => 255 },
        org_html_color => {
            type     => 'character',
            length   => 6,
            not_null => 1,
            default  => '777777'
        },

        org_type => {
            type     => 'character',
            default  => 'N',
            length   => 1,
            not_null => 1
        },
        org_status => {
            type     => 'character',
            default  => 'A',
            length   => 1,
            not_null => 1
        },
        org_max_users => { type => 'integer', default => 0 },
        org_suppress_welcome_email_flag =>
            { type => 'integer', default => 0, not_null => 1 },

        org_cre_user => { type => 'integer',  not_null => 1 },
        org_upd_user => { type => 'integer' },
        org_cre_dtim => { type => 'datetime', not_null => 1 },
        org_upd_dtim => { type => 'datetime' },
    ],

    primary_key_columns => ['org_id'],

    unique_key => [ ['org_uuid'], ['org_name'] ],

    foreign_keys => [
        cre_user => {
            class       => 'AIR2::User',
            key_columns => { org_cre_user => 'user_id' },
        },

        parent => {
            class       => 'AIR2::Organization',
            key_columns => { org_parent_id => 'org_id' },
        },

        upd_user => {
            class       => 'AIR2::User',
            key_columns => { org_upd_user => 'user_id' },
        },

        default_project => {
            class       => 'AIR2::Project',
            key_columns => { org_default_prj_id => 'prj_id' },
        }
    ],

    relationships => [
        org_sys_id => {
            class      => 'AIR2::OrgSysId',
            column_map => { org_id => 'osid_org_id' },
            type       => 'one to many',
        },

        banner => {
            class      => 'AIR2::Image',
            column_map => { org_id => 'img_xid' },
            query_args => [ img_ref_type => 'B' ],
            type       => 'one to one',
        },

        children => {
            class      => 'AIR2::Organization',
            column_map => { org_id => 'org_parent_id' },
            type       => 'one to many',
        },

        inquiries => {
            map_class => 'AIR2::InqOrg',
            map_from  => 'organization',
            map_to    => 'inquiry',
            type      => 'many to many',
        },

        logo => {
            class      => 'AIR2::Image',
            column_map => { org_id => 'img_xid' },
            query_args => [ img_ref_type => 'L' ],
            type       => 'one to one',
        },

        outcomes => {
            class      => 'AIR2::Outcome',
            column_map => { org_id => 'out_org_id' },
            type       => 'one to many',
        },

        project_org => {
            class      => 'AIR2::ProjectOrg',
            column_map => { org_id => 'porg_org_id' },
            type       => 'one to many',
        },

        projects => {
            map_class => 'AIR2::ProjectOrg',
            map_from  => 'organization',
            map_to    => 'project',
            type      => 'many to many',
        },

        sources => {
            map_class => 'AIR2::SrcOrg',
            map_from  => 'organization',
            map_to    => 'source',
            type      => 'many to many',
        },

        src_org => {
            class      => 'AIR2::SrcOrg',
            column_map => { org_id => 'so_org_id' },
            type       => 'one to many',
        },

        src_org_emails => {
            class      => 'AIR2::SrcOrgEmail',
            column_map => { org_id => 'soe_org_id' },
            type       => 'one to many',
        },

        src_pref_org => {
            class      => 'AIR2::SrcPrefOrg',
            column_map => { org_id => 'spo_org_id' },
            type       => 'one to many',
        },

        user_org => {
            class      => 'AIR2::UserOrg',
            column_map => { org_id => 'uo_org_id' },
            type       => 'one to many',
        },

        users => {
            map_class => 'AIR2::UserOrg',
            map_from  => 'organization',
            map_to    => 'user',
            type      => 'many to many',
        },
    ],
);

sub get_location {
    my $self = shift;
    my $default_to_apm = shift || 0;
    my $loc            = join(
        ', ',
        grep { defined and length } (
            $self->org_address, $self->org_city,
            $self->org_state,   $self->org_zip
        )
    );
    if ( !$loc and $default_to_apm ) {
        return '480 Cedar St., Saint Paul, MN, 55101';
    }
    return $loc;
}

sub get_uri {
    my $self = shift;
    return sprintf( '%s/en/newsroom/%s',
        AIR2::Config::get_mypin2_url, $self->org_name, );
}

sub get_email {
    my $self = shift;
    return $self->org_email if $self->org_email;

    # find a user who has this as home org and use their email
    for my $uo ( @{ $self->user_org } ) {
        if ( $uo->uo_home_flag ) {
            return $uo->user->get_primary_email->uem_address;
        }
    }
    return 'support@publicinsightnetwork.org';
}

sub get_logo_uri {
    my $self     = shift;
    my $filename = shift || 'logo_medium.png';
    my $logo     = $self->logo;
    if ( !$logo || !$logo->img_uuid ) {
        return;
    }
    my $base = AIR2::Config::get_base_url();
    $base =~ s,/$,,;
    return sprintf( "%s/img/org/%s/%s?%s",
        $base, $logo->img_uuid, $filename, $logo->img_upd_dtim->epoch );
}

=head2 get_mlid

Returns mailing list id for Lyris (EmailLabs) for use with Lyris::API.

=cut

sub get_mlid {
    my $self = shift;
    my $xuuids = $self->find_org_sys_id( query => [ osid_type => 'E' ] );
    if ( $xuuids and @$xuuids ) {
        return $xuuids->[0]->osid_xuuid();
    }
    return undef;
}

=head2 get_active_parents_ids

Similar to the method in the Organization.php Doctrine model.
Returns array ref of org_ids for all active parents.

=cut

sub get_active_parents_ids {
    my $self   = shift;
    my $pids   = [];
    my $parent = $self->parent;
    while ( $parent
        && ( $parent->org_status ne 'F' ) )
    {
        last
            if $parent->org_id == $self->org_id;
        push @$pids, $parent->org_id;
        $parent = $parent->parent;
    }
    return $pids;
}

=head2 collect_related_org_ids( I<org_ids_array_ref> )

Returns I<org_ids_array_ref> fleshed out with all related children
and parent org_ids. NOTE that because I<org_ids_array_ref> is a reference
it is modified in-place.

=cut

sub collect_related_org_ids {
    my $self = shift;
    my $org_ids = shift or croak "org_ids required";

    if ( $self->org_status ne 'F' ) {
        push @$org_ids, $self->org_id;
    }
    for my $oid ( @{ $self->get_active_parents_ids() } ) {
        push @$org_ids, $oid;
    }
    for my $o ( @{ $self->children } ) {
        next if $o->org_id == $self->org_id;
        $o->collect_related_org_ids($org_ids);
    }

    return $org_ids;
}

=head2 get_org_levels

Static method to return an array of org_ids at each depth.  The org_ids are
a hash of (org_id => 1).

=cut

my %org_map;
my @org_levels;
my %org_children;
my %org_parents;

sub get_org_levels {
    if (@org_levels) {
        return \@org_levels;
    }

    # map org_ids to parents
    %org_map = map { $_->org_id => $_->org_parent_id }
        @{ AIR2::Organization->fetch_all };
    for my $org_id ( keys %org_map ) {
        my $parent_id = $org_map{$org_id};
        my $depth     = 0;

        # calculate depth
        while ( defined $parent_id ) {
            $depth++;
            $parent_id = $org_map{$parent_id};
            if (   defined $parent_id
                && defined $org_map{$parent_id}
                && $parent_id == $org_map{$parent_id} )
            {
                croak "ERROR: org $parent_id has recursive parent!";
            }
        }

        # add this org_id at the correct depth
        $org_levels[$depth]->{$org_id} = 1;
    }
    return \@org_levels;
}

=head2 get_org_children( I<org_id> )

Static method to return an array of org_ids that represent the current org and
all the descendant orgs.  (This amounts to a tree at root=I<org_id>).

=cut

sub clear_caches {
    %org_map      = ();
    @org_levels   = ();
    %org_children = ();
    %org_parents  = ();
}

sub get_org_children {
    my $org_id = shift;
    if ( $org_children{$org_id} ) {
        return $org_children{$org_id};
    }

    # make sure org_map has been loaded
    unless (%org_map) {
        get_org_levels();
    }

    # start with this org_id
    my @ids = ($org_id);

    # find direct children of this org
    my @direct;
    for my $oid ( keys %org_map ) {
        my $pid = $org_map{$oid};
        push( @direct, $oid ) if ( $pid && $pid == $org_id );
    }

    # find children-of-children (recursive)
    for my $did (@direct) {
        my $descendents = get_org_children($did);
        for my $desc_id ( @{$descendents} ) {
            push( @ids, $desc_id );
        }
    }

    $org_children{$org_id} = \@ids;
    return \@ids;
}

=head2 get_org_parents( I<org_id> )

Static method to return an array of org_ids that represent direct
ancestors of I<org_id>.

=cut

sub get_org_parents {
    my $org_id = shift;
    if ( $org_parents{$org_id} ) {
        return $org_parents{$org_id};
    }

    # make sure org_map has been loaded
    unless (%org_map) {
        get_org_levels();
    }

    my $parents   = [];
    my $parent_id = $org_map{$org_id};
    while ( defined $parent_id ) {
        push @$parents, $parent_id;
        $parent_id = $org_map{$parent_id};
    }
    return $parents;
}

=head2 sort_by_depth( I<arrayref>, i<sort_field> )

Helper function to sort an array of org_ids by org depth

=cut

sub sort_by_depth {
    my $array     = shift or die 'array reference required';
    my $orgid_fld = shift or die 'org_id field required';

    # sort input array
    my $levels = get_org_levels();
    my @result;
    for my $lvl ( @{$levels} ) {
        for my $item ( @{$array} ) {
            my $org_id = $item->{$orgid_fld};

            # look for org id in this level
            push( @result, $item ) if ( $lvl->{$org_id} );
        }
    }
    return \@result;
}

=head2 is_active

Returns true if org_status has any value that logically equates
to "not in-active".

=cut

sub is_active {
    my $self = shift;
    if ( $self->org_status eq 'F' ) {
        return 0;
    }
    return 1;
}

sub get_rss_feed {
    my $self          = shift;
    my $limit         = shift || 100;
    my $use_evergreen = shift;
    my @feed;
    my $inqs
        = $self->inquiries_iterator( sort_by => 't2.inq_publish_dtim DESC' );
    my $count = 0;
INQ: while ( my $inq = $inqs->next ) {
        if ( $inq->is_published() and $inq->inq_rss_status eq 'Y' ) {
            push @feed, $inq;
            if ( ++$count >= $limit ) {
                last INQ;
            }
        }
    }
    if ( !@feed and $use_evergreen ) {
        @feed = @{ AIR2::Inquiry->get_evergreens() };
    }
    return \@feed;
}

sub get_rss_cache_path {
    my $self = shift;
    my $root = AIR2::Config::get_rss_cache_dir();
    if ( !-d $root->subdir('org') ) {
        $root->subdir('org')->mkpath(1);
    }
    return sprintf( "%s/org/%s.rss", $root, $self->org_name );
}

1;
