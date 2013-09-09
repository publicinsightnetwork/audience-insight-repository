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

plan(17);

/**********************
 * Init
 */
AIR2_DBManager::init();

$u = new TestUser();
$u->save();

$i = new TestInquiry();
$i->inq_cre_user = $u->user_id;
$i->inq_rss_intro = 'blah';
$i->save();

ok( $api = new AIRAPI($u), "get API object");


ok( $uuid = $i->inq_uuid, "get new inquiry uuid" );

$mal_formed = '<p>Thank you for your time. Please checkout ' .
    '<a href="http://pinsight.org">The Public Insight Newtork for more ' .
    '<strongchances&emsp;opportunities</strong> to share your insights with ' .
    'us.</p>';

$well_formed  = '<p>Thank you for your time. Please checkout ' .
    '<a href="http://pinsight.org">The Public Insight Newtork</a> for more ' .
    '<strong>chances&emsp;opportunities</strong> to share your insights with ' .
    'us.</p>';


/**********************
 * 1) Create some questions
 */
$rs = $api->create("inquiry/$uuid/question", array('resequence' => 1, 'ques_template' => 'textbox'));
is( $rs['code'], AIRAPI::OKAY, 'init q1 - okay' );
$qid1 = $rs['uuid'];

$rs = $api->create("inquiry/$uuid/question", array('resequence' => 2, 'ques_template' => 'checks'));
is( $rs['code'], AIRAPI::OKAY, 'init q2 - okay' );
$qid2 = $rs['uuid'];


/**********************
 * 2) Updating (good html)
 */
$rs = $api->update("inquiry/$uuid/question/$qid1", array('radix' => array('ques_value' => $well_formed)));
ok( $rs['code'], AIRAPI::OKAY, 'update text question - okay' );
$rs = $api->update("inquiry/$uuid/question/$qid2", array('radix' => array('ques_choices' => '[{"value":"' .
$well_formed . '"}]')));
ok( $rs['code'], AIRAPI::OKAY, 'update text question option - okay' );
$rs = $api->update("inquiry/$uuid", array('radix' => array('inq_intro_para' => $well_formed)));
ok( $rs['code'], AIRAPI::OKAY, 'update long description - okay' );
$rs = $api->update("inquiry/$uuid", array('radix' => array('inq_expire_msg' => $well_formed)));
ok( $rs['code'], AIRAPI::OKAY, 'update expire message - okay' );
$rs = $api->update("inquiry/$uuid", array('radix' => array('inq_deadline_msg' => $well_formed)));
ok( $rs['code'], AIRAPI::OKAY, 'update deadline message - okay' );
$rs = $api->update("inquiry/$uuid", array('radix' => array('inq_confirm_msg' => $well_formed)));
ok( $rs['code'], AIRAPI::OKAY, 'update thank you message - okay' );

/**********************
 * 3) Updating (bad html)
 */
$rs = $api->update("inquiry/$uuid/question/$qid1", array('radix' => array('ques_value' => $mal_formed)));
ok( $rs['code'], AIRAPI::BAD_DATA, 'fail to update text question - BAD_DATA' );
$rs = $api->update("inquiry/$uuid/question/$qid2", array('radix' => array('ques_choices' => '[{"value":"' .
$mal_formed . '"}]')));
ok( $rs['code'], AIRAPI::BAD_DATA, 'update text question option - BAD_DATA' );
$rs = $api->update("inquiry/$uuid", array('radix' => array('inq_intro_para' => $mal_formed)));
ok( $rs['code'], AIRAPI::BAD_DATA, 'fail to update long description - BAD_DATA' );
$rs = $api->update("inquiry/$uuid", array('radix' => array('inq_expire_msg' => $mal_formed)));
ok( $rs['code'], AIRAPI::BAD_DATA, 'fail to update expire message - BAD_DATA' );
$rs = $api->update("inquiry/$uuid", array('radix' => array('inq_deadline_msg' => $mal_formed)));
ok( $rs['code'], AIRAPI::BAD_DATA, 'fail to update deadline message - BAD_DATA' );
$rs = $api->update("inquiry/$uuid", array('radix' => array('inq_confirm_msg' => $mal_formed)));
ok( $rs['code'], AIRAPI::BAD_DATA, 'fail to update thank you message - BAD_DATA' );

/**********************
 * 4) Updating (combo)
 */
$rs = $api->update("inquiry/$uuid", array('radix' => array(
        'inq_intro_para' => $well_formed . ' ',
        'inq_expire_msg' => $mal_formed
    )));
ok( $rs['code'], AIRAPI::BAD_DATA, 'fail to update long description - BAD_DATA' );
