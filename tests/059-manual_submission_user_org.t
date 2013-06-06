#!/usr/bin/env php
<?php
/**************************************************************************
 *
 *   Copyright 2013 American Public Media Group
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
require_once 'Test.php';
require_once 'AirTestUtils.php';
require_once 'AirHttpTest.php';
require_once "models/TestUser.php";

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// http test
$browser = new AirHttpTest();
$browser->set_test_user();
$browser->set_content_type(AirHttpTest::$JSON);

$manual_uuid = 'dLBQu3yPPCw4';

plan(11);

// Test the case where the submission is a manual submission.
// In #7067 manual submissions do not have a defined organization
// under the user_org object.
ok( $manual_resp = $browser->http_get("/submission/$manual_uuid"),
    'manual submission json' );

is( $browser->resp_code(), 200, 'submission json resp code' );
ok( $json = json_decode($manual_resp, true), 'GET manual submission' );
is( $json['success'], true, 'GET manual - success' );
validate_json($json, 'manual submission'); // 4 tests
$source_manual_response = $json['radix'];
//diag_dump( $source_manual_response );

ok($cre_user = $source_manual_response['CreUser'],
    "Manual submission Created user exists");
ok($user_org = $cre_user['UserOrg'][0], "Got the UserOrg");
//diag_dump( $user_org );
ok($organization = $user_org['Organization'],
    "Getting the Organization object from the UserOrg");
