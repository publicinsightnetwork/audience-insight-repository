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
$browser->set_content_type(AirHttpTest::$JSON);

// dummy data;
$u = new TestUser();
$u->save();
$u->user_type = User::$TYPE_SYSTEM; //avoid authz
$u->save();
$browser->set_user($u);

$p = new TestProject();
$p->save();
$uuid = $p->prj_uuid;

plan(20);


/**********************
 * Read
 */
ok( $resp = $browser->http_get("project/$uuid"), 'GET fetch' );
is( $browser->resp_code(), 200, 'GET fetch - code' );
ok( $json = json_decode($resp, true), 'GET fetch - decode' );
is( $json['success'], true, 'GET fetch - success' );

$cre = $json['radix']['prj_cre_dtim'];
ok( isset($json['radix']['CreUser']), 'GET fetch - CreUser set' );
is( $json['radix']['CreUser']['user_username'], 'AIR2SYSTEM', 'GET fetch - cre by system' );
is( $json['radix']['UpdUser']['user_username'], 'AIR2SYSTEM', 'GET fetch - last upd by system' );
ok( !isset($json['radix']['CreUser']['user_id']), 'GET fetch - no cre user id' );
is( $json['radix']['prj_upd_dtim'], $cre, 'GET fetch - cre and upd same' );

ok( !isset($json['radix']['prj_cre_user']), 'GET fetch - no cre id' );
ok( !isset($json['radix']['prj_upd_user']), 'GET fetch - no upd id' );


/**********************
 * update
 */
sleep(1);
$pdn = air2_generate_uuid()." test";
$data = array('prj_display_name' => $pdn);
ok( $resp = $browser->http_put("project/$uuid", array('radix' => json_encode($data))), 'PUT update' );
is( $browser->resp_code(), 200, 'PUT update - code' );
ok( $json = json_decode($resp, true), 'PUT update - decode' );
is( $json['success'], true, 'PUT update - success' );
is( $json['radix']['prj_display_name'], $pdn, 'PUT update - prj_display_name' );

is( $json['radix']['prj_cre_dtim'], $cre, 'PUT update - cre same' );
isnt( $json['radix']['prj_upd_dtim'], $cre, 'PUT update - cre and upd different' );
is( $json['radix']['CreUser']['user_username'], 'AIR2SYSTEM', 'GET fetch - cre by system' );
is( $json['radix']['UpdUser']['user_username'], $u->user_username, 'GET fetch - upd by user' );
