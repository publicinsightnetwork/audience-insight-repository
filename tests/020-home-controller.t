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

// init
AIR2_DBManager::init();
$browser = new AirHttpTest();
$browser->set_user("testuser", array());

plan(19);

/**********************
 * Verify that JSON view isn't allowed
 */
$browser->set_content_type(AirHttpTest::$JSON); // set to json
ok( $resp = $browser->http_get("/"), 'json nav to homepage' );
is( $browser->resp_code(), 415, "json homepage resp code 415" );


/**********************
 * Get HTML homepage
 */
$browser->set_content_type(AirHttpTest::$HTML); // set to html
ok( $resp = $browser->http_get("/"), 'nav to homepage' );
is( $browser->resp_code(), 200, "homepage resp code" );

// USERDATA
$var = air2_get_json_variable('AIR2.Home.USERDATA', $resp);
ok( air2_is_assoc_array($var), 'USERDATA set' );
validate_json($var, 'USERDATA');

// PROJDATA
$var = air2_get_json_variable('AIR2.Home.PROJDATA', $resp);
ok( air2_is_assoc_array($var), 'PROJDATA set' );
validate_json($var, 'PROJDATA');

// INQDATA
$var = air2_get_json_variable('AIR2.Home.INQDATA', $resp);
ok( air2_is_assoc_array($var), 'INQDATA set' );
validate_json($var, 'INQDATA');

?>
