#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 10;
use lib 'tests/search';
use AIR2TestUtils;
use Data::Dump qw( dump );
use JSON;
use AIR2::Search::MasterServer;
use AIR2Test::Source;
use AIR2Test::Organization;
use Plack::Test;
use Unix::PID::Tiny;
use Dezi::Client;

my $TEST_ORG_NAME1 = 'testorg1';
my $TEST_USERNAME  = 'ima-test-user';
my $TEST_UUID      = 'abcdef123456';

SKIP: {

    if ( !AIR2TestUtils::search_env_ok() ) {
        skip "The search env does not look sane. Skipping all tests", 10;
    }

    # make sure our watcher is running
    my $unix_pid = Unix::PID::Tiny->new;
    my $watcher_pid_file
        = AIR2::Config->get_app_root->file('var/watch-stale-records.pid');
    if ( !-s $watcher_pid_file ) {
        skip "The watch-stale-records script is not running", 10;
    }
    my $watcher_pid = $watcher_pid_file->slurp;
    if ( !$watcher_pid or !$unix_pid->is_pid_running($watcher_pid) ) {
        skip "The watch-stale-records script is not running", 10;
    }

    # create dummy source record
    ok( my $org1 = AIR2Test::Organization->new(
            org_default_prj_id => 1,
            org_name           => $TEST_ORG_NAME1,
            )->load_or_save(),
        "create test org1"
    );
    ok( my $source = AIR2Test::Source->new(
            src_username  => $TEST_USERNAME,
            src_post_name => 'esquire',
            src_uuid      => $TEST_UUID,
        ),
        "new source"
    );
    ok( $source->add_emails(
            [ { sem_email => $TEST_USERNAME . '@nosuchemail.org' } ]
        ),
        "add email address"
    );
    ok( $source->add_organizations( [$org1] ), "add orgs to source" );
    ok( $source->save(), "save source" );

    # do this manually since load_or_save might miss it
    #AIR2::SrcOrgCache::refresh_cache($source);

    # allow the watcher to refresh its cache
    sleep(3);

    # ping the watcher
    ok( AIR2::SearchUtils::touch_stale($source), "touch_stale for source" );

    #diag( "src_id=" . $source->src_id );
    #diag( "src_uuid=" . $source->src_uuid );
    #diag( 'src authz=' . dump( $source->get_authz ) );

    # wait a little to give the watcher some time
    sleep 15;

    # verify that the source record was indexed
    ok( my $tkt = AIR2TestUtils::dummy_system_tkt(), "get dummy auth tkt" );

    #diag( "tkt=" . $tkt );

    test_psgi(
        app    => AIR2::Search::MasterServer->app( {} ),
        client => sub {
            my $callback = shift;
            my $req
                = HTTP::Request->new( GET =>
                    "/fuzzy-sources/search?q=src_username=$TEST_USERNAME&air2_tkt=$tkt"
                );
            my $resp = $callback->($req);

            #dump $resp;
            ok( my $json = decode_json( $resp->content ),
                "json decode body of response" );

            #dump($json);
            diag( "total: " . $json->{total} );
            is( $json->{total}, 1, "got one result" );
            is( $json->{results}->[0]->{uri}, $TEST_UUID,
                "got expected uri" );

            # clean up
            if ( $json->{total} ) {
                my $dezi_client = Dezi::Client->new(
                    server => AIR2::Config->get_search_uri . '/sources',
                    server_params => { air2_tkt => $tkt },

                    #debug         => 1,
                );
                my $r = $dezi_client->delete($TEST_UUID);
                diag( "search server clean up: " . $r->code );
            }
        },
    );

}
