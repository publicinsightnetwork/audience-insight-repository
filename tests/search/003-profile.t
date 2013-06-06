#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 20;
use lib 'tests/search';
use AIR2TestUtils;    # sets lib path
use AIR2::Search::MasterServer;
use Data::Dump qw( dump );
use JSON::XS;
use Plack::Test;

SKIP: {

    if ( !AIR2TestUtils::search_env_ok() ) {
        skip "The search env does not look sane. Skipping all tests", 20;
    }

    my $tkt = AIR2TestUtils::dummy_tkt();

    # loop for profiling
    my $count = 0;
    while ( $count++ < 10 ) {
        test_psgi(
            app    => AIR2::Search::MasterServer->app( {} ),
            client => sub {
                my $callback = shift;
                my $req      = HTTP::Request->new(
                    GET => "/sources/search?q=test&air2_tkt=$tkt" );
                my $resp = $callback->($req);

                #dump $resp;
                ok( my $json = decode_json( $resp->content ),
                    "json decode body of response" );

                #dump($json);

                cmp_ok( $json->{total}, '>', 2, "total for q=test" );
            },
        );

    }

}
