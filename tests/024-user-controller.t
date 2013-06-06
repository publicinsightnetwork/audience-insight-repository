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

// init
AIR2_DBManager::init();
$browser = new AirHttpTest();
$browser->set_user("testuser", array());

// create a test user to look at
$u = new TestUser();
$u->save();
$uuid = $u->user_uuid;

plan(48);

/**********************
 * Validate HTML inline data
 */
$browser->set_content_type(AirHttpTest::$HTML); // set to html
ok( $resp = $browser->http_get("/user/$uuid"), 'nav to userpage' );
is( $browser->resp_code(), 200, "userpage resp code" );

$var = air2_get_json_variable('AIR2.User.BASE', $resp);
validate_json($var, 'BASE');
$var = air2_get_json_variable('AIR2.User.ORGDATA', $resp);
validate_json($var, 'ORGDATA');
$var = air2_get_json_variable('AIR2.User.ACTDATA', $resp);
validate_json($var, 'ACTDATA');
$var = air2_get_json_variable('AIR2.User.NETDATA', $resp);
validate_json($var, 'NETDATA');


/**********************
 * Validate JSON data
 */
$browser->set_content_type(AirHttpTest::$JSON); // set to json

ok( $resp = $browser->http_get("/user/$uuid"), 'json nav to user' );
is( $browser->resp_code(), 200, "json user resp code" );
validate_json($resp, 'user');

ok( $resp = $browser->http_get("/user/$uuid/email"), 'json nav to email' );
is( $browser->resp_code(), 200, "json email resp code" );
validate_json($resp, 'email');

ok( $resp = $browser->http_get("/user/$uuid/phone"), 'json nav to phone' );
is( $browser->resp_code(), 200, "json phone resp code" );
validate_json($resp, 'phone');

ok( $resp = $browser->http_get("/user/$uuid/organization"), 'json nav to organizations' );
is( $browser->resp_code(), 200, "json organizations resp code" );
validate_json($resp, 'organizations');

ok( $resp = $browser->http_get("/user/$uuid/network"), 'json nav to networks' );
is( $browser->resp_code(), 200, "json networks resp code" );
validate_json($resp, 'networks');
