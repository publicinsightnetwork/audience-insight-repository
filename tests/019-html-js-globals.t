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
require_once 'models/TestUser.php';
require_once 'models/TestOrganization.php';

// init
AIR2_DBManager::init();
$browser = new AirHttpTest();
define('AIR2READER', 2);

plan(19);

/**********************
 * Create a user for us to 'log in' as
 */
$org = new TestOrganization();
$org->save();
$usr = new TestUser();
$usr->UserOrg[0]->uo_org_id = $org->org_id;
$usr->UserOrg[0]->uo_ar_id = AIR2READER; //AIR User role
$usr->UserOrg[0]->uo_status = 'A';
$usr->UserOrg[0]->uo_notify_flag = true;
$usr->UserOrg[0]->uo_home_flag = true;
$usr->save();
$browser->set_user($usr);


/**********************
 * Get HTML page
 */
$browser->set_content_type(AirHttpTest::$HTML); // set to html
ok( $resp = $browser->http_get("/"), 'nav to homepage' );
is( $browser->resp_code(), 200, "homepage resp code" );

// HOMEURL
$var = air2_get_json_variable('AIR2.HOMEURL', $resp);
ok( is_string($var), 'HOMEURL is string' );
is( trim($var, '/'), trim($browser->base_url, '/'), 'HOMEURL set properly' );

// LOGOUTURL
$var = air2_get_json_variable('AIR2.LOGOUTURL', $resp);
ok( is_string($var), 'LOGOUTURL is string' );
is( trim($var, '/'), trim($browser->base_url, '/').'/logout', 'LOGOUTURL set properly' );

// USERNAME
$var = air2_get_json_variable('AIR2.USERNAME', $resp);
ok( is_string($var), 'USERNAME is string' );
is( $var, $usr->user_username, 'USERNAME set properly' );

// USERINFO
$var = air2_get_json_variable('AIR2.USERINFO', $resp);
ok( air2_is_assoc_array($var), 'USERINFO is assoc array' );
$uuid = isset($var['uuid']) ? $var['uuid'] : null;
$username = isset($var['username']) ? $var['username'] : null;
$first_name = isset($var['first_name']) ? $var['first_name'] : null;
$last_name = isset($var['last_name']) ? $var['last_name'] : null;
$type = isset($var['type']) ? $var['type'] : null;
$status = isset($var['status']) ? $var['status'] : null;
is( $uuid, $usr->user_uuid, 'USERINFO uuid' );
is( $username, $usr->user_username, 'USERINFO username' );
is( $first_name, $usr->user_first_name, 'USERINFO first_name' );
is( $last_name, $usr->user_last_name, 'USERINFO last_name' );
is( $type, $usr->user_type, 'USERINFO type' );
is( $status, $usr->user_status, 'USERINFO status' );

// USERAUTHZ
$var = air2_get_json_variable('AIR2.USERAUTHZ', $resp);
ok( air2_is_assoc_array($var), 'USERAUTHZ is assoc array' );
$ar_mask = isset($var[$org->org_uuid]) ? $var[$org->org_uuid] : null;
ok( $ar_mask & ACTION_ORG_READ, 'USERAUTHZ set correct role for test org' );

// BINCOOKIE
$var = air2_get_json_variable('AIR2.BINCOOKIE', $resp);
ok( is_string($var), 'BINCOOKIE is string' );
is( $var, AIR2_BIN_STATE_CK, 'BINCOOKIE set properly' );


?>
