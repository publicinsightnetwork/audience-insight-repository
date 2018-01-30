#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;
use lib 'tests/search';
use AIR2TestUtils;    # sets lib path
use AIR2::Search::MasterServer;
use AIR2Test::SrcResponse;
use Data::Dump qw( dump );
use JSON;
use Plack::Test;
use URI::Query;
use Search::Tools::UTF8;
use Dezi::Client;
use utf8;

binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

SKIP: {

    if ( !AIR2TestUtils::search_env_ok() ) {
        skip "The search env does not look sane. Skipping all tests", 5;
    }

    # some known data to add a bona fide utf-8 ellipsis to
    my $ellips = "…";

    my $srs = AIR2::SrcResponseSet->new( srs_id => 1 )->load;
    my $sr = AIR2Test::SrcResponse->new(
        sr_orig_value => "this is an ellipsis: $ellips",
        sr_src_id     => 1,
        sr_ques_id    => $srs->inquiry->questions->[0]->ques_id,
        sr_srs_id     => 1,
    )->save;

    my $uuid = $srs->srs_uuid;

    # add to index
    my $base_dir = AIR2::Config->get_search_xml->subdir('responses');
    $base_dir->mkpath(1);

    my $xml         = $srs->as_xml( { base_dir => $base_dir } );
    my $tkt         = AIR2TestUtils::dummy_tkt( $srs->cre_user->user_id );
    my $dezi_client = Dezi::Client->new(
        server        => AIR2::Config->get_search_uri() . '/responses',
        server_params => { 'air2_tkt' => $tkt }
    );
    my $http_resp
        = $dezi_client->index( \$xml, $uuid, 'application/xml',
        { 'air2_tkt' => $tkt },
        );

    is( $http_resp->code, 200, "index updated with XML response" );
    if ( $http_resp->code ne 200 ) {
        diag( $http_resp->content );
    }

    test_psgi(
        app    => AIR2::Search::MasterServer->app( {} ),
        client => sub {
            my $callback = shift;
            my $params   = URI::Query->new(
                {   q        => "ellipsis",
                    air2_tkt => $tkt,
                }
            );
            my $req
                = HTTP::Request->new( GET => "/responses/search?" . $params );
            my $resp = $callback->($req);

            #dump $resp;
            ok( my $json = decode_json( $resp->content ),
                "json decode body of response" );

            #dump($json);

            my $result = $json->{results}->[0];
            like(
                $result->{summary},
                qr/ellipsis \.\.\./,
                'summary is ASCII'
            );

            ok( my $qas = $result->{qa}, "get qa" );

            #dump($qas);

            for my $qa (@$qas) {
                next unless $qa->{resp} =~ m/ellipsis/;
                my $utf8_octets = to_utf8( $qa->{resp} );
                like( $utf8_octets, qr/$ellips/, "matches utf8 character" );
            }

        },

    );

}
