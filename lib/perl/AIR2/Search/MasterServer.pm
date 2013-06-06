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

package AIR2::Search::MasterServer;
use strict;
use warnings;
use Carp;
use JSON;
use Plack::Builder;
use Plack::Request;
use Plack::App::URLMap;
use Data::Dump qw( dump );
use AIR2::Search::Authenticator;
use AIR2::Config;
use AIR2::SearchUtils;
use Dezi::UI;
use Module::Load;

our $VERSION = AIR2::Config->get_version();

sub about {
    my ( $self, $req, $loaded_indexes, $config ) = @_;

    if ( $req->path ne '/' ) {
        my $resp = 'Resource not found';
        return [
            404,
            [   'Content-Type'   => 'text/plain',
                'Content-Length' => length $resp,
            ],
            [$resp]
        ];
    }

    my $base_uri = $config->{base_uri} || $req->base;
    my %avail = ();
    for my $i (@$loaded_indexes) {
        $avail{$i} = $base_uri . $i;
    }

    my $about = {
        description => 'This is the AIR search server.',
        version     => $VERSION,
        available   => \%avail,
    };
    my $resp = to_json($about);
    return [
        200,
        [   'Content-Type'   => 'application/json',
            'Content-Length' => length $resp,
        ],
        [$resp],
    ];
}

sub app {

    my ( $class, $config ) = @_;

    my %routing_map = (
        'sources'                => 'FuzzySources',
        'active-sources'         => 'FuzzyActiveSources',
        'primary-sources'        => 'FuzzyPrimarySources',
        'fuzzy-sources'          => 'FuzzySources',
        'fuzzy-active-sources'   => 'FuzzyActiveSources',
        'fuzzy-primary-sources'  => 'FuzzyPrimarySources',
        'strict-sources'         => 'Sources',
        'strict-active-sources'  => 'ActiveSources',
        'strict-primary-sources' => 'PrimarySources',
        'inquiries'              => 'Inquiries',
        'projects'               => 'Projects',
        'responses'              => 'FuzzyResponses',
        'fuzzy-responses'        => 'FuzzyResponses',
        'strict-responses'       => 'Responses',
        'public-responses'       => 'PublicResponses',
    );

    my $url_map = Plack::App::URLMap->new();
    my @loaded_indexes;
    for my $path ( keys %routing_map ) {
        my $server_class = 'AIR2::Search::Server::' . $routing_map{$path};
        unless ( $config->{skip}->{$path} ) {
            load $server_class;
            $url_map->map(
                '/' . $path => builder {
                    mount '/' => $server_class->app(
                        $config->{$path}
                            || {
                            debug         => $config->{debug},
                            engine_config => $config->{engine_config},
                            ui_class      => 'Dezi::UI',
                            }
                    );
                }
            );
            push @loaded_indexes, $path;
        }
    }

    # Reporter classes provide metrics and stats
    unless ( $config->{skip}->{reporter} ) {
        load 'AIR2::Reporter::Org';
        $url_map->map(
            '/report/org' => builder {
                mount '/' => AIR2::Reporter::Org->new();
            }
        );
    }

    return builder {

        # global logging
        enable "SimpleLogger", level => $config->{'debug'} ? "debug" : "warn";

        enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }
        "Plack::Middleware::ReverseProxy";

        # AIR authn
        enable "+AIR2::Search::Authenticator";

        # optional gzip compression for clients that request it
        # client must set "Accept-Encoding" request header
        enable "Deflater",
            content_type => [
            'text/css',        'text/html',
            'text/javascript', 'application/javascript',
            'text/xml',        'application/xml',
            'application/json',
            ],
            vary_user_agent => 1;

        # default is just self-description
        $url_map->map(
            '/' => sub {
                my $req = Plack::Request->new(shift);
                return $class->about( $req, \@loaded_indexes, $config );
            }
        );

        $url_map->map(
            '/favicon.ico' => sub {
                my $req = Plack::Request->new(shift);
                my $res = $req->new_response();
                $res->redirect(
                    'http://www.publicinsightnetwork.org/favicon.ico', 301 );
                $res->finalize();
            }
        );

        # TODO /admin

        $url_map->to_app;
    };

}

1;
