#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;
use lib 'tests/search';
use AIR2TestUtils;    # sets lib path
use AIR2::Search::MasterServer;
use AIR2::SrcResponseSet;
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
    my $sr     = AIR2::SrcResponse->new(
        sr_src_id     => 205021,
        sr_ques_id    => 32776,
        sr_srs_id     => 1260468,
        sr_orig_value => "this is an ellipsis: $ellips",
    );
    $sr->load_or_save;

    my $uuid = $sr->srcresponseset->srs_uuid;

    my $srs
        = AIR2::SrcResponseSet->new( srs_uuid => $uuid )->load_speculative;
    if ( !$srs or $srs->not_found ) {
        skip "Can't find utf-8 encoded response $uuid in db. Skipping tests",
            5;
    }

    # add to index
    my $base_dir = AIR2::Config->get_search_xml->subdir('responses');
    $base_dir->mkpath(1);

    my $xml = $srs->as_xml( { base_dir => $base_dir } );
    my $tkt = AIR2TestUtils::dummy_tkt( 37, 44 );
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

    # clean up
    $sr->delete;

    test_psgi(
        app    => AIR2::Search::MasterServer->app( {} ),
        client => sub {
            my $callback = shift;
            my $params   = URI::Query->new(
                {   q        => "srs_uuid:$uuid",
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

            ok( my $qas = $json->{results}->[0]->{qa}, "get qa" );

            #dump($qas);

            is( scalar(@$qas), 4, "got 4 qa" );

            for my $qa (@$qas) {
                next unless $qa =~ qr/$ellips/;
                like( $qa, qr/$ellips/, "matches utf8 character" );
            }

        },

    );

}
