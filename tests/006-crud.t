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

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$browser = new AirHttpTest();
$browser->set_test_user();

// dummy data
$p1 = new TestProject();
$p1->save();
$uuid1 = $p1->prj_uuid;
$p2 = new TestProject();
$p2->save();
$uuid2 = $p2->prj_uuid;
$o = new TestOrganization();
$o->save();

plan(46);


/**********************
 * HTML page via GET
 */
$browser->set_content_type(AirHttpTest::$HTML);
ok( $resp = $browser->http_get("project/$uuid1"), 'GET html' );
is( $browser->resp_code(), 200, 'GET html - code' );
like( $browser->resp_content_type(), '/html/', 'GET html - type' );


/**********************
 * list via GET
 */
$browser->set_content_type(AirHttpTest::$JSON);
ok( $resp = $browser->http_get("project"), 'GET list' );
is( $browser->resp_code(), 200, 'GET list - code' );
ok( $json = json_decode($resp, true), 'GET list - decode' );
foreach ($json['radix'] as $row) {
    $u = $row['prj_uuid'];
    ok( !isset($row['prj_id']), "GET list - no PK for $u");
}
is( $json['success'], true, 'GET list - success' );
ok( $json['meta']['total'] >= 10, 'GET list - total' );
ok( count($json['radix']) <= $json['meta']['total'], 'GET list - match' );


/**********************
 * create via POST
 */
$tpn = '006-crud-test-project';
$conn->exec("delete from project where prj_name = '$tpn'");
$data = array('org_uuid' => $o->org_uuid, 'prj_name' => $tpn, 'prj_display_name' => $tpn);
ok( $resp = $browser->http_post("project", array('radix' => json_encode($data))), 'POST create' );
$n = $conn->exec("delete from project where prj_name = '$tpn'");
is( $n, 1, 'POST create - cleanup' );
is( $browser->resp_code(), 200, 'POST create - code' );
ok( $json = json_decode($resp, true), 'POST create - decode' );
is( $json['success'], true, 'POST create - success' );
is( $json['radix']['prj_name'], $tpn, 'POST create - prj_name' );
is( $json['radix']['prj_display_name'], $tpn, 'POST create - prj_display_name' );
ok( isset($json['radix']['prj_uuid']), 'POST create - uuid' );


/**********************
 * read via GET
 */
ok( $resp = $browser->http_get("project/$uuid1"), 'GET fetch' );
is( $browser->resp_code(), 200, 'GET fetch - code' );
ok( $json = json_decode($resp, true), 'GET fetch - decode' );
is( $json['success'], true, 'GET fetch - success' );
is( $json['radix']['prj_name'], $p1->prj_name, 'GET fetch - prj_name' );
is( $json['radix']['prj_uuid'], $p1->prj_uuid, 'GET fetch - prj_uuid' );
ok( !isset($json['radix']['prj_id']), 'GET fetch - no PK id' );


/**********************
 * update via PUT
 */
$pdn = air2_generate_uuid()." test";
$data = array('prj_display_name' => $pdn);
ok( $resp = $browser->http_put("project/$uuid1", array('radix' => json_encode($data))), 'PUT update' );
is( $browser->resp_code(), 200, 'PUT update - code' );
ok( $json = json_decode($resp, true), 'PUT update - decode' );
is( $json['success'], true, 'PUT update - success' );
is( $json['radix']['prj_display_name'], $pdn, 'PUT update - prj_display_name' );


/**********************
 * delete via DELETE
 */
ok( $resp = $browser->http_delete("project/$uuid1"), 'DELETE delete' );
is( $browser->resp_code(), 200, 'DELETE delete - code' );
ok( $json = json_decode($resp, true), 'DELETE delete - decode' );
is( $json['success'], true, 'DELETE delete - success' );
is( $json['uuid'], $uuid1, 'DELETE delete - returned uuid' );
ok( $resp = $browser->http_get("project/$uuid1"), 'GET deleted' );
is( $browser->resp_code(), 404, 'GET deleted - 404' );
