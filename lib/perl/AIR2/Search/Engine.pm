###########################################################################
#
#   Copyright 2012 American Public Media Group
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

package AIR2::Search::Engine;
use strict;
use warnings;
use base qw( Search::OpenSearch::Engine::Lucy );
use DateTime;
use Carp;
use Data::Dump qw( dump );
use AIR2::Config;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use constant MAX_SUMMARY_LEN => 200;
use Time::HiRes qw( time );
use Encode;

sub version { return AIR2::Config::get_version }

=pod

=head1 NAME

AIR2::Search::Engine - subclass of Search::OpenSearch::Engine::Lucy

=head1 DESCRIPTION

Provides private methods, mostly for manipulating facet results.

=cut

# extend the basic response schema
Search::OpenSearch::Response::ExtJS->add_attribute('unauthz_total');
Search::OpenSearch::Response::JSON->add_attribute('unauthz_total');
Search::OpenSearch::Response::XML->add_attribute('unauthz_total');
Search::OpenSearch::Response::Tiny->add_attribute('unauthz_total');

# make our cache keys more complex
sub get_facets_cache_key {
    my ( $self, $query, $args ) = @_;
    my $query_bytes = encode_utf8($query);
    my $k = md5_hex( $self->searcher->invindex->[0]->path . $query_bytes );
    return $k;
}

# no-op
sub get_virtual_fields { return [] }

sub _cleanup_summary {
    my ( $self, $result, @summary ) = @_;

    my %uniq;
    my @cleaned;

    #warn "summary: " . dump \@summary;
    for (@summary) {
        s/\ +/ /g;
        s/^ //;
        s/ $//;
        next unless length;
        next if $uniq{$_}++;
        push @cleaned, $_;
    }

    #warn "uniq: " . dump( \%uniq );
    $result->{summary} = join( ' ... ', @cleaned );

    # clean up
    $result->{summary} =~ s/(\.\.\.\ +)+/... /g;

    # for space reasons, we always do brute-force truncate
    if ( length $result->{summary} > MAX_SUMMARY_LEN ) {
        $result->{summary} = substr( $result->{summary}, 0, MAX_SUMMARY_LEN );
        $result->{summary} .= ' ...';
    }

    return $result->{summary};
}

sub _summarize_uuid_title {
    my ( $self, $facets ) = @_;
    for my $f (@$facets) {
        my ( $uuid, $title ) = ( $f->{term} =~ m/^(.+?):(.+)/ );
        $f->{term}  = $uuid;
        $f->{label} = $title;
    }
    return $facets;
}

sub _summarize_prj_uuid_title {
    return shift->_summarize_uuid_title(@_);
}

sub _summarize_inq_uuid_title {
    return shift->_summarize_uuid_title(@_);
}

sub _do_date_range_summary {
    my ( $self, $facets ) = @_;
    my %ranges;
    my $now_dt = DateTime->now( time_zone => $AIR2::Config::TIMEZONE );
    my $now_date = $now_dt->ymd('');
    my $seven_days_ago     = $now_dt->clone->subtract( days => 7 )->ymd('');
    my $eight_days_ago     = $now_dt->clone->subtract( days => 8 )->ymd('');
    my $fifteen_days_ago   = $now_dt->clone->subtract( days => 15 )->ymd('');
    my $sixteen_days_ago   = $now_dt->clone->subtract( days => 16 )->ymd('');
    my $thirty_days_ago    = $now_dt->clone->subtract( days => 30 )->ymd('');
    my $thirtyone_days_ago = $now_dt->clone->subtract( days => 31 )->ymd('');
    my $sixty_days_ago     = $now_dt->clone->subtract( days => 60 )->ymd('');
    my $sixtyone_days_ago  = $now_dt->clone->subtract( days => 61 )->ymd('');
    my $ninety_days_ago    = $now_dt->clone->subtract( days => 90 )->ymd('');

    # define as array initially in the order we want it
    my @terms = (
        "0..7 days" => sprintf( "(%d..%d)", $seven_days_ago, $now_date ),
        "8..15 days" =>
            sprintf( "(%d..%d)", $fifteen_days_ago, $eight_days_ago ),
        "16..30 days" =>
            sprintf( "(%d..%d)", $thirty_days_ago, $sixteen_days_ago ),
        "31..60 days" =>
            sprintf( "(%d..%d)", $sixty_days_ago, $thirtyone_days_ago ),
        "61..90 days" =>
            sprintf( "(%d..%d)", $ninety_days_ago, $sixtyone_days_ago ),
        "90+ days" =>
            sprintf( "(%d..%d)", '19000101', ( $ninety_days_ago - 1 ) )
    );

    # coerce into a hash for easy key lookup
    my %terms_hash = @terms;
    my @term_order
        = grep {defined} map { exists $terms_hash{$_} ? $_ : undef } @terms;

    for my $f (@$facets) {
        my $date = $f->{term};
        my $c    = $f->{count};
        if ( $date >= $seven_days_ago && $date <= $now_date ) {
            $ranges{"0..7 days"} += $c;
        }
        if ( $date >= $fifteen_days_ago && $date <= $eight_days_ago ) {
            $ranges{"8..15 days"} += $c;
        }
        if ( $date >= $thirty_days_ago && $date <= $sixteen_days_ago ) {
            $ranges{"16..30 days"} += $c;
        }
        if ( $date >= $sixty_days_ago && $date <= $thirtyone_days_ago ) {
            $ranges{"31..60 days"} += $c;
        }
        if ( $date >= $ninety_days_ago && $date <= $sixtyone_days_ago ) {
            $ranges{"61..90 days"} += $c;
        }
        if ( $date < $ninety_days_ago ) {
            $ranges{"90+ days"} += $c;
        }
    }

    my @newfacets;

    # sort only for predictable order in tests
    for my $r (@term_order) {
        push @newfacets,
            {
            term  => $terms_hash{$r},
            label => $r,
            count => $ranges{$r} || 0,
            };
    }
    return \@newfacets;
}

