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
require_once 'models/TestProject.php';

// init
AIR2_DBManager::init();
$browser = new AirHttpTest();
$browser->set_user("testuser", array());

// create some dummy data
$t1 = new TestProject();
$t1->save();
$uuid = $t1->prj_uuid;

plan(56);
////////////////////////////////////
// check project dashboard view html
$browser->set_content_type(AirHttpTest::$HTML);
$page = $browser->http_get("/project/$uuid");
is( $browser->resp_code(), 200, "GET dashboard html" );
$page = $browser->http_get("/project/DOESNTEXIST");
is( $browser->resp_code(), 404, "GET nonexistant dashboard html" );

// submission view
$page = $browser->http_get("/project/$uuid/submission");
is( $browser->resp_code(), 415, "GET submissions html" );
$page = $browser->http_get("/project/DOESNTEXIST/submission");
is( $browser->resp_code(), 404, "GET nonexistant submissions html" );

// inquiries view
$page = $browser->http_get("/project/$uuid/inquiry");
is( $browser->resp_code(), 415, "GET inquiries html" );
$page = $browser->http_get("/project/DOESNTEXIST/inquiry");
is( $browser->resp_code(), 404, "GET nonexistant inquiries html" );

// organizations view
$page = $browser->http_get("/project/$uuid/organization");
is( $browser->resp_code(), 415, "GET organizations html" );
$page = $browser->http_get("/project/DOESNTEXIST/organization");
is( $browser->resp_code(), 404, "GET nonexistant organizations html" );

// annotations view
$page = $browser->http_get("/project/$uuid/annotation");
is( $browser->resp_code(), 415, "GET annotations html" );
$page = $browser->http_get("/project/DOESNTEXIST/annotation");
is( $browser->resp_code(), 404, "GET nonexistant annotations html" );

// activity view
$page = $browser->http_get("/project/$uuid/activity");
is( $browser->resp_code(), 415, "GET activity html" );
$page = $browser->http_get("/project/DOESNTEXIST/activity");
is( $browser->resp_code(), 404, "GET nonexistant activity html" );

// tags view
$page = $browser->http_get("/project/$uuid/tag");
is( $browser->resp_code(), 415, "GET tags html" );
$page = $browser->http_get("/project/DOESNTEXIST/tag");
is( $browser->resp_code(), 404, "GET nonexistant tags html" );


////////////////////////////
// check project json
$browser->set_content_type(AirHttpTest::$JSON);
$json = $browser->http_get("/project/$uuid");
is( $browser->resp_code(), 200, "GET project json" );
ok( $thing = json_decode($json, true), "json decode get project" );
validate_json($thing, 'project'); // 3 tests

// submission json
$json = $browser->http_get("/project/$uuid/submission");
is( $browser->resp_code(), 200, "GET submission json" );
ok( $thing = json_decode($json, true), "json decode get submission" );
validate_json($thing, 'submission'); // 3 tests

// inquiries json
$json = $browser->http_get("/project/$uuid/inquiry");
is( $browser->resp_code(), 200, "GET inquiries json" );
ok( $thing = json_decode($json, true), "json decode get inquiries" );
validate_json($thing, 'inquiries'); // 3 tests

// organizations json
$json = $browser->http_get("/project/$uuid/organization");
is( $browser->resp_code(), 200, "GET organizations json" );
ok( $thing = json_decode($json, true), "json decode get organizations" );
validate_json($thing, 'organizations'); // 3 tests

// annotations json
$json = $browser->http_get("/project/$uuid/annotation");
is( $browser->resp_code(), 200, "GET annotations json" );
ok( $thing = json_decode($json, true), "json decode get annotations" );
validate_json($thing, 'annotations'); // 3 tests

// activity json
$json = $browser->http_get("/project/$uuid/activity");
is( $browser->resp_code(), 200, "GET activity json" );
ok( $thing = json_decode($json, true), "json decode get activity" );
validate_json($thing, 'activity'); // 3 tests

// tags json
$json = $browser->http_get("/project/$uuid/tag");
is( $browser->resp_code(), 200, "GET tags json" );
ok( $thing = json_decode($json, true), "json decode get tags" );
validate_json($thing, 'tags'); // 3 tests


?>
