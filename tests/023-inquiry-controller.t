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
require_once 'models/TestInquiry.php';

// init
AIR2_DBManager::init();
$browser = new AirHttpTest();
$browser->set_user("testuser", array());

// create some dummy data
$t1 = new TestInquiry();
$t1->save();
$uuid = $t1->inq_uuid;

plan(54);

////////////////////////////////////
// check inquiry dashboard view html
$browser->set_content_type(AirHttpTest::$HTML);
$page = $browser->http_get("/inquiry/$uuid");
is( $browser->resp_code(), 415, "old url gives 415" );
$page = $browser->http_get("/query/$uuid");
is( $browser->resp_code(), 200, "GET dashboard html" );
$page = $browser->http_get("/query/DOESNTEXIST");
is( $browser->resp_code(), 404, "GET nonexistant dashboard html" );

// questions view
$page = $browser->http_get("/query/$uuid/question");
is( $browser->resp_code(), 415, "GET questions html" );
$page = $browser->http_get("/query/DOESNTEXIST/question");
is( $browser->resp_code(), 404, "GET nonexistant questions html" );

// projects view
$page = $browser->http_get("/query/$uuid/project");
is( $browser->resp_code(), 415, "GET projects html" );
$page = $browser->http_get("/query/DOESNTEXIST/project");
is( $browser->resp_code(), 404, "GET nonexistant projects html" );

// annotations view
$page = $browser->http_get("/query/$uuid/annotation");
is( $browser->resp_code(), 415, "GET annotations html" );
$page = $browser->http_get("/query/DOESNTEXIST/annotation");
is( $browser->resp_code(), 404, "GET nonexistant annotations html" );

// tags view
$page = $browser->http_get("/query/$uuid/tag");
is( $browser->resp_code(), 415, "GET tags html" );
$page = $browser->http_get("/query/DOESNTEXIST/tag");
is( $browser->resp_code(), 404, "GET nonexistant tags html" );


////////////////////////////
// check inquiry json
$browser->set_content_type(AirHttpTest::$JSON);
$json = $browser->http_get("/query/$uuid");
is( $browser->resp_code(), 404, "new url gives 404 for json" );
$json = $browser->http_get("/inquiry/$uuid");
is( $browser->resp_code(), 200, "GET inquiry json" );
ok( $thing = json_decode($json, true), "json decode get inquiry" );
validate_json($thing, 'inquiry'); // 3 tests

// questions json
$json = $browser->http_get("/inquiry/$uuid/question");
is( $browser->resp_code(), 200, "GET questions json" );
ok( $thing = json_decode($json, true), "json decode get questions" );
validate_json($thing, 'questions'); // 3 tests

// projects json
$json = $browser->http_get("/inquiry/$uuid/project");
is( $browser->resp_code(), 200, "GET projects json" );
ok( $thing = json_decode($json, true), "json decode get projects" );
validate_json($thing, 'projects'); // 3 tests

// annotations json
$json = $browser->http_get("/inquiry/$uuid/annotation");
is( $browser->resp_code(), 200, "GET annotations json" );
ok( $thing = json_decode($json, true), "json decode get annotations" );
validate_json($thing, 'annotations'); // 3 tests

// tags json
$json = $browser->http_get("/inquiry/$uuid/tag");
is( $browser->resp_code(), 200, "GET tags json" );
ok( $thing = json_decode($json, true), "json decode get tags" );
validate_json($thing, 'tags'); // 3 tests

// authors json
$json = $browser->http_get("/inquiry/$uuid/author");
is( $browser->resp_code(), 200, "GET author json" );
ok( $thing = json_decode($json, true), "json decode get author" );
validate_json($thing, 'authors'); // 3 tests

// watchers json
$json = $browser->http_get("/inquiry/$uuid/watcher");
is( $browser->resp_code(), 200, "GET watcher json" );
ok( $thing = json_decode($json, true), "json decode get watcher" );
validate_json($thing, 'watchers'); // 3 tests

