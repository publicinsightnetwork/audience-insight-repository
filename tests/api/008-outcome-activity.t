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

$o1 = new TestOrganization();
$o1->add_users(array($u), 4);
$o1->save();

$s1 = new TestSource();
$s1->add_orgs(array($o1));
$s1->save();
$s2 = new TestSource();
$s2->add_orgs(array($o1));
$s2->save();
$s2->SrcEmail[]->sem_email = $s2->src_username;
$s2->save();

$p1 = new TestProject();
$p1->add_orgs(array($o1));
$p1->save();
$p2 = new TestProject();
$p2->add_orgs(array($o1));
$p2->save();

$i1 = new TestInquiry();
$i1->inq_cre_user = $u->user_id;
$i1->add_projects(array($p1));
$i1->save();

$TEST_HL = "008-outcome-activity.t test headline";
$TEST_URL = "http://testurl.com/008-outcome-activity.t";
$cleanup = new TestCleanup('outcome', 'out_headline', $TEST_HL, 10);


AIR2Logger::$ENABLE_LOGGING = true;
plan(57);

/**********************
 * 1) Create an outcome, add stuff in the normal fashion
 */
$data = array(
    'out_headline' => $TEST_HL,
    'out_teaser'   => 'Test outcome',
    'out_url'      => $TEST_URL,
    'out_dtim'     => air2_date()
);
$rs = $api->create("outcome", $data);
is( $rs['code'], AIRAPI::OKAY, 'create outcome - okay' );
$uuid = $rs['uuid'];

$rs = $api->create("outcome/$uuid/source", array('src_uuid' => $s1->src_uuid));
is( $rs['code'], AIRAPI::OKAY, 'add s1 - okay' );
$rs = $api->create("outcome/$uuid/source", array('src_uuid' => $s2->src_uuid));
is( $rs['code'], AIRAPI::OKAY, 'add s2 - okay' );
$rs = $api->create("outcome/$uuid/project", array('prj_uuid' => $p1->prj_uuid));
is( $rs['code'], AIRAPI::OKAY, 'add p1 - okay' );
$rs = $api->create("outcome/$uuid/project", array('prj_uuid' => $p2->prj_uuid));
is( $rs['code'], AIRAPI::OKAY, 'add p2 - okay' );
$rs = $api->create("outcome/$uuid/inquiry", array('inq_uuid' => $i1->inq_uuid));
is( $rs['code'], AIRAPI::OKAY, 'add i1 - okay' );


/**********************
 * 2) Check data
 */
