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
require_once 'rframe/AIRAPI.php';
$tdir = APPPATH.'../tests';
require_once "$tdir/Test.php";
require_once "$tdir/models/TestCleanup.php";
require_once "$tdir/models/TestUser.php";
require_once "$tdir/models/TestOrganization.php";
require_once "$tdir/models/TestInquiry.php";
require_once "$tdir/models/TestSource.php";


/**********************
 * Init
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$u = new TestUser();
$u->save();
$api = new AIRAPI($u);

$i = new TestInquiry();
$i->inq_cre_user = $u->user_id;
$i->save();
$i->inq_status = Inquiry::$STATUS_DRAFT;
$i->save();
$uuid = $i->inq_uuid;

$o1 = new TestOrganization();
$o1->add_users(array($u), 4);
$o1->save();
$o2 = new TestOrganization();
$o2->add_users(array($u), 4);
$o2->save();
$p1 = new TestProject();
$p1->add_orgs(array($o1));
$p1->save();
$p2 = new TestProject();
$p2->add_orgs(array($o2));
$p2->save();


plan(64);

/**********************
 * 1) Create some questions, and publish
 */
$rs = $api->create("inquiry/$uuid/question", array('resequence' => 1, 'ques_template' => 'textbox'));
is( $rs['code'], AIRAPI::OKAY, 'init q1 - okay' );
$qid1 = $rs['uuid'];

$rs = $api->create("inquiry/$uuid/question", array('resequence' => 2, 'ques_template' => 'textbox'));
is( $rs['code'], AIRAPI::OKAY, 'init q2 - okay' );
$qid2 = $rs['uuid'];

$rs = $api->update("inquiry/$uuid", array('do_publish' => 1));
is( $rs['code'], AIRAPI::OKAY, 'publish 1 - okay' );
is( $rs['radix']['inq_status'], Inquiry::$STATUS_ACTIVE, 'publish 1 - status' );
is( $rs['radix']['inq_stale_flag'], false, 'publish 1 - not stale' );
ok( isset($rs['radix']['inq_publish_dtim']), 'publish 1 - has dtim' );


/**********************
 * 2) Update inquiry fields
 */
$rs = $api->update("inquiry/$uuid", array('inq_title' => 'newtitle'));
is( $rs['code'], AIRAPI::OKAY, 'upd inq - okay' );
is( $rs['radix']['inq_status'], Inquiry::$STATUS_ACTIVE, 'upd inq - status' );
is( $rs['radix']['inq_stale_flag'], true, 'upd inq - stale' );


/**********************
 * 3) Update question
 */
$i->refresh();
$i->inq_stale_flag = false;
$i->save();
$rs = $api->update("inquiry/$uuid/question/$qid1", array('ques_value' => 'blahquestion?'));
is( $rs['code'], AIRAPI::OKAY, 'upd ques - okay' );

