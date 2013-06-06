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

package AIR2::SrcOrgCache;
use strict;
use base qw(AIR2::DB);
use Carp;
use Data::Dump qw( dump );
use Scalar::Util qw( blessed );

__PACKAGE__->meta->setup(
    table => 'src_org_cache',

    columns => [
        soc_src_id => { type => 'integer',   not_null => 1 },
        soc_org_id => { type => 'integer',   not_null => 1 },
        soc_status => { type => 'character', length   => 1, not_null => 1 },
    ],

    primary_key_columns => [ 'soc_src_id', 'soc_org_id' ],

    foreign_keys => [
        organization => {
            class       => 'AIR2::Organization',
            key_columns => { soc_org_id => 'org_id' },
        },

        source => {
            class       => 'AIR2::Source',
            key_columns => { soc_src_id => 'src_id' },
        },

    ],
);

=head2 refresh_cache( I<Source> )

Static method to refresh the src_org_cache from a Source object ref

=cut

sub refresh_cache {
    my $source = shift or croak "Source object ref required";
    my $src_id;
    my $dbh;

    # get new or existing handle based on what was passed in
    if ( !blessed($source) ) {
        if ( $source =~ m/\D/ ) {
            $source = AIR2::Source->new( src_uuid => $source )->load;
            $src_id = $source->src_id;
        }
        else {
            $src_id = $source;
        }

        # NOTE we use new() and not new_or_cached() to try and work around
        # occasional lock error with do() below.
        $dbh = AIR2::DBManager->new()->get_write_handle->retain_dbh;
    }
    elsif ( !$source->isa('AIR2::Source') ) {
        croak "Source object is not a AIR2::Source instance (is a "
            . blessed($source) . ")";
    }
    else {
        $src_id = $source->src_id;
        $dbh    = $source->db->get_write_handle->retain_dbh;
    }

    # drop existing cache table
    $dbh->do("delete from src_org_cache where soc_src_id = $src_id");

    # re-cache authz
    my $insert
        = "insert into src_org_cache (soc_src_id, soc_org_id, soc_status)";
    my $authz_orgs = AIR2::Source::get_authz_status($src_id);

    #warn "authz_orgs: " . dump($authz_orgs) . "\n";
    for my $org_id ( keys %{$authz_orgs} ) {
        my $stat = $authz_orgs->{$org_id};
        my $sql  = "$insert values ($src_id, $org_id, '$stat')";

        #warn "soc: $sql\n";
        $dbh->do($sql);
    }
}

1;

