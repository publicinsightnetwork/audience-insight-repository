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

package AIR2::Reporter;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use JSON;
use base 'Plack::Middleware';
use Search::OpenSearch::Response::JSON;
use Search::OpenSearch::Response::XML;
use Search::OpenSearch::Response::ExtJS;
use Time::HiRes qw( time );
use CHI;
use Path::Class::Dir;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use Plack::Util::Accessor (qw( searchers cache cache_ttl debug ));

sub prepare_app {
    my $self = shift;
    if ( !$self->cache ) {
        my $cache_dir = Path::Class::Dir->new('/tmp/air2/search/cache');
        $cache_dir->mkpath();

        $self->{cache} = CHI->new(
            driver           => 'File',
            root_dir         => "$cache_dir/reporter",
            dir_create_mode  => 0770,
            file_create_mode => 0660,
            on_set_error     => 'die',
        );

    }
    $self->{cache_ttl} ||= 60 * 60 * 2;    # 2 hours

    return $self;
}

sub log {
    my $self = shift;
    return if $ENV{AIR2_QUIET};
    AIR2::Utils::logger(@_);
}

sub call {
    my $self            = shift;
    my $request         = Plack::Request->new(shift);
    my $params          = $request->parameters->as_hashref_mixed;
    my $search_response = $self->do_report($params);

    # build HTTP response
    my $http_response = $request->new_response;

    if ( !$search_response ) {
        $http_response->status(500);
        $http_response->content_type('application/json');
        $http_response->body(
            encode_json( { success => 0, msg => 'Internal error' } ) );
    }
    elsif ( !$search_response->success ) {
        $http_response->status(400);
        $http_response->content_type('application/json');
        $http_response->body(
            encode_json( { success => 0, msg => 'Bad request' } ) );
    }
    else {
        $http_response->status(200);
        $http_response->content_type( $search_response->content_type );
        $http_response->body("$search_response");
    }

    return $http_response->finalize();
}

sub do_report {
    my ( $self, $params ) = @_;

    my $format          = $params->{t} || $params->{format} || 'ExtJS';
    my $response_class  = 'Search::OpenSearch::Response::' . $format;
    my $search_response = $response_class->new();

    my $uri;
    eval { $uri = $self->get_uri($params); };
    if ($@) {
        warn $@;    # so we get it in server log
        $search_response->success(0);
        return $search_response;
    }
    my $start     = time();
    my $q         = encode_json($params);
    my $cache_key = md5_hex($uri);
    my %results;

    if ( !$params->{ignore_cache} and $self->cache->is_valid($cache_key) ) {
        %results = %{ $self->cache->get($cache_key) };
    }
    else {
        my $query_defs = $self->query_defs($params);
        for my $name ( sort keys %$query_defs ) {
            my $idx      = $query_defs->{$name}->{idx};
            my $searcher = $self->searchers->{$idx};
            if ( !$searcher ) {
                croak "No idx searcher for $idx";
            }
            my $res;
            eval {
                $res = $searcher->search( $query_defs->{$name}->{q},
                    { max => 1_000_000 } );
            };
            croak $@ if $@;
            my $total = 0;
            if ( $query_defs->{$name}->{sum} ) {
                while ( my $r = $res->next ) {
                    $total += $r->get_property( $query_defs->{$name}->{sum} )
                        || 0;
                }
            }
            else {
                $total = $res->hits;
            }
            $results{$name} = {
                c => $total,
                i => $query_defs->{$name}->{idx},
                q => $query_defs->{$name}->{q}
            };

            #warn "$name ($query_defs->{$name}->{q}) => $total\n";
        }

        $self->log("caching results for $cache_key");
        my $rt = $self->cache->set( $cache_key, \%results, $self->cache_ttl );
    }
    $results{uri} = $self->get_uri($params);

    $search_response->parsed_query($q);
    $search_response->author( ref($self) );
    $search_response->total(1);
    $search_response->success(1);
    $search_response->search_time( sprintf( "%0.5f", time() - $start ) );
    $search_response->results( [ \%results ] );
    $search_response->metaData(
        {   idProperty      => 'uri',
            root            => 'results',
            totalProperty   => 'total',
            successProperty => 'success',
            start           => $search_response->offset,
            limit           => $search_response->page_size,
            fields          => [
                map {
                    {   name => $_,
                        type => ref $results{$_} ? 'array' : 'string'
                    }
                    } sort keys %results
            ],
        }
    );
    $search_response->build_time( sprintf( "%0.5f", time() - $start ) );

    return $search_response;
}

sub query_defs {
    my $self = shift;
    my $opts = shift;
    croak "Must define query_defs for $self";
}

sub get_uri { croak "must define get_uri() in " . shift }

1;

