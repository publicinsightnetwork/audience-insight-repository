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
use Test::More tests => 108;
use lib 'tests/search';
use Data::Dump qw( dump );
use AIR2TestUtils;
use AIR2::Config;
use AIR2Test::Source;
use AIR2Test::Project;
use AIR2Test::SrcResponseSet;
use AIR2Test::Organization;
use AIR2Test::Inquiry;
use AIR2Test::User;
use Rose::DBx::Object::Indexed::Indexer;
use Search::Tools::XML;
use JSON;
use URI::Query;
use Plack::Test;

my $stxml          = Search::Tools::XML->new;
my $debug          = $ENV{PERL_DEBUG} || 0;
my $TEST_ORG_NAME1 = 'testorg1';
my $TEST_ORG_NAME2 = 'testorg2';
my $TEST_USERNAME  = 'ima-test-user';
my $TEST_PROJECT   = 'ima-test-project';
my $TEST_INQ_UUID  = 'testinq12345';
my $TEST_INQ_UUID2 = 'testinq67890';
my $TMP_DIR        = AIR2::Config::get_tmp_dir->subdir('search');
$AIR2::Config::SEARCH_ROOT = $TMP_DIR;

$Rose::DB::Object::Debug          = $debug;
$Rose::DB::Object::Manager::Debug = $debug;

$TMP_DIR->mkpath($debug);
my $xml_dir = $TMP_DIR->subdir('xml/sources');
$xml_dir->mkpath($debug);
my $index_dir = $TMP_DIR->subdir('index/sources');
$index_dir->mkpath($debug);

##################################################################################
## set up test data
##################################################################################

ok( my $project = AIR2Test::Project->new(
        prj_name         => $TEST_PROJECT,
        prj_display_name => $TEST_PROJECT,
    ),
    "new project"
);

ok( my $project2 = AIR2Test::Project->new(
        prj_name         => $TEST_PROJECT . 2,
        prj_display_name => $TEST_PROJECT . 2,
    ),
    "new project2"
);

ok( $project->load_or_save,  "save project" );
ok( $project2->load_or_save, "save project2" );

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
ok( my $org3 = AIR2Test::Organization->new(
        org_default_prj_id => $project->prj_id,
        org_name           => $TEST_ORG_NAME2 . '-child',
        org_parent_id      => $org2->org_id,
        )->load_or_save(),
    "create test org3 child of org2"
);

#diag("org1 id = " . $org1->org_id);
#diag("org2 id = " . $org2->org_id);

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

ok( $project2->add_project_orgs(
        [   {   porg_org_id          => $org2->org_id,
                porg_contact_user_id => $user->user_id,
            }
        ]
    ),
    "add orgs to project2"
);
ok( $project2->save(), "write ProjectOrgs2" );

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
ok( $source->add_annotations( [ { srcan_value => 'seeme annotation' } ] ),
    "add source annotations" );
ok( $source->load_or_save(), "save source" );

ok( my $source2 = AIR2Test::Source->new(
        src_username  => $TEST_USERNAME . '2',
        src_post_name => 'esquire',
    ),
    "new source"
);
ok( $source2->add_emails(
        [ { sem_email => $TEST_USERNAME . '@really-nosuchemail.org' } ]
    ),
    "add email address"
);
ok( $source2->add_organizations( [$org2] ), "add orgs to source" );
ok( $source2->add_annotations( [ { srcan_value => 'seeme annotation2' } ] ),
    "add source annotations" );
ok( $source2->load_or_save(), "save source2" );

ok( my $source3 = AIR2Test::Source->new(
        src_username  => $TEST_USERNAME . '3',
        src_post_name => 'esquire',
    ),
    "new source"
);
ok( $source3->add_emails(
        [ { sem_email => $TEST_USERNAME . '@3really-nosuchemail.org' } ]
    ),
    "add email address"
);
ok( $source3->add_src_orgs(
        [   { so_org_id => $org1->org_id, so_status => 'A' },
            { so_org_id => $org2->org_id, so_status => 'F' },
            { so_org_id => $org3->org_id, so_status => 'A' },
        ]
    ),
    "add orgs, one opt-in one opt-out one opt-in-to-child-of-opt-out"
);
ok( $source3->load_or_save(), "save source3" );

# must do this explicitly since orgs are cached at startup
AIR2::SrcOrgCache::refresh_cache($source);
AIR2::SrcOrgCache::refresh_cache($source2);
AIR2::SrcOrgCache::refresh_cache($source3);

####################
## set up queries
ok( my $inq = AIR2Test::Inquiry->new(
        inq_uuid         => $TEST_INQ_UUID,
        inq_title        => 'the color query',
        inq_publish_dtim => '2012-01-01',
    ),
    "create test inquiry"
);

ok( $inq->add_projects( [ $project, $project2 ] ),
    "add projects to inquiry" );

