#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use lib 'tests/search';
use AIR2TestUtils;    # sets lib path
use AIR2::Search::MasterServer;
use Data::Dump qw( dump );
use JSON;
use URI::Query;
use Plack::Test;

SKIP: {

    if ( !AIR2TestUtils::search_env_ok() ) {
        skip "The search env does not look sane. Skipping all tests", 3;
    }

    my $tkt = AIR2TestUtils::dummy_tkt();

    test_psgi(
        app    => AIR2::Search::MasterServer->app( {} ),
        client => sub {
            my $callback = shift;
            my $params   = URI::Query->new(
                {   q        => 'test',
                    air2_tkt => $tkt,
                    u        => 1,
                    p        => 100000,
                }
            );
            my $req
                = HTTP::Request->new( GET => "/sources/search?" . $params );
            my $resp = $callback->($req);

            #dump $resp;
            is( $resp->code, 500,
                "500 error when asking for mismatched number of results" );

            # parse number we expected
            my ($expected) = ( $resp->content =~ m/got (\d+) instead/ );
            $params = URI::Query->new(
                {   q        => 'test',
                    air2_tkt => $tkt,
                    u        => 1,
                    p        => $expected,
                }
            );
            $req = HTTP::Request->new( GET => "/sources/search?" . $params );
            $resp = $callback->($req);

            #dump $resp;
            ok( my $json = decode_json( $resp->content ),
                "json decode body of response" );

            #dump($json);

            cmp_ok( scalar( @{ $json->{results} } ),
                '==', $json->{total}, "got expected total results" );
        },
    );

}
