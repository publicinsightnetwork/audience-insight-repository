#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use lib "$FindBin::Bin/../../tests/search";
use lib "$FindBin::Bin/../../tests/search/models";
use Test::More tests => 22;
use AIR2::Utils;
use AIR2::Question;
use AIR2TestUtils;
use AIR2Test::Inquiry;
use AIR2Test::User;
use AIR2Test::Project;
use AIR2Test::Organization;
use JSON;
use Data::Dump qw( dump );

my $TEST_ORG_NAME1 = 'testorg1';
my $TEST_ORG_NAME2 = 'testorg2';
my $TEST_PROJECT   = 'ima-test-project';
my $TEST_USERNAME  = 'ima-test-user';

use_ok('AIR2::InquiryPublisher');

###################################################
# set up test data
ok( my $project = AIR2Test::Project->new(
        prj_name         => $TEST_PROJECT,
        prj_display_name => $TEST_PROJECT,
    ),
    "new project"
);
ok( $project->load_or_save, "save project" );
ok( my $org1 = AIR2Test::Organization->new(
        org_default_prj_id => $project->prj_id,
        org_name           => $TEST_ORG_NAME1,
        org_display_name   => uc($TEST_ORG_NAME1),
        )->load_or_save(),
    "create test org1"
);
ok( my $org2 = AIR2Test::Organization->new(
        org_default_prj_id => $project->prj_id,
        org_name           => $TEST_ORG_NAME2,
        org_display_name   => uc($TEST_ORG_NAME2),
        )->load_or_save(),
    "create test org2"
);
ok( my $user = AIR2Test::User->new(
        user_username   => $TEST_USERNAME,
        user_first_name => 'First',
        user_last_name  => 'Last',
    ),
    "create test user"
);
ok( $user->load_or_save(), "save test user" );

# must do this AFTER we set default_prj_id above
ok( $project->add_project_orgs(
        [   {   porg_org_id          => $org1->org_id,
                porg_contact_user_id => $user->user_id,
            },
            {   porg_org_id          => $org2->org_id,
                porg_contact_user_id => $user->user_id,
            }
        ]
    ),
    "add orgs to project"
);
ok( $project->save(), "write ProjectOrgs" );

ok( my $inquiry = AIR2Test::Inquiry->new(
        inq_uuid  => 'i am a uuid',
        inq_title => 'the color QUERY  ',
    ),
    "new Inquiry"
);
ok( my $question
        = AIR2::Question->new( ques_value => 'what is your favorite color' ),
    "new Question"
);
ok( $inquiry->add_questions($question), "add question to Inquiry" );
ok( $inquiry->add_projects( [$project] ), "add projects to Inquiry" );
ok( $inquiry->add_organizations($org1), "org1 is an Owner" );

ok( $inquiry->load_or_save(), 'get test data' );

##########################################
# publish, check artifacts
my $inq_uuid = $inquiry->inq_uuid;

ok( AIR2::InquiryPublisher->publish($inq_uuid), 'published' );

my $output_dir = AIR2::Config::get_app_root()->subdir('public_html/querys');

my $output_json = $output_dir->file( 'iamauuid' . '.json' );
my $output_html = $output_dir->file( 'iamauuid' . '.html' );

ok( -s "$output_json", "json exists" ) or diag("Couldn't find $output_json");
ok( -s "$output_html", "html exists" ) or diag("Couldn't find $output_html");

my $json = decode_json( $output_json->slurp );

#diag( dump($json) );

my $timestamp = $inquiry->inq_cre_dtim;
$timestamp =~ s/T/ /;

my $expected = {
    action     => AIR2::Config::get_constant('AIR2_BASE_URL') . 'q/iamauuid',
    method     => 'POST',
    source_url => AIR2::Config::get_constant('AIR2_MYPIN2_URL'),
    authors    => [
        { email => undef, first => "AIR2SYSTEM", "last" => "AIR2SYSTEM" },
    ],
    orgs => [
        {   color        => 777777,
            display_name => "TESTORG1",
            logo         => undef,
            name         => "testorg1",
            site         => undef,
            uuid         => $org1->org_uuid,
        },
    ],
    projects => [
        {   display_name => "ima-test-project",
            name         => "ima-test-project",
            orgs         => [ "testorg1", "testorg2" ],
            uuid         => $project->prj_uuid,
        },
    ],
    query => {
        inq_cache_dtim    => undef,
        inq_cache_user    => undef,
        inq_confirm_msg   => undef,
        inq_cre_dtim      => $timestamp,
        inq_deadline_dtim => undef,
        inq_deadline_msg  => undef,
        inq_desc          => undef,
        inq_ending_para   => undef,
        inq_expire_dtim   => undef,
        inq_expire_msg    => undef,
        inq_ext_title     => undef,
        inq_intro_para    => undef,
        inq_loc_id        => 52,
        inq_public_flag   => 0,
        inq_publish_dtim  => undef,
        inq_rss_intro     => undef,
        inq_rss_status    => "N",
        inq_stale_flag    => 1,
        inq_status        => "A",
        inq_title         => "the color QUERY",
        inq_tpl_opts      => undef,
        inq_type          => AIR2::Inquiry::TYPE_FORMBUILDER,
        inq_upd_dtim      => $timestamp,
        inq_url           => undef,
        inq_uuid          => "i am a uuid ",
        inq_xid           => undef,
        locale            => 'en_US',
    },
    questions => [
        {   ques_choices     => undef,
            ques_cre_dtim    => $timestamp,
            ques_dis_seq     => 20,
            ques_locks       => undef,
            ques_pmap_id     => undef,
            ques_public_flag => 0,
            ques_resp_opts   => undef,
            ques_resp_type   => "S",
            ques_status      => "A",
            ques_template    => undef,
            ques_type        => "T",
            ques_upd_dtim    => $timestamp,
            ques_uuid        => $question->ques_uuid,
            ques_value       => "what is your favorite color",
        },
    ],
};

is_deeply( $json, $expected, "got expected JSON format" );

ok( AIR2::InquiryPublisher->unpublish($inq_uuid), 'unpublished' );

ok( !-e "$output_json", "json no longer exists" )
    or diag("Still have $output_json");
ok( !-e "$output_html", "html no longer exists" )
    or diag("Still have $output_html");
