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
use Test::More tests => 62;
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
use Rose::DBx::Object::Indexed::Indexer;
use Search::Tools::XML;
use DateTime;

my $stxml          = Search::Tools::XML->new;
my $debug          = $ENV{PERL_DEBUG} || 0;
my $TEST_USERNAME  = 'ima-test-user';
my $TEST_PROJECT   = 'ima-test-project';
my $TEST_ORG_NAME1 = 'testorg1';
my $TEST_ORG_NAME2 = 'testorg2';
my $TEST_INQ_UUID  = 'testinq12345';
my $TEST_SRS_UUID  = 'testing12345';
my $TEST_OUT_UUID  = 'testout12345';
my $TEST_USER_UUID = 'testuser1234';
my $TEST_RESP_UUID = 'testresp1234';
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

ok( my $tagmaster1
        = AIR2::TagMaster->new( tm_name => 'searchtag1' )->load_or_save(),
    "searchtag1 TagMaster"
);
ok( my $tagmaster2
        = AIR2::TagMaster->new( tm_name => 'searchtag2' )->load_or_save(),
    "searchtag2 TagMaster"
);

ok( my $project = AIR2Test::Project->new(
        prj_name         => $TEST_PROJECT,
        prj_display_name => $TEST_PROJECT,
        annotations      => [ { prjan_value => 'terribly important stuff' } ],
    ),
    "new project"
);
ok( $project->load_or_save, "save project" );

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

ok( $source->add_annotations( [ { srcan_value => 'really trustworthy' } ] ),
    "add annotations" );

ok( $source->add_src_orgs(
        [ { so_org_id => $org1->org_id, so_home_flag => 1 } ]
    ),
    "add orgs to source"
);

ok( $source->add_aliases( [ { sa_first_name => 'source-first-alias' } ] ),
    "add alias to source" );

# use load_or_save in case we aborted on earlier run and left data behind
ok( $source->load_or_save(), "save source" );

ok( my $src_tag = AIR2::Tag->new(
        tag_xid      => $source->src_id,
        tag_ref_type => 'S',
        tag_tm_id    => $tagmaster1->tm_id,
        )->save(),
    "tag source"
);

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
        inq_uuid  => $TEST_INQ_UUID,
        inq_title => 'the color query',
        inquiry_annotations =>
            [ { inqan_value => 'yes we have no bananas' } ],
        inquiry_orgs => [ { iorg_org_id => $org1->org_id, } ],
    ),
    "create test inquiry"
);

ok( $inquiry->add_projects( [$project] ), "add projects to inquiry" );

ok( my $ques = AIR2::Question->new(
        ques_value       => 'what is your favorite color',
        ques_public_flag => 1,
    ),
    "new question"
);
ok( $inquiry->add_questions( [$ques] ), "add question" );
ok( $inquiry->load_or_save, "save inquiry" );

#diag( "src_id==".$source->src_id );
ok( my $srs = AIR2Test::SrcResponseSet->new(
        srs_src_id => $source->src_id,
        srs_inq_id => $inquiry->inq_id,
        srs_date   => time(),
        srs_uuid   => $TEST_SRS_UUID,
    ),
    "new SrcResponseset"
);
ok( my $response = AIR2::SrcResponse->new(
        sr_src_id     => $source->src_id,
        sr_ques_id    => $ques->ques_id,
        sr_orig_value => 'blue is my favorite color',
    ),
    "new response"
);
ok( $response->add_annotations( [ { sran_value => 'great response!' } ] ),
    "add src_response annotation" );
ok( $srs->add_responses( [$response] ), "add responses" );
ok( $srs->add_users(
        [   {   usrs_user_id       => $user->user_id,
                usrs_read_flag     => 1,
                usrs_favorite_flag => 0,
            }
        ]
    ),
    "add users"
);
ok( $srs->load_or_save(), "save SrcResponseSet" );
ok( my $srs_tag = AIR2::Tag->new(
        tag_xid      => $srs->srs_id,
        tag_ref_type => 'R',
        tag_tm_id    => $tagmaster2->tm_id,
        )->save(),
    "tag submission"
);

