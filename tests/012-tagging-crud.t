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
require_once 'AirHttpTest.php';
require_once 'models/TestProject.php';
require_once 'models/TestOrganization.php';
require_once 'models/TestUser.php';
require_once 'models/TestTagMaster.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$browser = new AirHttpTest();
$browser->set_content_type(AirHttpTest::$JSON);
$browser->set_test_user();

// dummy data;
$p = new TestProject();
$p->save();
$uuid = $p->prj_uuid;
$t1 = new TestTagMaster();
$t1->save();
$t2 = new TestTagMaster();
$t2->save();

plan(54);

/**********************
 * LIST tags
 */
ok( $resp = $browser->http_get("project/$uuid/tag"), 'LIST tags' );
is( $browser->resp_code(), 200, 'LIST tags - code' );
ok( $json = json_decode($resp, true), 'LIST tags - decode' );
is( $json['success'], true, 'LIST tags - success' );
is( count($json['radix']), 0, 'LIST tags - count' );


/**********************
 * POST tag
 */
$data = array('radix' => json_encode(array('tm_name' => $t1->tm_name)));
ok( $resp = $browser->http_post("project/$uuid/tag", $data), 'POST tag' );
is( $browser->resp_code(), 200, 'POST tag - code' );
ok( $json = json_decode($resp, true), 'POST tag - decode' );
is( $json['success'], true, 'POST tag - success' );
is( $json['radix']['tm_name'], $t1->tm_name, 'POST tag - tm_name' );
is( $json['radix']['tm_id'], $t1->tm_id, 'POST tag - tm_id' );
is( $json['radix']['tm_type'], 'J', 'POST tag - tm_type' );
ok( isset($json['radix']['tag_cre_dtim']), 'POST tag - tag_cre_dtim' );
$cre = $json['radix']['tag_cre_dtim'];


/***********************
 * POST same tag (by tm_id)
 */
sleep(1);
$data = array('radix' => json_encode(array('tm_id' => $t1->tm_id)));
ok( $resp = $browser->http_post("project/$uuid/tag", $data), 'POST tag2' );
is( $browser->resp_code(), 200, 'POST tag2 - code' );
ok( $json = json_decode($resp, true), 'POST tag2 - decode' );
is( $json['success'], true, 'POST tag2 - success' );
is( $json['radix']['tm_name'], $t1->tm_name, 'POST tag2 - tm_name' );
is( $json['radix']['tm_id'], $t1->tm_id, 'POST tag2 - tm_id' );
is( $json['radix']['tag_cre_dtim'], $cre, 'POST tag2 - same cre_dtim' );
isnt( $json['radix']['tag_upd_dtim'], $cre, 'POST tag2 - different upd_dtim' );
$upd = $json['radix']['tag_upd_dtim'];


/***********************
 * POST same tag (by tm_name)
 */
sleep(1);
$data = array('radix' => json_encode(array('tm_name' => $t1->tm_name)));
ok( $resp = $browser->http_post("project/$uuid/tag", $data), 'POST tag3' );
is( $browser->resp_code(), 200, 'POST tag3 - code' );
ok( $json = json_decode($resp, true), 'POST tag3 - decode' );
is( $json['success'], true, 'POST tag3 - success' );
is( $json['radix']['tm_name'], $t1->tm_name, 'POST tag3 - tm_name' );
is( $json['radix']['tm_id'], $t1->tm_id, 'POST tag3 - tm_id' );
is( $json['radix']['tag_cre_dtim'], $cre, 'POST tag3 - same cre_dtim' );
isnt( $json['radix']['tag_upd_dtim'], $upd, 'POST tag3 - different upd_dtim' );


/***********************
 * POST same tag (lowercased!)
 */
$data = array('radix' => json_encode(array('tm_name' => strtolower($t1->tm_name))));
ok( $resp = $browser->http_post("project/$uuid/tag", $data), 'POST tag4' );
is( $browser->resp_code(), 200, 'POST tag4 - code' );
ok( $json = json_decode($resp, true), 'POST tag4 - decode' );
is( $json['success'], true, 'POST tag4 - success' );
is( $json['radix']['tm_name'], $t1->tm_name, 'POST tag4 - tm_name' );


/***********************
 * LIST tags
 */
ok( $resp = $browser->http_get("project/$uuid/tag"), 'LIST tags' );
is( $browser->resp_code(), 200, 'LIST tags - code' );
ok( $json = json_decode($resp, true), 'LIST tags - decode' );
is( $json['success'], true, 'LIST tags - success' );
is( count($json['radix']), 1, 'LIST tags - count' );


/***********************
 * GET tag
 */
$tmid = $t1->tm_id;
ok( $resp = $browser->http_get("project/$uuid/tag/$tmid"), 'GET tag' );
is( $browser->resp_code(), 200, 'GET tag - code' );
ok( $json = json_decode($resp, true), 'GET tag - decode' );
is( $json['success'], true, 'GET tag - success' );


/**********************
 * Remove tag
 */
ok( $resp = $browser->http_delete("project/$uuid/tag/$tmid"), 'DELETE tag' );
is( $browser->resp_code(), 200, 'DELETE tag - code' );
ok( $json = json_decode($resp, true), 'DELETE tag - decode' );
is( $json['success'], true, 'DELETE tag - success' );


/**********************
 * verify tag is gone
 */
ok( $resp = $browser->http_get("project/$uuid/tag/$tmid"), 'GET tag' );
is( $browser->resp_code(), 404, 'GET tag - code' );

ok( $resp = $browser->http_get("project/$uuid/tag"), 'LIST tags' );
is( $browser->resp_code(), 200, 'LIST tags - code' );
ok( $json = json_decode($resp, true), 'LIST tags - decode' );
is( $json['success'], true, 'LIST tags - success' );
is( count($json['radix']), 0, 'LIST tags - count' );