ok( my $inq2 = AIR2Test::Inquiry->new(
        inq_uuid         => $TEST_INQ_UUID2,
        inq_title        => 'the shape query',
        inq_publish_dtim => '2012-02-01',
    ),
    "create test inquiry2"
);

ok( $inq2->add_projects( [$project2] ), "add projects to inquiry2" );

ok( my $ques
        = AIR2::Question->new( ques_value => 'what is your favorite color' ),
    "new question"
);
ok( $inq->add_questions( [$ques] ), "add question" );
ok( $inq->load_or_save, "save inquiry" );

ok( my $ques2
        = AIR2::Question->new( ques_value => 'what is your favorite shape' ),
    "new question2"
);
ok( $inq2->add_questions( [$ques2] ), "add question2" );
ok( $inq2->load_or_save, "save inquiry2" );

##############################
## set up responses
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
        sr_orig_value => 'blue is my favorite color',
    ),
    "new response"
);
ok( $srs->add_responses( [$response] ), "add responses" );
ok( $srs->save(), "save SrcResponseSet" );

ok( my $srs2 = AIR2Test::SrcResponseSet->new(
        srs_src_id => $source2->src_id,
        srs_inq_id => $inq->inq_id,
        srs_date   => time(),
    ),
    "new SrcResponseset"
);
ok( my $response2 = AIR2::SrcResponse->new(
        sr_src_id     => $source2->src_id,
        sr_ques_id    => $ques->ques_id,
        sr_orig_value => 'red is my favorite color',
    ),
    "new response"
);
ok( $srs2->add_responses( [$response2] ), "add responses" );
ok( $srs2->save(), "save SrcResponseSet" );

ok( my $srs3 = AIR2Test::SrcResponseSet->new(
        srs_src_id => $source->src_id,
        srs_inq_id => $inq2->inq_id,
        srs_date   => time(),
    ),
    "new SrcResponseset"
);
ok( my $response3 = AIR2::SrcResponse->new(
        sr_src_id     => $source->src_id,
        sr_ques_id    => $ques2->ques_id,
        sr_orig_value => 'circle is my favorite shape',
    ),
    "new response"
);
ok( $srs3->add_responses( [$response3] ), "add response3" );
ok( $srs3->save(), "save SrcResponseSet 2" );

#################################
## responses XML

ok( my $resp_xml = $srs->as_xml(
        { debug => $debug, base_dir => $TMP_DIR->subdir('xml/responses') }
    ),
    "get resp_xml"
);
ok( my $resp_xml2 = $srs2->as_xml(
        { debug => $debug, base_dir => $TMP_DIR->subdir('xml/responses') }
    ),
    "get resp_xml2"
);
ok( my $resp_xml3 = $srs3->as_xml(
        { debug => $debug, base_dir => $TMP_DIR->subdir('xml/responses') }
    ),
    "get resp_xml3"
);

#diag("write xml for " . $srs->srs_id);
ok( AIR2::SearchUtils::write_xml_file(
        pk     => $srs->srs_id,
        base   => $TMP_DIR->subdir('xml/responses'),
        xml    => $resp_xml,
        pretty => $debug,
    ),
    "write resp_xml"
);

#diag("write xml for " . $srs2->srs_id);
ok( AIR2::SearchUtils::write_xml_file(
        pk     => $srs2->srs_id,
        base   => $TMP_DIR->subdir('xml/responses'),
        xml    => $resp_xml2,
        pretty => $debug,
    ),
    "write resp_xml2"
);

#diag("write xml for " . $srs3->srs_id);
ok( AIR2::SearchUtils::write_xml_file(
        pk     => $srs3->srs_id,
        base   => $TMP_DIR->subdir('xml/responses'),
        xml    => $resp_xml3,
        pretty => $debug,
    ),
    "write resp_xml3"
);

#############################
## sources xml
ok( my $xml = $source->as_xml(
        {   debug    => $debug,
            base_dir => $xml_dir,
        }
    ),
    "source->as_xml"
);
ok( AIR2::SearchUtils::write_xml_file(
        pk     => $source->src_id,
        base   => $xml_dir,
        xml    => $xml,
        pretty => $debug,
        debug  => $debug,
    ),
    "write xml file"
);

ok( my $xml2 = $source2->as_xml(
        {   debug    => $debug,
            base_dir => $xml_dir,
        }
    ),
    "source2->as_xml"
);
ok( AIR2::SearchUtils::write_xml_file(
        pk     => $source2->src_id,
        base   => $xml_dir,
        xml    => $xml2,
        pretty => $debug,
        debug  => $debug,
    ),
    "write xml file"
);

ok( AIR2::SearchUtils::write_xml_file(
        pk   => $source3->src_id,
        base => $xml_dir,
        xml  => $source3->as_xml( { debug => $debug, base_dir => $xml_dir } ),
        pretty => $debug,
        debug  => $debug,
    ),
    "write source3 xml file"
);

