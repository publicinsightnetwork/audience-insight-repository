#!/usr/bin/env perl
###########################################################################
#
#   Copyright 2010 American Public Media Group
#
#   This file is part of AIR2.
#
#   AIR2 is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   AIR2 is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
#
###########################################################################

use strict;
use warnings;
use Test::More tests => 46;
use lib 'tests/search';
use Data::Dump qw( dump );
use AIR2TestUtils;
use AIR2::Config;
use AIR2Test::User;
use AIR2Test::Source;
use AIR2Test::Project;
use AIR2Test::SrcResponseSet;
use AIR2Test::Organization;
use AIR2Test::Inquiry;
use AIR2Test::Outcome;
use AIR2Test::PublicSrcResponseSet;
use Rose::DBx::Object::Indexed::Indexer;
use Search::Tools::XML;
use DateTime;

my $stxml            = Search::Tools::XML->new;
my $debug            = $ENV{PERL_DEBUG} || 0;
my $TEST_USERNAME    = 'ima-test-user';
my $TEST_PROJECT     = 'ima-test-project';
my $TEST_ORG_NAME1   = 'testorg1';
my $TEST_ORG_NAME2   = 'testorg2';
my $TEST_INQ_UUID    = 'testinq12345';
my $TEST_NP_INQ_UUID = 'testinq22345';
my $TEST_SRS_UUID    = 'testing12345';
my $TEST_NP_SRS_UUID = 'testing22345';
my $TEST_OUT_UUID    = 'testout12345';
my $today = DateTime->now->set_time_zone($AIR2::Config::TIMEZONE)->ymd('');

# pk depends on fixtures order
my $prefs = AIR2::SearchUtils::all_preference_values_by_id();
my $en_US;
for ( keys %$prefs ) {
    if ( $prefs->{$_}->ptv_value eq 'en_US' ) {
        $en_US = $prefs->{$_};
    }
}
if ( !$en_US ) {
    die "Can't find preference type for 'en_US'";
}

#dump( $en_US->column_value_pairs );

# reuse this
my $xml;

$Rose::DB::Object::Debug          = $debug;
$Rose::DB::Object::Manager::Debug = $debug;

###################################
##           setup
###################################

ok( my $project = AIR2Test::Project->new(
        prj_name         => $TEST_PROJECT,
        prj_display_name => $TEST_PROJECT,
        annotations      => [ { prjan_value => 'terribly important stuff' } ],
    ),
    "new project"
);
ok( $project->load_or_save, "save project" );

ok( my $project2 = AIR2Test::Project->new(
        prj_name         => $TEST_PROJECT,
        prj_display_name => $TEST_PROJECT,
        annotations =>
            [ { prjan_value => 'even more terribly important stuff' } ],
    ),
    "new project again"
);
ok( $project2->load_or_save, "save project" );

