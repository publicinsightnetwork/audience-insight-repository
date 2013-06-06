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

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$browser = new AirHttpTest();
$browser->set_content_type(AirHttpTest::$JSON);

// for some reason, CI xss-clean has an issue with this
$secret = 'TestPassw&rd123$';

// setup user to login as
$u = new TestUser();
$u->user_password = $secret;
$u->save();

plan(15);


/**********************
 * Check password php methods
 */
isnt( $u->user_password, $secret, 'password mutated' );
ok( !$u->check_password('nothing'), 'bad password' );
ok( $u->check_password($secret), 'password matches' );


/**********************
 * Http login - bad username
 */
$creds = array('username' => 'blah', 'password' => 'blah', 'admin' => 1);
ok( $resp = $browser->http_post('login', $creds), 'bad username' );
is( $browser->resp_code(), 401, 'bad username - code' );
ok( $json = json_decode($resp, true), 'bad username - decode' );
ok( !$json['success'], 'bad username - unsuccess' );


/**********************
 * Http login - bad password
 */
$creds['username'] = $u->user_username;
ok( $resp = $browser->http_post('login', $creds), 'bad password' );
is( $browser->resp_code(), 401, 'bad password - code' );
ok( $json = json_decode($resp, true), 'bad password - decode' );
ok( !$json['success'], 'bad password - unsuccess' );


/**********************
 * Http login - good stuff
 */
$creds['password'] = $secret;
ok( $resp = $browser->http_post('login', $creds), 'good stuff' );
is( $browser->resp_code(), 200, 'good stuff - code' );
ok( $json = json_decode($resp, true), 'good stuff - decode' );
ok( $json['success'], 'good stuff - success' );
