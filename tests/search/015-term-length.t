#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;
use lib 'tests/search';
use AIR2TestUtils;    # sets lib path
use AIR2::Search::MasterServer;
use Data::Dump qw( dump );
use JSON;
use utf8;
use URI::Query;
use Plack::Test;

SKIP: {

    if ( !AIR2TestUtils::search_env_ok() ) {
        skip "The search env does not look sane. Skipping all tests", 2;
    }

    my $tkt = AIR2TestUtils::dummy_tkt();

    my $config
        = do AIR2::Config->get_app_root->file('etc/dezi.config.pl') . "";

    test_psgi(
        app    => AIR2::Search::MasterServer->app($config),
        client => sub {
            my $callback = shift;
            my $query    = URI::Query->new(
                {   q        => 'a',
                    air2_tkt => $tkt,
                }
            );
            my $req
                = HTTP::Request->new( GET => "/sources/search?" . $query );
            my $resp = $callback->($req);

            #dump($resp);

            is( $resp->code, 500, "too short term throws server error" );
            if ( $resp->code == 500 ) {
                like( $resp->content, qr/at least 2/, "error msg match" );
            }
            else {
                fail('got response other than 500');
                my $body = decode_json( $resp->content );
                diag( $body->{query} );
                diag( dump $body );
            }

        },
    );

}
