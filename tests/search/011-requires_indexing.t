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
use Test::More tests => 43;
use lib 'tests/search';
use Data::Dump qw( dump );
use AIR2TestUtils;
use AIR2::Config;
use AIR2Test::Source;
use AIR2Test::SrcActivity;
use AIR2Test::Project;
use AIR2Test::SrcResponseSet;
use AIR2Test::PublicSrcResponseSet;
use AIR2Test::Inquiry;
use AIR2Test::Outcome;

my $debug         = $ENV{PERL_DEBUG} || 0;
my $TEST_USERNAME = 'ima-test-user';
my $TEST_PROJECT  = 'ima-test-project';
my $TEST_INQUIRY  = 'ima-test-inquiry';
my $TEST_SRS      = 'ima-test-srs';
my $TEST_PUB_SRS  = 'ima-public-test-srs';
my $TEST_OUT_UUID = 'testout12345';

$Rose::DB::Object::Debug          = $debug;
$Rose::DB::Object::Manager::Debug = $debug;

###################################
##           source
###################################

ok( my $source = AIR2Test::Source->new(
        src_username => $TEST_USERNAME,
        debug        => $debug
    ),
    "new source"
);
ok( $source->add_emails(
        [ { sem_email => $TEST_USERNAME . '@nosuchemail.org' } ]
    ),
    "add email address"
);

# use load_or_insert in case we aborted on earlier run and left data behind
ok( $source->load_or_insert(), "save source" );

# make sure our upd_dtim is current
ok( $source->src_upd_dtim( time() ), "set src_upd_dtim" );
ok( $source->save(),                 "save source with upd_dtim" );

ok( my $src_ids = $source->requires_indexing_ids( $source->src_upd_dtim() ),
    "get requires_indexing_id" );
is( scalar @$src_ids, 1, "one source found for indexing" );

SKIP: {

    my $total
        = AIR2::SrcActivity->fetch_count( query => [ '!sact_id' => 0 ] );
    skip "No SrcActivity found in db", 2 if !$total;

    # touch a random activity and make sure it gets noticed
    my $rand_sact = AIR2::SrcActivity->fetch_all_iterator( limit => 1 )->next;
    $rand_sact->sact_upd_dtim( time() );
    $rand_sact->save();

    ok( $src_ids = $source->requires_indexing_ids( $source->src_upd_dtim() ),
        "get requires_indexing_id"
    );
    is( scalar @$src_ids, 2, "two found for indexing" );
}

sleep(1);    # make sure we do not get false positives for upd_dtim later

###################################
##           project
###################################

ok( my $project = AIR2Test::Project->new(
        prj_name         => $TEST_PROJECT,
        prj_display_name => $TEST_PROJECT,
    ),
    "new project"
);
ok( $project->load_or_insert, "save project" );
ok( my $prj_ids
        = AIR2Test::Project->requires_indexing_ids( $project->prj_upd_dtim ),
    "get requires_indexing_ids for Project"
);

#diag( dump( $prj_ids ));

###################################
##       src_response_set
###################################

ok( my $inq = AIR2Test::Inquiry->new( inq_title => $TEST_INQUIRY, ),
    "new inquiry" );
ok( $inq->load_or_insert, "save inquiry" );
ok( my $srs = AIR2Test::SrcResponseSet->new(
        srs_src_id => $source->src_id,
        srs_inq_id => $inq->inq_id,
        srs_xuuid  => $TEST_SRS,
        srs_date   => time(),
    ),
    "new srs"
);
ok( $srs->load_or_insert, "save srs" );
ok( my $srs_ids
        = AIR2Test::SrcResponseSet->requires_indexing_ids(
        $srs->srs_upd_dtim ),
    "get required_indexing_ids for SRS"
);

#diag( dump $srs_ids );
is( $srs_ids->[0], $srs->srs_id, "got self as srs to index" );

sleep(1);    # no false positives

#$Rose::DB::Object::Debug = 1;
#$Rose::DB::Object::Manager::Debug = 1;

