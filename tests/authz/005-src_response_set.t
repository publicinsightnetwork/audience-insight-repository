#!/usr/bin/env php
<?php
/**************************************************************************
 *
 *   Copyright 2010 American Public Media Group
 *
 *   This file is part of AIR2.
 *
 *   AIR2 is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   AIR2 is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
 *
 *************************************************************************/

require_once 'app/init.php';
require_once APPPATH.'../tests/Test.php';
require_once APPPATH.'../tests/AirHttpTest.php';
require_once APPPATH.'../tests/AirTestUtils.php';
require_once APPPATH.'../tests/models/TestUser.php';
require_once APPPATH.'../tests/models/TestSource.php';
require_once APPPATH.'../tests/models/TestOrganization.php';
require_once APPPATH.'../tests/models/TestProject.php';
require_once APPPATH.'../tests/models/TestInquiry.php';

plan(67);

AIR2_DBManager::init();

// create project and inquiry
$project = new TestProject();
$project->save();
$inquiry = new TestInquiry();
$inquiry->add_projects(array($project));
$inquiry->Question[0]->ques_value = 'what is the air-speed velocity of a swallow?';
$inquiry->save();

// create source and response
$source = new TestSource();
$source->save();
$srs = new SrcResponseSet();
$srs->srs_date = air2_date();
$srs->srs_src_id = $source->src_id;
$srs->srs_inq_id = $inquiry->inq_id;
$srs->SrcResponse[0]->sr_src_id = $source->src_id;
$srs->SrcResponse[0]->sr_ques_id = $inquiry->Question[0]->ques_id;
$srs->SrcResponse[0]->sr_orig_value = 'european or african swallow?';
$srs->save();

// create test users
$usr1_reader = new TestUser();
$usr1_reader->save();
$usr2_reader = new TestUser();
$usr2_reader->save();
$usr3_reader = new TestUser();
$usr3_reader->save();
$usr4_reader = new TestUser();
$usr4_reader->save();
$usr5_rdplus = new TestUser();
$usr5_rdplus->save();

// create test organizations
$org1_inprj_optin = new TestOrganization();
$org1_inprj_optin->add_users(array($usr1_reader));
$org1_inprj_optin->add_users(array($usr5_rdplus), 6);
$org1_inprj_optin->save();
$org2_noprj_optin = new TestOrganization();
$org2_noprj_optin->add_users(array($usr2_reader));
$org2_noprj_optin->save();
$org3_inprj_optout = new TestOrganization();
$org3_inprj_optout->add_users(array($usr3_reader));
$org3_inprj_optout->save();
$org4_noprj_optout = new TestOrganization();
$org4_noprj_optout->add_users(array($usr4_reader));
$org4_noprj_optout->save();

// child/parent/sibling users
$parent_usr = new TestUser();
$parent_usr->save();
$child_usr = new TestUser();
$child_usr->save();
$sibling_usr = new TestUser();
$sibling_usr->save();

// child/parent/sibling orgs
$parent = new TestOrganization();
$parent->add_users(array($parent_usr)); //READER
$parent->save();
$org1_inprj_optin->org_parent_id = $parent->org_id;
$org1_inprj_optin->save();
$child = new TestOrganization();
$child->org_parent_id = $org1_inprj_optin->org_id;
$child->add_users(array($child_usr)); //READER
$child->save();
$sibling = new TestOrganization();
$sibling->org_parent_id = $parent->org_id;
$sibling->add_users(array($sibling_usr)); //READER
$sibling->save();

// join projects/orgs
$project->add_orgs(array($org1_inprj_optin, $org3_inprj_optout));
$project->save();
$source->add_orgs(array($org1_inprj_optin, $org2_noprj_optin));
$source->add_orgs(array($org3_inprj_optout, $org4_noprj_optout), SrcOrg::$STATUS_OPTED_OUT);
$source->save();

// labels
$str1 = 'user-inprj and src-optin';
$str2 = 'user-noprj and src-optin';
$str3 = 'user-inprj and src-optout';
$str4 = 'user-noprj and src-optout';


