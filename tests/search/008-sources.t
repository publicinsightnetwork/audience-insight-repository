#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 24;
use lib 'tests/search';
use AIR2TestUtils;    # sets lib path
use AIR2::Search::MasterServer;
use Data::Dump qw( dump );
use JSON;
use Plack::Test;
use URI::Query;

SKIP: {

    if ( !AIR2TestUtils::search_env_ok() ) {
        skip "The search env does not look sane. Skipping all tests", 24;
    }

    my $tkt = AIR2TestUtils::dummy_tkt();

    test_psgi(
        app    => AIR2::Search::MasterServer->app( {} ),
        client => sub {
            my $callback = shift;
            my $params   = URI::Query->new(
                {   q        => 'oil spill',
                    air2_tkt => $tkt,
                    p        => 3,             # small for speed
                }
            );
            my $req
                = HTTP::Request->new( GET => "/sources/search?" . $params );
            my $resp = $callback->($req);

            #dump $resp;
            ok( my $json = decode_json( $resp->content ),
                "json decode body of response" );

            ok( exists $json->{unauthz_total}, "unauthz_total present" );

            #dump( $json );

            cmp_ok(
                $json->{total}, '<=',
                $json->{unauthz_total},
                "unauthz_total > total"
            );

            my @expected_fields = qw(
                primary_location
                primary_email
                primary_phone
                excerpts
                title
                uri
                summary

            );

            for my $res ( @{ $json->{results} } ) {

                for my $f (@expected_fields) {
                    ok( defined $res->{$f}, "$f defined" );

                }
            }

        },
    );

}