# add test outcome to source
ok( my $outcome = AIR2Test::Outcome->new(
        out_uuid     => $TEST_OUT_UUID,
        out_headline => 'test the outcome xml',
        out_url      => 'https://nosuchemail.org',
        out_teaser   => 'this is a test test test',
        out_dtim     => time(),
    ),
    "create test outcome"
);
ok( $outcome->add_sources( [$source] ), "add source to outcome" );
ok( $outcome->load_or_save, "save outcome" );

###################################
##           project
###################################

# create XML
ok( $xml = $project->as_xml( { debug => $debug, } ), "project->as_xml" );

#diag( $stxml->tidy($xml) );
like(
    $xml,
    qr(<prj_status>A</prj_status>),
    "xml created, project with default status"
);
like( $xml, qr(<annotations count="1"), "xml has annotations" );

###################################
##           source
###################################

# create XML
$source->forget_related('response_sets');

#diag("response_sets==" . $source->has_related('response_sets'));
ok( $xml = $source->as_xml( { debug => $debug, } ), "source->as_xml" );

#diag( $stxml->tidy($xml) );
like( $xml, qr(<tag>searchtag1</tag>), "got source tag" );
like( $xml, qr(<tag>searchtag2</tag>), "got submission tag" );

like(
    $xml,
    qr(<src_status>E</src_status>),
    "xml created, source with default status"
);
like(
    $xml,
    qr(<preferred_language>en_US</preferred_language>),
    "xml has preferred_language en_US"
);
like(
    $xml,
    qr(<sact_notes>i am the walrus</sact_notes>),
    "xml has activity notes"
);
unlike(
    $xml,
    qr(<sact_actm_id>11</sact_actm_id>),
    "xml profile change activities skipped"
);

like(
    $xml,
    qr(<last_contacted_date>$today</last_contacted_date>),
    "xml has last_contacted_date"
);

like(
    $xml,
    qr(<contacted_date>$today</contacted_date>),
    "xml has contacted_date"
);

like( $xml, qr(<annotations count="1"), "xml has annotations" );

like( $xml, qr(<outcomes count="1"), "xml has outcomes" );

like( $xml, qr(<aliases count="1"), "xml has aliases" );

like(
    $xml,
    qr(<source_name>Harold Bl&#225;h),
    "xml source_name not transliterated"
);

like(
    $xml,
    qr(<source_trans_name>Harold Blah),
    "xml source_trans_name is transliterated!"
);

like(
    $xml,
    qr(<smadd_county>Ramsey</smadd_county>),
    "xml source has smadd_county"
);

###################################
##           inquiry
###################################

# create XML
ok( $xml = $inquiry->as_xml( { debug => $debug, } ), "inquiry->as_xml" );

#diag( $stxml->tidy($xml) );
like(
    $xml,
    qr(<org_names count="\d+">),
    "xml created, inquiry with org_names"
);
like(
    $xml,
    qr(<inqan_value>yes we have no bananas</inqan_value>),
    "inquiry contains annotations"
);

###################################
##     src_response_set (submission)
###################################

# create XML
ok( $xml = $srs->as_xml( { debug => $debug, } ), "srs->as_xml" );

#diag( $stxml->tidy($xml) );
like(
    $xml,
    qr(<prj_uuid_title>\w{12}:(.+)</prj_uuid_title>),
    "xml created, got prj_uuid_title"
);

like( $xml, qr(<user_read>\w{12}</user_read>), "user_read included" );
unlike( $xml, qr(<user_star>\w{12}</user_star>), "user_star excluded" );
like(
    $xml,
    qr(<src_status>Enrolled</src_status>),
    "src_status in submission with full english"
);

my $authz_org_ids = join( ',', @{ $inquiry->get_project_authz() } );
my $owner_org_ids = join( ',', @{ $inquiry->get_owner_org_ids() } );
my $ques_type     = $ques->ques_type;
my $ques_uuid     = $ques->ques_uuid;
my $upd_user_uuid = $response->upd_user->user_uuid;
my $resp_uuid     = $response->sr_uuid;
my $srs_qa_re
    = qr(<qa>$authz_org_ids:$owner_org_ids:$TEST_INQ_UUID:$ques_uuid:\d+:$ques_type:$resp_uuid:.:.:(\d+-\d+-\d+ \d+:\d+:\d+):$upd_user_uuid:blue is my favorite color</qa>);

like( $xml, $srs_qa_re, "srs <qa> tagset" );