/**********************
 * Test record authz
 */
is( $srs->user_may_read($usr1_reader),    AIR2_AUTHZ_IS_ORG,    "$str1 - read srs" );
is( $srs->user_may_write($usr1_reader),   AIR2_AUTHZ_IS_DENIED, "$str1 - no write srs" );
is( $source->user_may_read($usr1_reader), AIR2_AUTHZ_IS_ORG,    "$str1 - read source" );

is( $srs->user_may_read($usr2_reader),    AIR2_AUTHZ_IS_DENIED, "$str2 - no read srs" );
is( $source->user_may_read($usr2_reader), AIR2_AUTHZ_IS_ORG,    "$str2 - read source" );

is( $srs->user_may_read($usr3_reader),    AIR2_AUTHZ_IS_ORG,    "$str3 - read srs" );
is( $srs->user_may_write($usr3_reader),   AIR2_AUTHZ_IS_DENIED, "$str3 - no write srs" );
is( $source->user_may_read($usr3_reader), AIR2_AUTHZ_IS_ORG,    "$str3 - no read source" );

is( $srs->user_may_read($usr4_reader),    AIR2_AUTHZ_IS_DENIED, "$str4 - no read srs" );
is( $source->user_may_read($usr4_reader), AIR2_AUTHZ_IS_ORG,    "$str4 - no read source" );

is( $srs->user_may_read($usr5_rdplus),     AIR2_AUTHZ_IS_ORG,    "$str1 - rdplus - read srs" );
is( $srs->user_may_write($usr5_rdplus),    AIR2_AUTHZ_IS_DENIED, "$str1 - rdplus - no write srs" );
is( $source->user_may_write($usr5_rdplus), AIR2_AUTHZ_IS_ORG,    "$str1 - rdplus - write source" );

/**********************
 * Test MANUAL_ENTRY-type submissions (need at least 1 question created for
 * the activity-logging that happens around MANUAL_ENTRY SrcResponseSets)
 */
$inq2 = new TestInquiry();
$inq2->add_projects(array($project));
$inq2->save();
$inq2->inq_type = Inquiry::$TYPE_MANUAL_ENTRY;
$inq2->Question[0]->ques_value = 'ques1';
$inq2->save();
$srs2 = new SrcResponseSet();
$srs2->srs_date = air2_date();
$srs2->srs_type = SrcResponseSet::$TYPE_MANUAL_ENTRY;
$srs2->srs_src_id = $source->src_id;
$srs2->srs_inq_id = $inq2->inq_id;
$srs2->SrcResponse[0]->sr_src_id = $source->src_id;
$srs2->SrcResponse[0]->sr_ques_id = $inq2->Question[0]->ques_id;

is( $srs2->user_may_read($usr1_reader),   AIR2_AUTHZ_IS_ORG,    "$str1 - read manual srs" );
is( $srs2->user_may_write($usr1_reader),  AIR2_AUTHZ_IS_DENIED, "$str1 - no write manual srs" );
is( $srs2->user_may_manage($usr1_reader), AIR2_AUTHZ_IS_DENIED, "$str1 - no manage manual srs" );

is( $srs2->user_may_read($usr5_rdplus),   AIR2_AUTHZ_IS_ORG,    "$str1 - readerplus - read manual srs" );
is( $srs2->user_may_write($usr5_rdplus),  AIR2_AUTHZ_IS_ORG,    "$str1 - readerplus - write manual srs" );
is( $srs2->user_may_manage($usr5_rdplus), AIR2_AUTHZ_IS_DENIED, "$str1 - readerplus - no manage manual srs" );

$srs2->save();
is( $srs2->user_may_read($usr1_reader),   AIR2_AUTHZ_IS_ORG,    "$str1 - read saved manual srs" );
is( $srs2->user_may_write($usr1_reader),  AIR2_AUTHZ_IS_DENIED, "$str1 - no write saved manual srs" );
is( $srs2->user_may_manage($usr1_reader), AIR2_AUTHZ_IS_DENIED, "$str1 - no manage saved manual srs" );

