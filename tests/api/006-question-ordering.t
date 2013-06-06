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

plan(45);

/**********************
 * Init
 */
AIR2_DBManager::init();

$u = new TestUser();
$u->save();
ok( $api = new AIRAPI($u), "get API object");

$i = new TestInquiry();
diag("new test inquiry");
$i->inq_cre_user = $u->user_id;
$i->save();

ok( $uuid = $i->inq_uuid, "get new inquiry uuid" );

diag("set up complete");

define('NUM_DEFAULT_QUESTIONS', 4); // 4 contributor 


/**********************
 * 1) Create some questions
 */
$rs = $api->create("inquiry/$uuid/question", array('resequence' => 1, 'ques_template' => 'textbox'));
is( $rs['code'], AIRAPI::OKAY, 'init q1 - okay' );
$qid1 = $rs['uuid'];

$rs = $api->create("inquiry/$uuid/question", array('resequence' => 2, 'ques_template' => 'textbox'));
is( $rs['code'], AIRAPI::OKAY, 'init q2 - okay' );
$qid2 = $rs['uuid'];

$rs = $api->create("inquiry/$uuid/question", array('resequence' => 3, 'ques_template' => 'textbox'));
is( $rs['code'], AIRAPI::OKAY, 'init q3 - okay' );
$qid3 = $rs['uuid'];

$rs = $api->create("inquiry/$uuid/question", array('resequence' => 4, 'ques_template' => 'textbox'));
is( $rs['code'], AIRAPI::OKAY, 'init q4 - okay' );
$qid4 = $rs['uuid'];

// check initial ordering
$rs = $api->query("inquiry/$uuid/question");
//diag_dump($rs);
is( $rs['code'], AIRAPI::OKAY, 'init questions - okay' );
is( count($rs['radix']), NUM_DEFAULT_QUESTIONS + 4, 'init questions - count' );
is( $rs['radix'][0]['ques_uuid'], $qid1, 'init questions - 1' );
is( $rs['radix'][1]['ques_uuid'], $qid2, 'init questions - 2' );
is( $rs['radix'][2]['ques_uuid'], $qid3, 'init questions - 3' );
is( $rs['radix'][3]['ques_uuid'], $qid4, 'init questions - 4' );

/**********************
 * 2) Collision re-ordering
 */
$rs = $api->update("inquiry/$uuid/question/$qid1", array('resequence' => 3));
is( $rs['code'], AIRAPI::OKAY, 'reseq 1 - okay' );

$rs = $api->query("inquiry/$uuid/question");
is( $rs['code'], AIRAPI::OKAY, 'reseq 1 - query' );
is( count($rs['radix']), NUM_DEFAULT_QUESTIONS + 4, 'reseq 1 - count' );
is( $rs['radix'][0]['ques_uuid'], $qid2, 'reseq 1 - 1=2' );
is( $rs['radix'][1]['ques_uuid'], $qid3, 'reseq 1 - 2=3' );
is( $rs['radix'][2]['ques_uuid'], $qid1, 'reseq 1 - 3=1' );
is( $rs['radix'][3]['ques_uuid'], $qid4, 'reseq 1 - 4=4' );


/**********************
 * 3) Collision adding
 */
$rs = $api->create("inquiry/$uuid/question", array('resequence' => 3, 'ques_template' => 'textbox'));
is( $rs['code'], AIRAPI::OKAY, 'add 1 - okay' );
$qid5 = $rs['uuid'];

$rs = $api->query("inquiry/$uuid/question");
is( $rs['code'], AIRAPI::OKAY, 'add 1 - query' );
is( count($rs['radix']), NUM_DEFAULT_QUESTIONS + 5, 'add 1 - count' );
is( $rs['radix'][0]['ques_uuid'], $qid2, 'add 1 - 1=2' );
is( $rs['radix'][1]['ques_uuid'], $qid3, 'add 1 - 2=3' );
is( $rs['radix'][2]['ques_uuid'], $qid5, 'add 1 - 3=5' );
is( $rs['radix'][3]['ques_uuid'], $qid1, 'add 1 - 4=1' );
is( $rs['radix'][4]['ques_uuid'], $qid4, 'add 1 - 4=4' );


/**********************
 * 4) Non-collision re-ordering (move to end)
 */
$rs = $api->update("inquiry/$uuid/question/$qid1", array('resequence' => 10));
is( $rs['code'], AIRAPI::OKAY, 'reseq 2 - okay' );

$rs = $api->query("inquiry/$uuid/question");
is( $rs['code'], AIRAPI::OKAY, 'reseq 2 - query' );
is( count($rs['radix']), NUM_DEFAULT_QUESTIONS + 5, 'reseq 2 - count' );
is( $rs['radix'][0]['ques_uuid'], $qid2, 'reseq 2 - 1=2' );
is( $rs['radix'][1]['ques_uuid'], $qid3, 'reseq 2 - 2=3' );
is( $rs['radix'][2]['ques_uuid'], $qid5, 'reseq 2 - 3=5' );
is( $rs['radix'][3]['ques_uuid'], $qid4, 'reseq 2 - 4=4' );
is( $rs['radix'][8]['ques_uuid'], $qid1, 'reseq 2 - 5=1' );
//diag_dump($rs['radix']);
/**********************
 * 5) Collision re-ordering (move to start)
 */
$rs = $api->update("inquiry/$uuid/question/$qid5", array('resequence' => 1));
is( $rs['code'], AIRAPI::OKAY, 'reseq 3 - okay' );

$rs = $api->query("inquiry/$uuid/question");
is( $rs['code'], AIRAPI::OKAY, 'reseq 3 - query' );
is( count($rs['radix']), NUM_DEFAULT_QUESTIONS + 5, 'reseq 3 - count' );
is( $rs['radix'][0]['ques_uuid'], $qid5, 'reseq 3 - 1=5' );
is( $rs['radix'][1]['ques_uuid'], $qid2, 'reseq 3 - 2=2' );
is( $rs['radix'][2]['ques_uuid'], $qid3, 'reseq 3 - 3=3' );
is( $rs['radix'][3]['ques_uuid'], $qid4, 'reseq 3 - 4=4' );
is( $rs['radix'][8]['ques_uuid'], $qid1, 'reseq 3 - 5=1' );


/**********************
 * 6) Bad sequence
 */
$rs = $api->update("inquiry/$uuid/question/$qid5", array('resequence' => 0));
is( $rs['code'], AIRAPI::BAD_DATA, 'bad sequence - code' );
like( $rs['message'], '/invalid sequence/i', 'bad sequence - message' );
