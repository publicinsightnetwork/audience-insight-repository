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
            my $query    = URI::Query->new(
                {   q        => 'h3 AND (photo OR change)',
                    air2_tkt => $tkt,
                }
            );
            my $req
                = HTTP::Request->new( GET => "/inquiries/search?" . $query );
            my $resp = $callback->($req);

            #dump($resp);

            ok( my $json = decode_json( $resp->content ),
                "json decode body of response" );

            #dump($json);

            ok( my $summary = $json->{results}->[0]->{summary},
                "get summary" );

            # summary should have no markup except highlighting
            unlike( $summary, qr/<h3>/i, "No <h3> tag in summary" );

        },
    );

}
