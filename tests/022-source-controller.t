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
require_once 'models/TestSource.php';
require_once 'models/TestOrganization.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$browser = new AirHttpTest();
$browser->set_user("testuser", array());

// create some dummy data
$t1 = new TestSource();
$t1->save();
$uuid = $t1->src_uuid;

plan(66);
////////////////////////////////////
// check source dashboard view html
$browser->set_content_type(AirHttpTest::$HTML);
$page = $browser->http_get("/source/$uuid");
is( $browser->resp_code(), 200, "GET dashboard html" );
$page = $browser->http_get("/source/DOESNTEXIST");
is( $browser->resp_code(), 404, "GET nonexistant dashboard html" );

// organizations view
$page = $browser->http_get("/source/$uuid/organization");
is( $browser->resp_code(), 415, "GET organizations html" );
$page = $browser->http_get("/source/DOESNTEXIST/organizations");
is( $browser->resp_code(), 404, "GET nonexistant organizations html" );

// submission view
$page = $browser->http_get("/source/$uuid/submission");
is( $browser->resp_code(), 415, "GET submissions html" );
$page = $browser->http_get("/source/DOESNTEXIST/submissions");
is( $browser->resp_code(), 404, "GET nonexistant submissions html" );

// annotations view
$page = $browser->http_get("/source/$uuid/annotation");
is( $browser->resp_code(), 415, "GET annotations html" );
$page = $browser->http_get("/source/DOESNTEXIST/annotations");
is( $browser->resp_code(), 404, "GET nonexistant annotations html" );

// activity view
$page = $browser->http_get("/source/$uuid/activity");
is( $browser->resp_code(), 415, "GET activity html" );
$page = $browser->http_get("/source/DOESNTEXIST/activity");
is( $browser->resp_code(), 404, "GET nonexistant activity html" );

// tags view
$page = $browser->http_get("/source/$uuid/tag");
is( $browser->resp_code(), 415, "GET tags html" );
$page = $browser->http_get("/source/DOESNTEXIST/tags");
is( $browser->resp_code(), 404, "GET nonexistant tags html" );


////////////////////////////
// check source json
$browser->set_content_type(AirHttpTest::$JSON);
$json = $browser->http_get("/source/$uuid");
is( $browser->resp_code(), 200, "GET source json" );
ok( $thing = json_decode($json, true), "json decode get source" );
validate_json($thing, 'source'); // 3 tests

// organizations json
$json = $browser->http_get("/source/$uuid/organization");
is( $browser->resp_code(), 200, "GET organizations json" );
ok( $thing = json_decode($json, true), "json decode get organizations" );
validate_json($thing, 'organizations'); // 3 tests

// submission json
$json = $browser->http_get("/source/$uuid/submission");
is( $browser->resp_code(), 200, "GET submission json" );
ok( $thing = json_decode($json, true), "json decode get submission" );
validate_json($thing, 'submission'); // 3 tests

// annotations json
$json = $browser->http_get("/source/$uuid/annotation");
is( $browser->resp_code(), 200, "GET annotations json" );
ok( $thing = json_decode($json, true), "json decode get annotations" );
validate_json($thing, 'annotations'); // 3 tests

// activity json
$json = $browser->http_get("/source/$uuid/activity");
is( $browser->resp_code(), 200, "GET activity json" );
ok( $thing = json_decode($json, true), "json decode get activity" );
validate_json($thing, 'activity'); // 3 tests

// tags json
$json = $browser->http_get("/source/$uuid/tag");
is( $browser->resp_code(), 200, "GET tags json" );
ok( $thing = json_decode($json, true), "json decode get tags" );
validate_json($thing, 'tags'); // 3 tests


////////////////////////////
// create a Source through the controller
$o = new TestOrganization();
$o->save();

$testemail = 'TestSource022@test.com';
$lc_email = strtolower($testemail);
$del = "delete from source where src_username = '$testemail'";
$conn->exec($del);

$post = array(
    'sem_email'      => $testemail,
    'src_first_name' => 'Harold',
    'src_last_name'  => 'Blah',
    'org_uuid'       => $o->org_uuid,
);
$data = array('radix' => json_encode($post));

ok( $resp = $browser->http_post("/source", $data), "POST - response" );
is( $browser->resp_code(), 200, "POST - code" );
ok( $json = json_decode($resp, true), "POST - decode" );
is( $json['success'], true, "POST - success" );

$radix = isset($json['radix']) ? $json['radix'] : array();
is( $radix['src_username'], $testemail, 'POST - src_username' );
isnt( $radix['src_username'], $lc_email, 'POST - not lowercase src_username' );
is( $radix['src_first_name'], $post['src_first_name'], 'POST - src_first_name' );
is( $radix['src_last_name'], $post['src_last_name'], 'POST - src_last_name' );
is( $radix['SrcEmail'][0]['sem_email'], $lc_email, 'POST - sem_email lowercase' );

// src_status hook on sem_email
$uuid = $radix['src_uuid'];
$sem_uuid = $radix['SrcEmail'][0]['sem_uuid'];
$src = AIR2_Record::find('Source', $uuid);
is( $radix['src_status'], Source::$STATUS_ENROLLED, 'src_status' );
is( $src->src_status, Source::$STATUS_ENROLLED, 'rec src_status' );
ok( $resp = $browser->http_get("/source/$uuid/email/$sem_uuid"), "GET email" );
is( $browser->resp_code(), 200, "GET email - code" );

$put = array(
    'sem_status' => SrcEmail::$STATUS_CONFIRMED_BAD,
);
$data = array('radix' => json_encode($put));
ok( $resp = $browser->http_put("/source/$uuid/email/$sem_uuid", $data), "PUT email" );
is( $browser->resp_code(), 200, "PUT email - code" );
ok( $json = json_decode($resp, true), "PUT email - decode" );
is( $json['success'], true, "PUT email - success" );

// check src_status
$src->refresh();
is( $src->src_status, Source::$STATUS_NO_PRIMARY_EMAIL, 'no primary email' );

// cleanup
$conn->exec($del);
