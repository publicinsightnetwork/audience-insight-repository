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
require_once 'models/TestSource.php';
require_once 'models/TestProject.php';
require_once 'models/TestUser.php';

// init
AIR2_DBManager::init();
$browser = new AirHttpTest();
$u = new TestUser();
$u->save();
$u->user_type = User::$TYPE_SYSTEM; //avoid authz
$u->save();
$browser->set_user($u);
$browser->set_content_type(AirHttpTest::$HTML);

// create some dummy data
$i = new TestInquiry();
$i->Question[0]->ques_value = 'testtest';
$i->save();

$s = new TestSource();
$s->save();
$suuid = $s->src_uuid;

$r = new SrcResponseSet();
$r->srs_src_id = $s->src_id;
$r->srs_inq_id = $i->inq_id;
$r->srs_date = air2_date();
$r->SrcResponse[0]->sr_src_id = $s->src_id;
$r->SrcResponse[0]->sr_ques_id = $i->Question[0]->ques_id;
$r->SrcResponse[0]->sr_orig_value = 'blah';
$r->save();
$uuid = $r->srs_uuid;

plan(49);

/**********************
 * sanity check html
 */
$page = $browser->http_get("/submission/$uuid");
is( $browser->resp_code(), 200, "GET dashboard html" );
$page = $browser->http_get("/submission/DOESNTEXIST");
is( $browser->resp_code(), 404, "GET nonexistant dashboard html" );

// responses view
$page = $browser->http_get("/submission/$uuid/response");
is( $browser->resp_code(), 415, "GET responses html" );
$page = $browser->http_get("/submission/DOESNTEXIST/question");
is( $browser->resp_code(), 404, "GET nonexistant responses html" );

// annotations view
$page = $browser->http_get("/submission/$uuid/annotation");
is( $browser->resp_code(), 415, "GET annotations html" );
$page = $browser->http_get("/submission/DOESNTEXIST/annotation");
is( $browser->resp_code(), 404, "GET nonexistant annotations html" );

// source view
$page = $browser->http_get("/submission/$uuid/source");
is( $browser->resp_code(), 415, "GET source html" );
$page = $browser->http_get("/submission/DOESNTEXIST/source");
is( $browser->resp_code(), 404, "GET nonexistant source html" );

// tags view
$page = $browser->http_get("/submission/$uuid/tag");
is( $browser->resp_code(), 415, "GET tags html" );
$page = $browser->http_get("/submission/DOESNTEXIST/tag");
is( $browser->resp_code(), 404, "GET nonexistant tags html" );


/**********************
 * sanity check json
 */
$browser->set_content_type(AirHttpTest::$JSON);
$json = $browser->http_get("/submission/$uuid");
is( $browser->resp_code(), 200, "GET submission json" );
ok( $thing = json_decode($json, true), "json decode get submission" );
validate_json($thing, 'submission'); // 3 tests

// responses json
$json = $browser->http_get("/submission/$uuid/response");
is( $browser->resp_code(), 200, "GET responses json" );
ok( $thing = json_decode($json, true), "json decode get responses" );
validate_json($thing, 'responses'); // 3 tests

//good place to change things and make sure they cascade and are returned
//change sr_mod_value as a test user and make sure Usr
$source_response = $thing['radix'][0];
$sr_uuid = $source_response['sr_uuid'];

//check response json for upduser
$json = $browser->http_get("/submission/$uuid/response/$sr_uuid.json");

is( $browser->resp_code(), 200, "fetch response json" );
ok( $thing = json_decode($json, true), "json decode get single response" );
isnt( $thing['radix']['UpdUser']['user_username'], $u->user_username, 'get - upd by user not our test user' );

$data = array( 'sr_mod_value' => 'moo' );
$params = array( 'radix' => json_encode($data) );
$json = $browser->http_put("/submission/$uuid/response/$sr_uuid.json", $params);
is( $browser->resp_code(), 200, "update response json" );
ok( $thing = json_decode($json, true), "json decode put response" );
is( $thing['radix']['UpdUser']['user_username'], $u->user_username, "put - upd by user is our test user" );

// responses json second fetch
$json = $browser->http_get("/submission/$uuid/response/$sr_uuid.json");
is( $browser->resp_code(), 200, "GET responses json" );
ok( $thing = json_decode($json, true), "json decode get single response" );
is( $thing['radix']['UpdUser']['user_username'], $u->user_username, 'fetch - upd by user is our test user' );

// annotations json
$json = $browser->http_get("/submission/$uuid/annotation");
is( $browser->resp_code(), 200, "GET annotations json" );
ok( $thing = json_decode($json, true), "json decode get annotations" );
validate_json($thing, 'annotations'); // 3 tests

// source json
$json = $browser->http_get("/submission/$uuid/source");
is( $browser->resp_code(), 200, "GET source json" );
ok( $thing = json_decode($json, true), "json decode get source" );
validate_json($thing, 'source'); // 3 tests

// tags json
$json = $browser->http_get("/submission/$uuid/tag");
is( $browser->resp_code(), 200, "GET tags json" );
ok( $thing = json_decode($json, true), "json decode get tags" );
validate_json($thing, 'tags'); // 3 tests
