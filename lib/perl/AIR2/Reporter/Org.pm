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

package AIR2::Reporter::Org;
use strict;
use warnings;
use base 'AIR2::Reporter';
use Carp;
use AIR2::Config;
use AIR2::Utils;
use DateTime;
use Search::OpenSearch;

sub prepare_app {
    my $self = shift;
    $self->SUPER::prepare_app(@_);
    my %searchers = (
        sources => Search::OpenSearch->engine(
            type  => 'Lucy',
            index => [ AIR2::Config->get_search_index_path('sources') ],
            )->searcher,
        inquiries => Search::OpenSearch->engine(
            type  => 'Lucy',
            index => [ AIR2::Config->get_search_index_path('inquiries') ],
            )->searcher,
        responses => Search::OpenSearch->engine(
            type  => 'Lucy',
            index => [ AIR2::Config->get_search_index_path('responses') ],
            )->searcher,
    );
    $self->searchers( \%searchers );
    return $self;
}

my %base_defs = (
    'sources' => {
        idx   => 'sources',
        today => 'org_status_date=%s_A_%s',
        month => 'org_status_month=%s_A_%s',
        year  => 'org_status_year=%s_A_%s',
        total => 'org_status=%s_A',
    },
    'available_sources' => {
        idx   => 'sources',
        today => 'org_status_date=%s_A_%s and src_status=(A or E or T)',
        month => 'org_status_month=%s_A_%s and src_status=(A or E or T)',
        year  => 'org_status_year=%s_A_%s and src_status=(A or E or T)',
        total => 'org_status=%s_A and src_status=(A or E or T)',
    },
    'primary_sources' => {
        idx   => 'sources',
        today => 'primary_org_name=%s and org_status_date=%s_A_%s',
        month => 'primary_org_name=%s and org_status_month=%s_A_%s',
        year  => 'primary_org_name=%s and org_status_year=%s_A_%s',
        total => 'primary_org_name=%s and org_status=%s_A',
    },
    'available_primary_sources' => {
        idx => 'sources',
        today =>
            'primary_org_name=%s and org_status_date=%s_A_%s and src_status=(A or E or T)',
        month =>
            'primary_org_name=%s and org_status_month=%s_A_%s and src_status=(A or E or T)',
        year =>
            'primary_org_name=%s and org_status_year=%s_A_%s and src_status=(A or E or T)',
        total =>
            'primary_org_name=%s and org_status=%s_A and src_status=(A or E or T)',
    },
    'opted_out' => {
        idx   => 'sources',
        today => 'org_status_date=%s_F_%s',
        month => 'org_status_month=%s_F_%s',
        year  => 'org_status_year=%s_F_%s',
        total => 'org_status=%s_F',
    },
    'unsubscribed' => {
        idx   => 'sources',
        today => 'org_status=%s_A and activity_type_date=22%s',
        month => 'org_status=%s_A and activity_type_month=22%s',
        year  => 'org_status=%s_A and activity_type_year=22%s',
        total => 'org_name=%s and src_status=U',
    },
    'sources_queried' => {
        idx   => 'sources',
        today => 'org_status=%s_A and last_queried_date=%s',
        month => 'org_status=%s_A and last_queried_month=%s',
        year  => 'org_status=%s_A and last_queried_year=%s',
        total => 'org_status=%s_A and last_queried_date!=19700101',
    },
    'queries' => {
        idx   => 'inquiries',
        today => 'org_name=%s and inq_publish_date=%s',
        month => 'org_name=%s and inq_publish_month=%s',
        year  => 'org_name=%s and inq_publish_year=%s',
        total => 'org_name=%s',
    },
    'submissions' => {
        idx   => 'responses',
        today => 'org_name=%s and srs_ts=%s',
        month => 'org_name=%s and srs_month=%s',
        year  => 'org_name=%s and srs_year=%s',
        total => 'org_name=%s',
    },
);

sub get_uri {
    my $self     = shift;
    my $opts     = shift or croak "opts required";
    my $org_name = $opts->{org_name} or croak "org_name required";
    return $org_name;
}

sub query_defs {
    my $self     = shift;
    my $opts     = shift or croak "opts required";
    my $org_name = $opts->{org_name} or croak "org_name required";

    my $now = DateTime->now();
    $now->set_time_zone( AIR2::Config->get_tz() );
    my $last_month  = $now->clone->subtract( months => 1 );
    my $last2_month = $now->clone->subtract( months => 2 );

    my %when = (
        'today' => $now->ymd(''),
        'month' => sprintf( "%s%02d", $now->year, $now->month ),
        'prev_month' =>
            sprintf( "%s%02d", $last_month->year, $last_month->month ),
        'year' => $now->year,
    );

    my %defs;

    for my $k ( keys %base_defs ) {
        for my $w ( keys %when ) {
            my $date = $when{$w};
            my $newk = $k . '_' . $w;
            my $tpl;
            if ( exists $base_defs{$k}->{$w} ) {
                $tpl = $base_defs{$k}->{$w};
            }
            elsif ( $w eq 'prev_month' ) {
                $tpl = $base_defs{$k}->{month};
            }

            $defs{$newk} = { idx => $base_defs{$k}->{idx} };

            if ( $k eq 'sources' or $k eq 'available_sources' ) {
                $defs{$newk}->{q} = sprintf( $tpl, $org_name, $date );
            }
            elsif ($k eq 'primary_sources'
                or $k eq 'available_primary_sources' )
            {
                $defs{$newk}->{q}
                    = sprintf( $tpl, $org_name, $org_name, $date );
            }
            elsif ( $k eq 'opted_out' ) {
                $defs{$newk}->{q} = sprintf( $tpl, $org_name, $date );
            }
            else {
                $defs{$newk}->{q} = sprintf( $tpl, $org_name, $date );
            }
        }
        my $total;
        my $tpl = $base_defs{$k}->{total};
        if ( $k eq 'primary_sources' or $k eq 'available_primary_sources' ) {
            $total = sprintf( $tpl, $org_name, $org_name );
        }
        else {
            $total = sprintf( $tpl, $org_name );
        }

        $defs{ $k . '_total' }
            = { idx => $base_defs{$k}->{idx}, q => $total };
    }
    return \%defs;
}

1;