is( $srs2->user_may_read($usr5_rdplus),   AIR2_AUTHZ_IS_ORG,    "$str1 - readerplus - read manual srs" );
is( $srs2->user_may_write($usr5_rdplus),  AIR2_AUTHZ_IS_DENIED, "$str1 - readerplus - no write manual srs" );
is( $srs2->user_may_manage($usr5_rdplus), AIR2_AUTHZ_IS_DENIED, "$str1 - readerplus - no manage manual srs" );
$srs2->delete();

/**********************
 * Test query authz
 */
$q = AIR2_Query::create()->from('SrcResponseSet');
SrcResponseSet::query_may_read($q, $usr1_reader);
is( $q->count(), 1, "$str1 - query srs");

$q = AIR2_Query::create()->from('SrcResponseSet');
SrcResponseSet::query_may_read($q, $usr2_reader);
is( $q->count(), 0, "$str2 - no query srs");

$q = AIR2_Query::create()->from('SrcResponseSet');
SrcResponseSet::query_may_read($q, $usr3_reader);
is( $q->count(), 1, "$str3 - query srs");

$q = AIR2_Query::create()->from('SrcResponseSet');
SrcResponseSet::query_may_read($q, $usr4_reader);
is( $q->count(), 0, "$str4 - no query srs");

/**********************
 * Test parent/child/sibling record authz
 */
is( $srs->user_may_read($parent_usr),    AIR2_AUTHZ_IS_ORG, "parent($str1) - read srs" );
is( $source->user_may_read($parent_usr), AIR2_AUTHZ_IS_ORG, "parent($str1) - read source" );

is( $srs->user_may_read($child_usr),    AIR2_AUTHZ_IS_ORG, "child($str1) - read srs" );
is( $source->user_may_read($child_usr), AIR2_AUTHZ_IS_ORG, "child($str1) - read source" );

is( $srs->user_may_read($sibling_usr),    AIR2_AUTHZ_IS_DENIED, "sibling($str1) - no read srs" );
is( $source->user_may_read($sibling_usr), AIR2_AUTHZ_IS_DENIED, "sibling($str1) - no read source" );

/**********************
 * Test parent/child/sibling query authz
 */
$q = AIR2_Query::create()->from('SrcResponseSet');
SrcResponseSet::query_may_read($q, $parent_usr);
is( $q->count(), 1, "parent($str1) - query srs");

$q = AIR2_Query::create()->from('SrcResponseSet');
SrcResponseSet::query_may_read($q, $child_usr);
is( $q->count(), 1, "child($str1) - query srs");

$q = AIR2_Query::create()->from('SrcResponseSet');
SrcResponseSet::query_may_read($q, $sibling_usr);
is( $q->count(), 0, "sibling($str3) - no query srs");

/**********************
 * Test SrsAnnotations (as readers)
 */
$srsan = new SrsAnnotation();
$srsan->srsan_srs_id = $srs->srs_id;
$sran = new SrAnnotation();
$sran->sran_sr_id = $srs->SrcResponse[0]->sr_id;

is( $srsan->user_may_read($usr1_reader),  AIR2_AUTHZ_IS_ORG,    "$str1 - read srsan" );
is( $srsan->user_may_write($usr1_reader), AIR2_AUTHZ_IS_NEW,    "$str1 - create srsan" );
is( $srsan->user_may_read($usr2_reader),  AIR2_AUTHZ_IS_DENIED, "$str2 - no read srsan" );
is( $srsan->user_may_read($usr3_reader),  AIR2_AUTHZ_IS_ORG,    "$str3 - read srsan" );
is( $srsan->user_may_write($usr3_reader), AIR2_AUTHZ_IS_NEW,    "$str3 - create srsan" );

