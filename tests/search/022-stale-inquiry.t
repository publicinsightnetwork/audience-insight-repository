#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 29;
use lib 'tests/search';
use AIR2TestUtils;
use AIR2::Config;
use Data::Dump qw( dump );

# test classes that clean up automatically
use AIR2Test::Source;
use AIR2Test::Project;
use AIR2Test::SrcResponseSet;
use AIR2Test::Organization;
use AIR2Test::Inquiry;
use AIR2Test::User;

my $TEST_ORG_NAME = 'testorg';
my $TEST_USERNAME = 'ima-test-user';
my $TEST_PROJECT  = 'ima-test-project';
my $TEST_INQ_UUID = 'testinq12345';
my $DEBUG         = $ENV{AIR2_DEBUG} || 0;

my $server_cmd = AIR2::Config->get_app_root->file('bin/search-server');
system("$^X $server_cmd stop_watcher");

END {
    system("$^X $server_cmd start_watcher");
}

# create dummy records
# then create xml and make sure relevant relations
# get updated via watch-stale-records.
# see Redmine #4275 for reference.

my $unix_pid        = Unix::PID::Tiny->new;
my $app_root        = AIR2::Config->get_app_root();
my $watcher_pidfile = $app_root->file("var/watch-stale-records.pid");

# do not test with watcher running because it might delete
# files before we can test for their existence
if ( -s $watcher_pidfile ) {
    die "Watcher is running";
}

# base line time
my $now = time();

sleep(1);    # some time should pass

ok( my $project = AIR2Test::Project->new(
        prj_name         => $TEST_PROJECT,
        prj_display_name => $TEST_PROJECT,
    ),
    "new project"
);

ok( $project->save, "save project" );

ok( my $org1 = AIR2Test::Organization->new(
        org_default_prj_id => $project->prj_id,
        org_name           => $TEST_ORG_NAME,
        )->save(),
    "create test org1"
);

ok( my $user = AIR2Test::User->new(
        user_username   => $TEST_USERNAME,
        user_first_name => 'First',
        user_last_name  => 'Last',
    ),
    "create test user"
);
ok( $user->save(), "save test user" );

# must do this AFTER we set default_prj_id above
ok( $project->add_project_orgs(
        [   {   porg_org_id          => $org1->org_id,
                porg_contact_user_id => $user->user_id,
            },
        ]
    ),
    "add org to project"
);
ok( $project->save(), "write ProjectOrgs" );

ok( my $source = AIR2Test::Source->new(
        src_username  => $TEST_USERNAME,
        src_post_name => 'esquire',
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

# must do this explicitly since orgs are cached at startup
AIR2::SrcOrgCache::refresh_cache($source);

ok( my $inq = AIR2Test::Inquiry->new(
        inq_uuid  => $TEST_INQ_UUID,
        inq_title => 'the color query',
        cre_user  => $user,
        )->save,
    "create test inquiry"
);

ok( $inq->add_projects(          [$project] ), "add project to inquiry" );
ok( $inq->add_users_as_authors(  [$user] ),    "add authors to inquiry" );
ok( $inq->add_users_as_watchers( [$user] ),    "add watchers to inquiry" );

ok( my $ques
        = AIR2::Question->new( ques_value => 'what is your favorite color' ),
    "new question"
);
ok( $inq->add_questions( [$ques] ), "add question" );
ok( $inq->save, "save inquiry" );

is( $user->has_related('inquiries_as_watcher'),
    1, "user is watching 1 inquiry" );
is( $user->has_related('inquiries_as_author'),
    1, "user is authoring 1 inquiry" );
is( $inq->has_related('authors'),  1, "inquiry has one author" );
is( $inq->has_related('watchers'), 1, "inquiry has one watcher" );

ok( my $srs = AIR2Test::SrcResponseSet->new(
        srs_src_id => $source->src_id,
        srs_inq_id => $inq->inq_id,
        srs_date   => time(),
    ),
    "new SrcResponseset"
);
ok( my $response = AIR2::SrcResponse->new(
        sr_src_id     => $source->src_id,
        sr_ques_id    => $ques->ques_id,
        sr_orig_value => "blue is my favorite color",
    ),
    "new response"
);
ok( $srs->add_responses( [$response] ), "add responses" );
ok( $srs->save(), "save SrcResponseSet" );

# test data complete
# run the tests
sleep(1);    # so mod time is in the past

# clear the table so we can know we started fresh
my $dbh = AIR2::DBManager->new->dbh;
$dbh->do("delete from stale_record where str_type = 'I'");
$dbh->do("delete from stale_record where str_type = 'R'");

my $proj2xml_output = AIR2TestUtils::run_it(
    "$^X $app_root/bin/projects2xml.pl --mod $now --touch_stale_kids");

$DEBUG and diag( dump $proj2xml_output );

# we should have some stale records
my $stale_inquiries
    = AIR2::StaleRecord->fetch_count( query => [ str_type => 'I' ] );
is( $stale_inquiries, 1, "one stale inquiry flagged" );

my $stale_responses
    = AIR2::StaleRecord->fetch_count( query => [ str_type => 'R' ] );
is( $stale_responses, 1, "one stale submission flagged" );

# now submissions
$dbh->do("delete from stale_record where str_type = 'I'");

my $resp2xml_output
    = AIR2TestUtils::run_it("$^X $app_root/bin/resp2xml.pl --mod $now");
$DEBUG and diag( dump $resp2xml_output );

$stale_inquiries
    = AIR2::StaleRecord->fetch_count( query => [ str_type => 'I' ] );
is( $stale_inquiries, 1, "one stale inquiry flagged" );