# like standard date range but invert it to *exclude* terms in each range
sub _do_neg_date_range_summary {
    my ( $self, $facets ) = @_;
    my %ranges;
    my $now_dt = DateTime->now( time_zone => $AIR2::Config::TIMEZONE );
    my $now_date = $now_dt->ymd('');
    my $seven_days_ago     = $now_dt->clone->subtract( days => 7 )->ymd('');
    my $eight_days_ago     = $now_dt->clone->subtract( days => 8 )->ymd('');
    my $fifteen_days_ago   = $now_dt->clone->subtract( days => 15 )->ymd('');
    my $sixteen_days_ago   = $now_dt->clone->subtract( days => 16 )->ymd('');
    my $thirty_days_ago    = $now_dt->clone->subtract( days => 30 )->ymd('');
    my $thirtyone_days_ago = $now_dt->clone->subtract( days => 31 )->ymd('');
    my $sixty_days_ago     = $now_dt->clone->subtract( days => 60 )->ymd('');
    my $sixtyone_days_ago  = $now_dt->clone->subtract( days => 61 )->ymd('');
    my $ninety_days_ago    = $now_dt->clone->subtract( days => 90 )->ymd('');
    my @terms              = (
        "0..7 days" => sprintf( "(%d..%d)", $seven_days_ago, $now_date ),
        "8..15 days" =>
            sprintf( "(%d..%d)", $fifteen_days_ago, $eight_days_ago ),
        "16..30 days" =>
            sprintf( "(%d..%d)", $thirty_days_ago, $sixteen_days_ago ),
        "31..60 days" =>
            sprintf( "(%d..%d)", $sixty_days_ago, $thirtyone_days_ago ),
        "61..90 days" =>
            sprintf( "(%d..%d)", $ninety_days_ago, $sixtyone_days_ago ),
        "90+ days" =>
            sprintf( "(%d..%d)", '19000101', ( $ninety_days_ago - 1 ) )
    );

    # coerce into a hash for easy key lookup
    my %terms_hash = @terms;
    my @term_order
        = grep {defined} map { exists $terms_hash{$_} ? $_ : undef } @terms;

    for my $f (@$facets) {
        my $date = $f->{term};
        my $c    = $f->{count};
        if ( $date < $seven_days_ago && $date >= $now_date ) {
            $ranges{"0..7 days"} += $c;
        }
        if ( $date < $fifteen_days_ago || $date > $eight_days_ago ) {
            $ranges{"8..15 days"} += $c;
        }
        if ( $date < $thirty_days_ago || $date > $sixteen_days_ago ) {
            $ranges{"16..30 days"} += $c;
        }
        if ( $date < $sixty_days_ago || $date > $thirtyone_days_ago ) {
            $ranges{"31..60 days"} += $c;
        }
        if ( $date < $ninety_days_ago || $date > $sixtyone_days_ago ) {
            $ranges{"61..90 days"} += $c;
        }
        if ( $date > $ninety_days_ago ) {
            $ranges{"90+ days"} += $c;
        }
    }

    my @newfacets;

    # sort only for predictable order in tests
    for my $r (@term_order) {
        push @newfacets,
            {
            term  => $terms_hash{$r},
            label => $r,
            count => $ranges{$r} || 0,
            };
    }
    return \@newfacets;
}