#############################
## inquiry xml
ok( my $inqxml = $inq->as_xml(
        {   debug    => $debug,
            base_dir => $TMP_DIR->subdir('xml/inquiries')
        }
    ),
    "make inqxml"
);
ok( AIR2::SearchUtils::write_xml_file(
        pk     => $inq->inq_id,
        base   => $TMP_DIR->subdir('xml/inquiries'),
        xml    => $inqxml,
        pretty => $debug,
        debug  => $debug,
    ),
    "write inqxml file"
);
ok( my $inqxml2 = $inq2->as_xml(
        {   debug    => $debug,
            base_dir => $TMP_DIR->subdir('xml/inquiries')
        }
    ),
    "make inqxml2"
);
ok( AIR2::SearchUtils::write_xml_file(
        pk     => $inq2->inq_id,
        base   => $TMP_DIR->subdir('xml/inquiries'),
        xml    => $inqxml2,
        pretty => $debug,
        debug  => $debug,
    ),
    "write inqxml2 file"
);

$debug and diag(`tree $TMP_DIR`);

#########################
## create indexes
is( AIR2TestUtils::create_index(
        invindex => $index_dir,
        config =>
            AIR2::Config->get_app_root->file('etc/search/sources.config'),
        input => $xml_dir,
        debug => $debug,
    ),
    3,
    "create tmp source index with 3 docs in it"
);

is( AIR2TestUtils::create_index(
        invindex => $TMP_DIR->subdir('index/inquiries'),
        config =>
            AIR2::Config->get_app_root->file('etc/search/inquiries.config'),
        input => $TMP_DIR->subdir('xml/inquiries'),
        debug => $debug,
    ),
    2,
    "create tmp inquiries index with 2 docs in it"
);

is( AIR2TestUtils::create_index(
        invindex => $TMP_DIR->subdir('index/responses'),
        config =>
            AIR2::Config->get_app_root->file('etc/search/responses.config'),
        input => $TMP_DIR->subdir('xml/responses'),
        debug => $debug,
    ),
    3,
    "create tmp responses index with 3 docs in it"
);

##########################################################################################
## authz tests
##########################################################################################

# defer loading this till after test is compiled so that TMP_DIR is
# correctly recognized by AI2::Config and all the Search::Servers
require AIR2::Search::MasterServer;

ok( my $at = AIR2TestUtils::new_auth_tkt(), "get auth tkt object" );
my $org2_authz = encode_json(
    {   user => { type => "A" },
        authz => AIR2::SearchUtils::pack_authz( { $org2->org_id => 1 } )
    }
);
my $org2_tkt = $at->ticket(
    uid     => 'nosuchuser',
    ip_addr => '0.0.0.0',
    data    => $org2_authz
);

my $skip = {
    projects                 => 1,
    outcomes                 => 1,
    'sources'                => 1,
    'active-sources'         => 1,
    'primary-sources'        => 1,
    'fuzzy-sources'          => 1,
    'fuzzy-active-sources'   => 1,
    'fuzzy-primary-sources'  => 1,
    'fuzzy-responses'        => 1,
    'responses'              => 1,
    'active-responses'       => 1,
    'fuzzy-active-responses' => 1,
    'public-responses'       => 1,
};

test_psgi(
    app    => AIR2::Search::MasterServer->app( { skip => $skip } ),
    client => sub {
        my $callback = shift;
        my $query    = URI::Query->new(
            {   q        => "",                   # empty means everything
                air2_tkt => $org2_tkt,
                s        => 'inq_publish_date',
                d        => 'DESC',
            }
        );

        my $count = 0;

        while ( $count++ < 10 ) {
            my $req
                = HTTP::Request->new( GET => "/inquiries/search?" . $query );
            my $resp = $callback->($req);

            ok( my $json = decode_json( $resp->content ),
                "json decode body of response" );

            is( $json->{results}->[0]->{inq_publish_date},
                '20120201', "publish_date DESC" );
        }

    },
);

test_psgi(
    app    => AIR2::Search::MasterServer->app( { skip => $skip } ),
    client => sub {
        my $callback = shift;
        my $query    = URI::Query->new(
            {   q        => "",                   # empty means everything
                air2_tkt => $org2_tkt,
                s        => 'inq_publish_date',
                d        => 'asc',
            }
        );

        my $count = 0;

        while ( $count++ < 10 ) {
            my $req
                = HTTP::Request->new( GET => "/inquiries/search?" . $query );
            my $resp = $callback->($req);

            ok( my $json = decode_json( $resp->content ),
                "json decode body of response" );

            is( $json->{results}->[0]->{inq_publish_date},
                '20120101', "publish_date ASC" );
        }

    },
);

#################################################################
# clean up unless debug is on
#################################################################
END {
    if ( !$debug ) {
        $TMP_DIR->rmtree;
    }
}