is( $sran->user_may_read($usr1_reader),  AIR2_AUTHZ_IS_ORG,    "$str1 - read sran" );
is( $sran->user_may_write($usr1_reader), AIR2_AUTHZ_IS_NEW,    "$str1 - create sran" );
is( $sran->user_may_read($usr2_reader),  AIR2_AUTHZ_IS_DENIED, "$str2 - no read sran" );
is( $sran->user_may_read($usr3_reader),  AIR2_AUTHZ_IS_ORG,    "$str3 - read sran" );
is( $sran->user_may_write($usr3_reader), AIR2_AUTHZ_IS_NEW,    "$str3 - create sran" );

// owned annotations
$srsan->srsan_cre_user = $usr1_reader->user_id;
$srsan->save();
$sran->sran_cre_user = $usr1_reader->user_id;
$sran->save();

is( $srsan->user_may_read($usr1_reader),  AIR2_AUTHZ_IS_ORG,    "$str1 - read srsan" );
is( $srsan->user_may_write($usr1_reader), AIR2_AUTHZ_IS_OWNER,  "$str1 - update srsan" );
is( $srsan->user_may_read($usr2_reader),  AIR2_AUTHZ_IS_DENIED, "$str2 - no read srsan" );
is( $srsan->user_may_read($usr3_reader),  AIR2_AUTHZ_IS_ORG,    "$str3 - read srsan" );
is( $srsan->user_may_write($usr3_reader), AIR2_AUTHZ_IS_DENIED, "$str3 - no update srsan" );

is( $sran->user_may_read($usr1_reader),  AIR2_AUTHZ_IS_ORG,    "$str1 - read sran" );
is( $sran->user_may_write($usr1_reader), AIR2_AUTHZ_IS_OWNER,  "$str1 - update sran" );
is( $sran->user_may_read($usr2_reader),  AIR2_AUTHZ_IS_DENIED, "$str2 - no read sran" );
is( $sran->user_may_read($usr3_reader),  AIR2_AUTHZ_IS_ORG,    "$str3 - read sran" );
is( $sran->user_may_write($usr3_reader), AIR2_AUTHZ_IS_DENIED, "$str3 - no update sran" );

/**********************
 * Quick test of writing/managing
 */
$usr1_reader->UserOrg[0]->uo_ar_id = 3; //WRITER
$usr1_reader->UserOrg[0]->save();
$usr1_reader->UserOrg[0]->clearRelated('AdminRole');
$usr1_reader->clear_authz();
$usr3_reader->UserOrg[0]->uo_ar_id = 4; //MANAGER
$usr3_reader->UserOrg[0]->save();
$usr3_reader->UserOrg[0]->clearRelated('AdminRole');
$usr3_reader->clear_authz();
$child_usr->UserOrg[0]->uo_ar_id = 4;   //MANAGER
$child_usr->UserOrg[0]->save();
$child_usr->UserOrg[0]->clearRelated('AdminRole');
$child_usr->clear_authz();

is( $srs->user_may_read($usr1_reader),   AIR2_AUTHZ_IS_ORG,    "$str1 - read srs" );
is( $srs->user_may_write($usr1_reader),  AIR2_AUTHZ_IS_ORG,    "$str1 - write srs" );
is( $srs->user_may_manage($usr1_reader), AIR2_AUTHZ_IS_DENIED, "$str1 - no manage srs" );

is( $srs->user_may_read($usr3_reader),   AIR2_AUTHZ_IS_ORG,    "$str3 - read srs" );
is( $srs->user_may_write($usr3_reader),  AIR2_AUTHZ_IS_ORG,    "$str3 - write srs" );
is( $srs->user_may_manage($usr3_reader), AIR2_AUTHZ_IS_ORG,    "$str3 - manage srs" );

is( $srs->user_may_read($child_usr),   AIR2_AUTHZ_IS_ORG,    "child($str1) - read srs" );
is( $srs->user_may_write($child_usr),  AIR2_AUTHZ_IS_DENIED,    "child($str1) - write srs" );
is( $srs->user_may_manage($child_usr), AIR2_AUTHZ_IS_DENIED,    "child($str1) - manage srs" );