sub build_facets {
    my $self   = shift;
    my $facets = $self->SUPER::build_facets(@_);

    # summarize for what client actually uses
    my %sum;

    for my $name ( keys %$facets ) {

        my $method = '_summarize_' . $name;
        if ( $self->can($method) ) {
            $sum{$name} = $self->$method( $facets->{$name} );
        }
        else {
            $sum{$name} = $facets->{$name};
        }
    }

    return \%sum;
}

sub get_uuids_only {
    my $self           = shift;
    my %args           = @_;
    my $query          = $args{'q'} or croak "'q' required";
    my $total          = $args{'p'} or croak "'p' required";
    my $enforce_total  = $args{'u'} == 2 ? 0 : 1;
    my $boolop         = $args{'b'} || 'AND';
    my $uuid_field     = $args{'uuid_field'} || 'uri';
    my $format         = $args{'t'} || $args{format} || 'ExtJS';
    my $response_class = $args{response_class}
        || 'Search::OpenSearch::Response::' . $format;

    my $start_time = time();
    my $searcher   = $self->searcher or croak "searcher not defined";
    my $results    = $searcher->search(
        $query,
        {   start          => 0,
            max            => $enforce_total ? $total : 1_000_000,
            default_boolop => $boolop,
        }
    );
    my $hits = $results->hits;

    if ( $enforce_total && $hits != $total ) {
        croak "Failed to find $total hits for '$query' (got $hits instead)";
    }
    my $response = $response_class->new();
    $response->search_time( sprintf( "%0.5f", time() - $start_time ) );
    my $start_build = time();
    my %uuids;
    my $total_uuids = 0;
    while ( my $r = $results->next ) {
        my $uuid = $r->{doc}->{$uuid_field};
        for my $u ( split( m/\003/, $uuid ) ) {
            if ( ++$uuids{$u} > 1 ) {
                warn "More than one $uuid_field=$u\n";
            }
            $total_uuids++;
        }
    }
    $response->build_time( sprintf( "%0.5f", time() - $start_build ) );
    $response->total($hits);
    $response->results( [ keys %uuids ] );

    if ( $hits != scalar @{ $response->results } ) {
        croak "Mismatch between hits ($hits) and UUID count ("
            . scalar( @{ $response->results } )
            . ") total_uuids=$total_uuids";
    }

    return $response;
}

=head2 search( I<args> )

Overrides base Engine method to add virtual fields.

=cut

sub search {
    my $self = shift;
    my $resp = $self->SUPER::search(@_);
    if ( $resp->fields ) {

        # lastmod is PropertyNameAlias in every index, for sorting.
        my @f = ( @{ $resp->fields }, @{ $self->get_virtual_fields },
            'lastmod' );
        for (@f) {
            s/\./_/g;    # javascript-friendly
        }
        $resp->fields( \@f );
    }
    return $resp;
}

sub _fetch_prop_values {
    my $self   = shift;
    my $result = shift or croak "SWISH::Prog::Result object required";
    my $res    = shift or croak "result HASH ref required";
    my $fields = shift or croak "fields ARRAY ref required";
    my $multival_fields = shift or croak "multival_fields HASH ref required";
    my $collapse_dupe_fields = shift
        or croak "collapse_dup_fields HASH ref required";
    my $XMLer = shift or croak "Search::Tools::XML object required";

    for my $field (@$fields) {
        my $str = $XMLer->escape(
            $XMLer->strip_markup( ( $result->get_property($field) || '' ) ) );

        # undo escaping of single quotes as that can cause
        # snipping/hiliting to fail. See redmine #6423
        $str =~ s/&apos;/'/g;

        # our .count fields (or any field based on an attr)
        # can choke javascript on the client because of the dot.
        my $api_field = $field;
        $api_field =~ s/\./_/g;

        if ( exists $multival_fields->{$field} ) {
            $res->{$api_field} = [ split( m/\003/, $str ) ];
            if ( exists $collapse_dupe_fields->{$field} ) {
                my %u = map { $_ => $_ } @{ $res->{$field} };
                $res->{$api_field} = [ keys %u ];
            }
        }
        else {
            if ( exists $collapse_dupe_fields->{$field} ) {
                $str =~ s/\003.+//;
            }
            $res->{$api_field} = $str;
        }
    }

    $res->{lastmod} = $result->get_property('lastmod');

    return $res;
}

sub _has_authz {
    my ( $self, $org_masks, $org_ids ) = @_;
    my %org_uniq = map { $_ => $_ } split( /,/, $org_ids );
    for my $oid ( keys %$org_masks ) {
        if ( exists $org_uniq{$oid} ) {
            return 1;    # found intersection
        }
    }
    return 0;
}

1;