# add a tag to the submission, make sure source sees that as stale
ok( my $srs_tag = AIR2::Tag->new(
        tag_xid      => $srs->srs_id,
        tag_ref_type => $srs->tag_ref_type,
        tag_tm_id    => 1,                    # random, doesn't matter
    ),
    "new srs_tag"
);
ok( $srs_tag->save(), "save srs_tag" );
ok( $src_ids = $source->requires_indexing_ids( $srs_tag->tag_upd_dtim() ),
    "get requires_indexing_id" );
is( scalar @$src_ids,
    1, "one source found for indexing after adding submission tag" );

#$Rose::DB::Object::Manager::Debug = 0;
#$Rose::DB::Object::Debug = 0;

###################################
##  Public src_response_set
###################################

# requires_indexing_ids: Verifying that all response sets all contain 
# at least one public response.

ok( my $publicInquiry = AIR2Test::Inquiry->new(
        inq_title       => $TEST_INQUIRY,
        inq_public_flag => 1,
    ),
    "new inquiry"
);
ok( $publicInquiry->load_or_insert, "save inquiry" );

ok( my $quesNonPublic = AIR2::Question->new(
        ques_value       => 'what is your least favorite color',
        ques_public_flag => 0,
    ),
    "new non public question"
);
ok( $publicInquiry->add_questions( [$quesNonPublic] ),
    "add question non public" );
ok( $publicInquiry->load_or_save, "save inquiry" );

ok( my $quesPublic = AIR2::Question->new(
        ques_value       => 'what is your least favorite vegetable',
        ques_public_flag => 1,
    ),
    "new public question"
);
ok( $publicInquiry->add_questions( [$quesPublic] ), "add question public" );
ok( $publicInquiry->save, "save inquiry" );

ok( my $publicSrs = AIR2Test::SrcResponseSet->new(
        srs_src_id      => $source->src_id,
        srs_inq_id      => $publicInquiry->inq_id,
        srs_xuuid       => $TEST_PUB_SRS,
        srs_date        => time(),
        srs_public_flag => 1,
    ),
    "new srs"
);

ok( my $nonPublicResponse = AIR2::SrcResponse->new(
        sr_src_id      => $source->src_id,
        sr_ques_id     => $quesNonPublic->ques_id,
        sr_orig_value  => 'red is my least favorite color',
        sr_public_flag => 1,
    ),
    "new response"
);

ok( my $publicResponse = AIR2::SrcResponse->new(
        sr_src_id      => $source->src_id,
        sr_ques_id     => $quesPublic->ques_id,
        sr_orig_value  => 'arugula',
        sr_public_flag => 1,
    ),
    "new response"
);

ok( $publicSrs->add_responses( [ $publicResponse, $nonPublicResponse ] ),
    "add responses" );
ok( $publicSrs->load_or_save(), "save SrcResponseSet" );
is( $publicSrs->is_public, 1, "Correct number of public responses" );

ok( my $public_srs_ids
        = AIR2Test::PublicSrcResponseSet->requires_indexing_ids(
        $publicSrs->srs_upd_dtim
        ),
    "get required_indexing_ids for SRS"
);

#diag( "public " . dump $public_srs_ids );
#diag( "non-public " . dump $srs_ids );

is( $public_srs_ids->[0], $publicSrs->srs_id, "got self as srs to index" );

###################################
##           outcome
###################################

ok( my $outcome = AIR2Test::Outcome->new(
        out_uuid     => $TEST_OUT_UUID,
        out_headline => 'test the outcome xml',
        out_url      => 'https://nosuchemail.org',
        out_teaser   => 'this is a test test test',
        out_dtim     => time(),
    ),
    "new outcome"
);
ok( $outcome->add_sources( [$source] ), "add source to outcome" );
ok( $outcome->load_or_save, "save outcome" );

# set the src_outcome date into the future
my $future = $source->src_upd_dtim->add( hours => 1 );
my $sout = $outcome->src_outcomes->[0];
$sout->set_admin_update(1);
$sout->sout_upd_dtim($future);
$sout->save();

# look into the future, so we miss the existing source
ok( $src_ids = $source->requires_indexing_ids($future), "get req_idxing" );
is( scalar @$src_ids, 1, "1 found for indexing" );