$rs = $api->fetch("inquiry/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'upd ques - fetch okay' );
is( $rs['radix']['inq_status'], Inquiry::$STATUS_ACTIVE, 'upd ques - status' );
is( $rs['radix']['inq_stale_flag'], true, 'upd ques - stale' );


/**********************
 * 4) Add question
 */
$i->refresh();
$i->inq_stale_flag = false;
$i->save();
$rs = $api->create("inquiry/$uuid/question", array('resequence' => 1, 'ques_template' => 'textbox'));
is( $rs['code'], AIRAPI::OKAY, 'cre ques - okay' );

$rs = $api->fetch("inquiry/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'cre ques - fetch okay' );
is( $rs['radix']['inq_status'], Inquiry::$STATUS_ACTIVE, 'cre ques - status' );
is( $rs['radix']['inq_stale_flag'], true, 'cre ques - stale' );


/**********************
 * 5) Remove question
 */
$i->refresh();
$i->inq_stale_flag = false;
$i->save();
$rs = $api->delete("inquiry/$uuid/question/$qid1");
is( $rs['code'], AIRAPI::OKAY, 'del ques - okay' );

$rs = $api->fetch("inquiry/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'del ques - fetch okay' );
is( $rs['radix']['inq_status'], Inquiry::$STATUS_ACTIVE, 'del ques - status' );
is( $rs['radix']['inq_stale_flag'], true, 'del ques - stale' );


/**********************
 * 6) Add organization
 */
$i->refresh();
$i->inq_stale_flag = false;
$i->save();
$rs = $api->create("inquiry/$uuid/organization", array('org_uuid' => $o1->org_uuid));
is( $rs['code'], AIRAPI::OKAY, 'cre org - okay' );
$rs = $api->create("inquiry/$uuid/organization", array('org_uuid' => $o2->org_uuid));
is( $rs['code'], AIRAPI::OKAY, 'cre org - 2nd okay' );

$rs = $api->fetch("inquiry/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'cre org - fetch okay' );
is( $rs['radix']['inq_status'], Inquiry::$STATUS_ACTIVE, 'cre org - status' );
is( $rs['radix']['inq_stale_flag'], true, 'cre org - stale' );


/**********************
 * 7) Remove organization
 */
$i->refresh();
$i->inq_stale_flag = false;
$i->save();
$rs = $api->delete("inquiry/$uuid/organization/".$o1->org_uuid);
is( $rs['code'], AIRAPI::OKAY, 'del org - okay' );

$rs = $api->fetch("inquiry/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'del org - fetch okay' );
is( $rs['radix']['inq_status'], Inquiry::$STATUS_ACTIVE, 'del org - status' );
is( $rs['radix']['inq_stale_flag'], true, 'del org - stale' );


/**********************
 * 8) Add project
 */
$i->refresh();
$i->inq_stale_flag = false;
$i->save();
$rs = $api->create("inquiry/$uuid/project", array('prj_uuid' => $p1->prj_uuid));
is( $rs['code'], AIRAPI::OKAY, 'cre prj - okay' );
$rs = $api->create("inquiry/$uuid/project", array('prj_uuid' => $p2->prj_uuid));
is( $rs['code'], AIRAPI::OKAY, 'cre prj - 2nd okay' );

$rs = $api->fetch("inquiry/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'cre prj - fetch okay' );
is( $rs['radix']['inq_status'], Inquiry::$STATUS_ACTIVE, 'cre prj - status' );
is( $rs['radix']['inq_stale_flag'], true, 'cre_prj - stale' );


/**********************
 * 9) Remove project
 */
$i->refresh();
$i->inq_stale_flag = false;
$i->save();
$rs = $api->delete("inquiry/$uuid/project/".$p1->prj_uuid);
is( $rs['code'], AIRAPI::OKAY, 'del prj - okay' );

$rs = $api->fetch("inquiry/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'del prj - fetch okay' );
is( $rs['radix']['inq_status'], Inquiry::$STATUS_ACTIVE, 'del prj - status' );
is( $rs['radix']['inq_stale_flag'], true, 'del prj - stale' );


/**********************
 * 10) Deadline
 */
$i->refresh();
$i->inq_publish_dtim = air2_date(strtotime('-1 week'));
$old_pdtim = $i->inq_publish_dtim;
$i->inq_deadline_dtim = air2_date(strtotime('-1 day'));
$i->save();
$rs = $api->update("inquiry/$uuid", array('do_publish' => 1));
is( $rs['code'], AIRAPI::OKAY, 'publish 2 - okay' );
is( $rs['radix']['inq_status'], Inquiry::$STATUS_DEADLINE, 'publish 2 - status' );
is( $rs['radix']['inq_stale_flag'], false, 'publish 2 - not stale' );
is( $rs['radix']['inq_publish_dtim'], $old_pdtim, 'publish 2 - pdtim stays same' );

$rs = $api->update("inquiry/$uuid", array('inq_ext_title' => 'new ext title'));
is( $rs['code'], AIRAPI::OKAY, 'publish 2 - change okay' );
is( $rs['radix']['inq_status'], Inquiry::$STATUS_DEADLINE, 'publish 2 - change status' );
is( $rs['radix']['inq_stale_flag'], true, 'publish 2 - change stale' );


/**********************
 * 11) Expire
 */
$i->refresh();
$i->inq_expire_dtim = air2_date(strtotime('-2 day'));
$i->save();
$rs = $api->update("inquiry/$uuid", array('do_expire' => 1, 'inq_title' => 'Expired query'));
is( $rs['code'], AIRAPI::OKAY, 'publish 3 - okay' );
is( $rs['radix']['inq_status'], Inquiry::$STATUS_EXPIRED, 'publish 3 - status' );
is( $rs['radix']['inq_stale_flag'], false, 'publish 3 - not stale' );

// back to deadline
$i->refresh();
$i->inq_expire_dtim = air2_date(strtotime('+1 day'));
$i->save();
$rs = $api->update("inquiry/$uuid", array('do_publish' => 1));
is( $rs['code'], AIRAPI::OKAY, 'publish 3.1 - okay' );
is( $rs['radix']['inq_status'], Inquiry::$STATUS_DEADLINE, 'publish 3.1 - status' );
is( $rs['radix']['inq_stale_flag'], false, 'publish 3.1 - not stale' );

// unset expire_dtim
$i->refresh();
$rs = $api->update("inquiry/$uuid", array('inq_expire_dtim' => ''));
is( $rs['radix']['inq_expire_dtim'], null, 'reset inq_expire_dtim to NULL');
//diag_dump( $rs );


/**********************
 * 12) Deactivate
 */
$rs = $api->update("inquiry/$uuid", array('do_deactivate' => 1));
//diag_dump($rs);
is( $rs['code'], AIRAPI::BAD_DATA, 'deact 1 - cannot deactivate once-published' );

$i->inq_status = Inquiry::$STATUS_DRAFT;
$i->save();
$rs = $api->update("inquiry/$uuid", array('do_deactivate' => 1));
//diag_dump($rs);
is( $rs['code'], AIRAPI::OKAY, 'deact 1 - ok' );
is( $rs['radix']['inq_status'], Inquiry::$STATUS_INACTIVE, 'deact 1 - status' );
is( $rs['radix']['inq_stale_flag'], false, 'deact 1 - not stale' );

$rs = $api->update("inquiry/$uuid", array('do_deactivate' => 1));
is( $rs['code'], AIRAPI::BAD_DATA, 'deact 2 - cannot deactivate already deactivated' );


/**********************
 * 13) Check publish-dtim changes
 */
$old_pdtim = $i->inq_publish_dtim;
sleep(1);   // let the clock unwind
$rs = $api->update("inquiry/$uuid", array('do_publish' => 1));
is( $rs['code'], AIRAPI::OKAY, 'publish dtim - okay' );
is( $rs['radix']['inq_status'], Inquiry::$STATUS_DEADLINE, 'publish dtim - status' );
is( $rs['radix']['inq_publish_dtim'], $old_pdtim, 'publish dtim - no change if already published' );


/**********************
 * 14) Delete
 */
$rs = $api->delete("inquiry/$uuid");
is( $rs['code'], AIRAPI::BAD_METHOD, 'delete 1 - NOT okay' );
like( $rs['message'], '/non-draft/i', 'delete 1 - message' );

$i->refresh();
$i->inq_status = Inquiry::$STATUS_DRAFT;
$i->save();

$rs = $api->delete("inquiry/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'delete 2 - okay' );
