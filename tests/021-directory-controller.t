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
require_once 'AirTestUtils.php';
require_once 'models/TestUser.php';
require_once 'models/TestOrganization.php';

// init
AIR2_DBManager::init();
$browser = new AirHttpTest();
$browser->set_user("testuser", array());

plan(50);

// create an organization, and put a user in it
$org = new TestOrganization();
$org->save();
$usr = new TestUser();
$usr->UserOrg[0]->uo_org_id = $org->org_id;
$usr->UserOrg[0]->uo_ar_id = 1; //AIR User role
$usr->UserOrg[0]->uo_status = 'A';
$usr->UserOrg[0]->uo_notify_flag = true;
$usr->UserOrg[0]->uo_home_flag = true;
$usr->save();
$browser->set_user($usr);

// create email
$uem = new UserEmailAddress();
$uem->uem_user_id = $usr->user_id;
$uem->uem_primary_flag = true;
$uem->uem_address = $usr->user_username.'@fakeemail.com';
$uem->save();

/**********************
 * Get AIR2 Directory page
 */
$browser->set_content_type(AirHttpTest::$HTML); // set to html
ok( $resp = $browser->http_get("/directory"), 'nav to directory' );
is( $browser->resp_code(), 200, "directory resp code" );

// USERDATA
$var = air2_get_json_variable('AIR2.Directory.USERDIR', $resp);
ok( air2_is_assoc_array($var), 'USERDIR set' );
validate_json($var, 'USERDIR');

// STATS
$var = air2_get_json_variable('AIR2.Directory.ORGDIR', $resp);
ok( air2_is_assoc_array($var), 'ORGDIR set' );
validate_json($var, 'ORGDIR');

/**********************
 * Get AIR2 Directory json data
 */
$browser->set_content_type(AirHttpTest::$JSON);
ok( $resp = $browser->http_get("/user"), 'directory json' );
is( $browser->resp_code(), 200, "directory json resp code" );
ok( $json = json_decode($resp, true), 'directory json decode' );
validate_json($json, 'directory');
ok( $json['meta']['total'] > 0, 'directory has at least 1 organization' );
ok( is_array($json['radix']), 'directory radix is array' );
ok( array_key_exists('org_uuid', $json['radix'][0]), 'directory userorgs set' );

/**********************
 * Query for specific organization
 */
ok( $resp = $browser->http_get("/user?filter=".$org->org_name), 'orgname' );
is( $browser->resp_code(), 200, "orgname resp code" );
ok( $json = json_decode($resp, true), 'orgname json decode' );
validate_json($json, 'orgname');
is( count($json['radix']), 1, 'orgname contains 1 user' );
is( $json['radix'][0]['user_uuid'], $usr->user_uuid, 'orgname useruuid' );

/**********************
 * Query for specific user
 */
ok( $resp = $browser->http_get("/user?filter=".$usr->user_username), 'userq' );
is( $browser->resp_code(), 200, "userq resp code" );
ok( $json = json_decode($resp, true), 'userq json decode' );
validate_json($json, 'userq');
is( $json['meta']['total'], 1, 'userq count is 1' );
is( $json['radix'][0]['org_uuid'], $org->org_uuid, 'userq org is correct' );

/**********************
 * Query by email
 */
$e = array('filter' => $uem->uem_address);
ok( $resp = $browser->http_get("/user", $e), 'uem' );
is( $browser->resp_code(), 200, "uem resp code" );
ok( $json = json_decode($resp, true), 'uem json decode' );
validate_json($json, 'uem');
is( $json['meta']['total'], 1, 'uem count is 1' );
is( $json['radix'][0]['user_username'], $usr->user_username, 'uem is user' );
is( $json['radix'][0]['uem_address'], $uem->uem_address, 'uem is address' );