ok( my $org1 = AIR2Test::Organization->new(
        org_default_prj_id => $project->prj_id,
        org_name           => $TEST_ORG_NAME1,
        )->load_or_save(),
    "create test org1"
);
ok( my $org2 = AIR2Test::Organization->new(
        org_default_prj_id => $project->prj_id,
        org_name           => $TEST_ORG_NAME2,
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

ok( my $source = AIR2Test::Source->new(
        src_username   => $TEST_USERNAME,
        src_first_name => "Harold",
        src_last_name  => "Bláh",
    ),
    "new source"
);
ok( $source->add_emails(
        [   {   sem_email        => $TEST_USERNAME . '@nosuchemail.org',
                sem_primary_flag => 1,
            }
        ]
    ),
    "add email address"
);
ok( $source->add_preferences( [ { sp_ptv_id => $en_US->ptv_id } ] ),
    "add en_US preferred language" );

ok( $source->add_mail_addresses(
        [   {   smadd_state  => 'MN',
                smadd_zip    => '55106',
                smadd_county => 'Ramsey',
                smadd_lat    => '150.00',
                smadd_long   => '200.01',
            },
        ]
    ),
    "add mail_addresses"
);

ok( $source->add_activities(
        [   {   project      => $project,
                sact_actm_id => 10,                  # sign up
                sact_desc    => 'test xml',
                sact_notes   => 'i am the walrus',
            },
            {   project      => $project,
                sact_actm_id => 11,              # profile change (ignored)
                sact_desc    => 'test ignore',
                sact_notes => 'you are the eggman',
            },
            {   project      => $project,
                sact_actm_id => 45,              # phone call to
                sact_desc    => 'reach out',
                sact_notes   => 'wirelessly',
            },
        ]
    ),
    "add activities"
);

ok( $source->add_src_orgs(
        [ { so_org_id => $org1->org_id, so_home_flag => 1 } ]
    ),
    "add orgs to source"
);

ok( $source->add_aliases( [ { sa_first_name => 'source-first-alias' } ] ),
    "add alias to source" );

# use load_or_save in case we aborted on earlier run and left data behind
ok( $source->load_or_save(), "save source" );

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

ok( $project2->add_project_orgs(
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
ok( $project2->save(), "write ProjectOrgs" );

ok( my $inquiry = AIR2Test::Inquiry->new(
        inq_uuid  => $TEST_INQ_UUID,
        inq_title => 'the color query',
        inquiry_annotations =>
            [ { inqan_value => 'yes we have no bananas' } ],
        inquiry_orgs    => [ { iorg_org_id => $org1->org_id, } ],
        inq_public_flag => 0,

    ),
    "create test inquiry non public"
);

ok( my $publicInquiry = AIR2Test::Inquiry->new(
        inq_uuid  => $TEST_NP_INQ_UUID,
        inq_title => 'the coloring query',
        inquiry_annotations =>
            [ { inqan_value => 'yes we have several bananas' } ],
        inquiry_orgs    => [ { iorg_org_id => $org1->org_id, } ],
        inq_public_flag => 1,

    ),
    "create test inquiry public"
);

ok( $inquiry->add_projects( [$project] ), "add projects to inquiry" );
ok( $publicInquiry->add_projects( [$project2] ),
    "add projects to public inquiry" );

ok( my $ques
        = AIR2::Question->new( ques_value => 'what is your favorite color' ),
    "new question"
);
ok( my $first_name_question = AIR2::Question->new_from_template('firstname'),
    "first name question"
);
ok( $inquiry->add_questions( [ $ques, $first_name_question ] ),
    "add questions" );
ok( $inquiry->load_or_save, "save inquiry" );

ok( my $quesNonPublic = AIR2::Question->new(
        ques_value       => 'what is your least favorite color',
        ques_public_flag => 0,
    ),
    "new non public question"
);
ok( $publicInquiry->add_questions( [ $quesNonPublic, $first_name_question ] ),
    "add questions non public"
);
ok( $publicInquiry->load_or_save, "save inquiry" );

ok( my $quesPublic = AIR2::Question->new(
        ques_value       => 'what is your least favorite vegetable',
        ques_public_flag => 1,
    ),
    "new public question"
);
ok( $publicInquiry->add_questions( [$quesPublic] ), "add question public" );
ok( $publicInquiry->save, "save inquiry" );

ok( my $publicSrs = AIR2Test::PublicSrcResponseSet->new(
        srs_src_id      => $source->src_id,
        srs_inq_id      => $publicInquiry->inq_id,
        srs_date        => time(),
        srs_uuid        => $TEST_NP_SRS_UUID,
        srs_public_flag => 1,
    ),
    "new SrcResponseset"
);
ok( my $nonPublicResponse = AIR2::SrcResponse->new(
        sr_src_id      => $source->src_id,
        sr_ques_id     => $quesNonPublic->ques_id,
        sr_orig_value  => 'red is my least favorite color',
        sr_public_flag => 1,
    ),
    "new response"
);
ok( $nonPublicResponse->add_annotations(
        [ { sran_value => 'great response!' } ]
    ),
    "add src_response annotation"
);
ok( my $publicResponse = AIR2::SrcResponse->new(
        sr_src_id      => $source->src_id,
        sr_ques_id     => $quesPublic->ques_id,
        sr_orig_value  => 'arugula',
        sr_public_flag => 1,
    ),
    "new response"
);
ok( my $first_name_response = AIR2::SrcResponse->new(
        sr_src_id     => $source->src_id,
        sr_ques_id    => $first_name_question->ques_id,
        sr_orig_value => 'AdHoc',
        sr_public_flag => 1,    # in practice this should not happen
    ),
    "new first name response"
);
ok( $publicSrs->add_responses(
        [ $publicResponse, $nonPublicResponse, $first_name_response ]
    ),
    "add responses"
);
ok( $publicSrs->add_users(
        [   {   usrs_user_id       => $user->user_id,
                usrs_read_flag     => 1,
                usrs_favorite_flag => 0,
            }
        ]
    ),
    "add users"
);
ok( $publicSrs->load_or_save(), "save PublicSrcResponseSet" );

########################################
##     src_response_set (submission)
########################################

# create XML
ok( $xml = $publicSrs->as_xml( { debug => $debug, } ), "srs->as_xml" );

# tidy it just to make errors easier to see
my $tidy_xml = $stxml->tidy($xml);

like(
    $tidy_xml,
    qr(<prj_uuid_title>\w{12}:(.+)</prj_uuid_title>)si,
    "xml created, got prj_uuid_title"
);

like(
    $tidy_xml,
    qr(<src_first_name>AdHoc</src_first_name>),
    "XML uses first_name response, not source profile"
);

my $ques_type  = $quesPublic->ques_type;
my $ques_seq   = $quesPublic->ques_dis_seq;
my $ques_uuid  = $quesPublic->ques_uuid;
my $ques_value = $quesPublic->ques_value;
my $qa_set
    = join( '|', $ques_uuid, $ques_type, $ques_seq, $ques_value, 'arugula' );

my $srs_qa_re = qr(<qa>$qa_set</qa>)s;

like( $tidy_xml, $srs_qa_re, "srs <qa> tagset" );