$rs = $api->fetch("outcome/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'fetch outcome - okay' );
is( $rs['radix']['out_headline'], $TEST_HL, 'fetch outcome - hl' );
is( $rs['radix']['out_url'], $TEST_URL, 'fetch outcome - url' );
is( $rs['radix']['src_count'], 2, 'fetch outcome - src count' );
is( $rs['radix']['prj_count'], 2, 'fetch outcome - prj count' );
is( $rs['radix']['inq_count'], 1, 'fetch outcome - inq count' );

is( $s1->SrcActivity->count(), 1, 's1 - 1 activity' );
$sact1 = $s1->SrcActivity[0];
like( $sact1->sact_desc, "/$TEST_HL/", 's1 - desc' );
ok( $sact1->sact_notes, 's1 - notes' );
ok( $json = json_decode($sact1->sact_notes, true), 's1 - decode notes' );
ok( isset($json['outcome']), 's1 - notes json outcome' );
ok( count($json['outcome']), 's1 - notes outcome has fields' );
is( $json['outcome']['out_headline'], $TEST_HL, 's1 - notes outcome headline' );

is( $s2->SrcActivity->count(), 1, 's2 - 1 activity' );
$sact2 = $s2->SrcActivity[0];
like( $sact2->sact_desc, "/$TEST_HL/", 's2 - desc' );
ok( $sact2->sact_notes, 's2 - notes' );
ok( $json = json_decode($sact2->sact_notes, true), 's2 - decode notes' );
ok( isset($json['outcome']), 's2 - notes json outcome' );
ok( count($json['outcome']), 's2 - notes outcome has fields' );
is( $json['outcome']['out_headline'], $TEST_HL, 's2 - notes outcome headline' );


/**********************
 * 3) Delete related
 */
$rs = $api->delete("outcome/$uuid/project/".$p2->prj_uuid);
is( $rs['code'], AIRAPI::OKAY, 'remove p2 - okay' );
$rs = $api->delete("outcome/$uuid/source/".$s2->src_uuid);
is( $rs['code'], AIRAPI::OKAY, 'remove s2 - okay' );


/**********************
 * 4) Check data
 */
$rs = $api->fetch("outcome/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'fetch outcome - okay' );
is( $rs['radix']['src_count'], 1, 'fetch outcome - src count' );
is( $rs['radix']['prj_count'], 1, 'fetch outcome - prj count' );
is( $rs['radix']['inq_count'], 1, 'fetch outcome - inq count' );

$s2->clearRelated();
is( $s2->SrcActivity->count(), 2, 's2 - 2 activity' );
$sact2 = $s2->SrcActivity[1];
like( $sact2->sact_desc, "/removed/", 's2 - desc removed' );
like( $sact2->sact_desc, "/$TEST_HL/", 's2 - desc' );
ok( $sact2->sact_notes, 's2 - notes' );
ok( $json = json_decode($sact2->sact_notes, true), 's2 - decode notes' );


/**********************
 * 5) Create outcome all-at-once
 */
$bad_emails = $s2->src_username.', fakestreet@fake008-outcome-activity.t';
$good_emails = $s2->src_username.', '.$s2->src_username;
$data = array(
    'out_headline' => $TEST_HL,
    'out_teaser'   => 'Test outcome',
    'out_url'      => $TEST_URL,
    'out_dtim'     => air2_date(),
    'prj_uuid'     => $p1->prj_uuid,
    'src_uuid'     => $s1->src_uuid,
    'emails'       => $bad_emails,
);
$rs = $api->create("outcome", $data);
is( $rs['code'], AIRAPI::BAD_DATA, 'create wholesale - bad data' );
like( $rs['message'], '/unknown email/i', 'create wholesale - message' );

$data['emails'] = $good_emails;
$rs = $api->create("outcome", $data);
is( $rs['code'], AIRAPI::OKAY, 'create wholesale - okay' );
is( $rs['radix']['src_count'], 2, 'create wholesale - src count' );
is( $rs['radix']['prj_count'], 1, 'create wholesale - prj count' );
is( $rs['radix']['inq_count'], 0, 'create wholesale - inq count' );
$uuid = $rs['uuid'];


/**********************
 * 6) Check-it!
 */
$s1->clearRelated();
is( $s1->SrcActivity->count(), 2, 's1 - 2 activity' );
$sact1 = $s1->SrcActivity[1];
like( $sact1->sact_desc, "/$TEST_HL/", 's1 - desc' );
ok( $sact1->sact_notes, 's1 - notes' );
ok( $json = json_decode($sact1->sact_notes, true), 's1 - decode notes' );
ok( isset($json['outcome']), 's1 - notes json outcome' );
ok( count($json['outcome']), 's1 - notes outcome has fields' );
is( $json['outcome']['out_headline'], $TEST_HL, 's1 - notes outcome headline' );

$s2->clearRelated();
is( $s2->SrcActivity->count(), 3, 's2 - 3 activity' );
$sact2 = $s2->SrcActivity[2];
like( $sact2->sact_desc, "/$TEST_HL/", 's2 - desc' );
ok( $sact2->sact_notes, 's2 - notes' );
ok( $json = json_decode($sact2->sact_notes, true), 's2 - decode notes' );
ok( isset($json['outcome']), 's2 - notes json outcome' );
ok( count($json['outcome']), 's2 - notes outcome has fields' );
is( $json['outcome']['out_headline'], $TEST_HL, 's2 - notes outcome headline' );
