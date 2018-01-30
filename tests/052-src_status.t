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

require_once 'Test.php';
require_once 'app/init.php';
require_once 'AirTestUtils.php';
require_once 'models/TestSource.php';
require_once 'models/TestOrganization.php';
require_once 'models/TestProject.php';
require_once 'models/TestInquiry.php';

// init
AIR2_DBManager::init();
plan(11);

// since we use activities to determine some status values
define('AIR2_REMOTE_USER_ID', 1);
AIR2Logger::$ENABLE_LOGGING = true;

// create some dummy data
$src = new TestSource();
$src->src_first_name = "";
$src->src_last_name  = "";
$src->save();

is( $src->src_status, Source::$STATUS_ANONYMOUS, "default status with no name is Z" );

$org1 = new TestOrganization();
$org1->save();

$org2 = new TestOrganization();
$org2->save();

$org3 = new TestOrganization();
$org3->save();

// create project and inquiry
$project = new TestProject();
$project->save();
$inquiry = new TestInquiry();
$inquiry->add_projects(array($project));
$inquiry->Question[0]->ques_value = 'what is the air-speed velocity of a swallow?';
$inquiry->save();

$src->src_first_name = 'Some';
$src->src_last_name  = 'Body';
$src->save();

is( $src->src_status, Source::$STATUS_NO_PRIMARY_EMAIL, "default status is N" );

// add an email
$src->SrcEmail[0]->sem_email = 'ima-src-status-test@nosuchemail.org';
$src->SrcEmail[0]->sem_primary_flag = 1;
$src->save();
is( $src->src_status, Source::$STATUS_NO_ORGS, "has email but no orgs" );

// add to some orgs
$so1 = new SrcOrg();
$so1->so_src_id = $src->src_id;
$so1->so_org_id = $org1->org_id;
$src->SrcOrg[] = $so1;
$src->save();
is( $src->src_status, Source::$STATUS_ENROLLED, "1 SrcOrg no responses == E" );

$so2 = new SrcOrg();
$so2->so_src_id = $src->src_id;
$so2->so_org_id = $org2->org_id;
$so2->so_status = SrcOrg::$STATUS_OPTED_OUT;
$src->SrcOrg[] = $so2;
$src->save();
is( $src->src_status, Source::$STATUS_ENROLLED, "2 SrcOrg no responses == E" );

$so3 = new SrcOrg();
$so3->so_src_id = $src->src_id;
$so3->so_org_id = $org2->org_id;
$so3->so_status = SrcOrg::$STATUS_EDITORIAL_DEACTV;
$src->SrcOrg[] = $so2;
$src->save();
is( $src->src_status, Source::$STATUS_ENROLLED, "3 SrcOrg no responses == E" );

$so1->so_status = SrcOrg::$STATUS_DELETED;
//$so1->save();
$src->save();
is( $src->src_status, Source::$STATUS_OPTED_OUT, "3 SrcOrg, 1 deleted, no responses == D" );

$so1->so_status = SrcOrg::$STATUS_OPTED_IN;
$so1->save();
//$src->save();
is( $src->set_src_status(), Source::$STATUS_ENROLLED, "3 SrcOrg, 1 reactivated no responses == E" );

// create some responses+activities
$srs1 = new SrcResponseSet();
$srs1->srs_date = air2_date();
$srs1->srs_src_id = $src->src_id;
$srs1->srs_inq_id = $inquiry->inq_id;
$srs1->SrcResponse[0]->sr_src_id = $src->src_id;
$srs1->SrcResponse[0]->sr_ques_id = $inquiry->Question[0]->ques_id;
$srs1->SrcResponse[0]->sr_orig_value = 'european or african swallow?';
$srs1->save();
$sact1 = new SrcActivity();
$sact1->sact_actm_id = 4;
$sact1->sact_src_id = $src->src_id;
$sact1->sact_prj_id = $project->prj_id;
$sact1->sact_dtim = air2_date();
$sact1->sact_xid = $srs1->srs_id;
$sact1->sact_ref_type = SrcActivity::$REF_TYPE_RESPONSE;
$sact1->save();
is( $src->set_src_status(), Source::$STATUS_ENROLLED, "3 SrcOrg 1 response == E" );



$srs2 = new SrcResponseSet();
$srs2->srs_date = air2_date(time()+1);
$srs2->srs_src_id = $src->src_id;
$srs2->srs_inq_id = $inquiry->inq_id;
$srs2->SrcResponse[0]->sr_src_id = $src->src_id;
$srs2->SrcResponse[0]->sr_ques_id = $inquiry->Question[0]->ques_id;
$srs2->SrcResponse[0]->sr_orig_value = 'blue! no, red!';
$srs2->save();
$sact2 = new SrcActivity();
$sact2->sact_actm_id = 4;
$sact2->sact_src_id = $src->src_id;
$sact2->sact_prj_id = $project->prj_id;
$sact2->sact_dtim = air2_date(time()+1);
$sact2->sact_xid = $srs1->srs_id;
$sact2->sact_ref_type = SrcActivity::$REF_TYPE_RESPONSE;
$sact2->save();
is( $src->set_src_status(), Source::$STATUS_ENGAGED, "3 SrcOrg 2 responses == A" );

// try adding source to blacklisted org
$all_pin = Doctrine::getTable('Organization')->findOneBy('org_name', 'allPIN');
$so4 = new SrcOrg();
$so4->so_src_id = $src->src_id;
$so4->so_org_id = $all_pin->org_id;
$src->SrcOrg[] = $so4;
try {
  $src->save();
  fail( "Assigning to All PIN Org should throw exception" );
}
catch (Exception $ex) {
  ok( $ex, "Caught exception trying to add Source to AllPIN Org: $ex" );
}
