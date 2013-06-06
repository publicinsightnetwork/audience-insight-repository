#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use lib 'tests/search';
use AIR2TestUtils;
use Data::Dump qw( dump );
use JSON::XS;
use AIR2::Search::MasterServer;
use Plack::Test;

SKIP: {

    if ( !AIR2TestUtils::search_env_ok() ) {
        skip "The search env does not look sane. Skipping all tests", 4;
    }
    my $idx_dir = AIR2::Config->get_search_index();
    if ( !-d $idx_dir ) {
        skip "Index dir $idx_dir is not a directory on this system", 4;
    }

    ok( my $at  = AIR2TestUtils::new_auth_tkt(), "get auth tkt object" );
    ok( my $tkt = AIR2TestUtils::dummy_tkt(),    "get dummy auth tkt" );

    test_psgi(
        app    => AIR2::Search::MasterServer->app( {} ),
        client => sub {
            my $callback = shift;
            my $req      = HTTP::Request->new(
                GET => "/projects/search?q=test&air2_tkt=$tkt" );
            my $resp = $callback->($req);

            #dump $resp;
            ok( my $json = decode_json( $resp->content ),
                "json decode body of response" );

            #dump($json);

            cmp_ok( $json->{total}, '>', 2, "total for q=test" );
        },
    );

}

