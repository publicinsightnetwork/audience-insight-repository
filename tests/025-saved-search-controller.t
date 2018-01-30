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

plan(16);

define('MY_SSEARCH_UUID', 'myuuid123456');

// clean up any previous run
AIR2_DBManager::init();
$query = new AIR2_Query();
$query->from('SavedSearch');
$query->where('ssearch_uuid=?', MY_SSEARCH_UUID);
$ssearch = $query->fetchOne();
if ($ssearch && $ssearch->exists()) {
    diag("found existing ssearch");
    ok($ssearch->delete(), "delete old record");
}
else {
    pass("no old record");
}

// init
$browser = new AirHttpTest();
$browser->set_content_type(AirHttpTest::$JSON);
$browser->set_test_user();

/**********************
 * create via POST
 */
$test_ssearch = array(
    'ssearch_uuid' => MY_SSEARCH_UUID,
    'ssearch_name' => 'my test ssearch',
    'ssearch_params' => '{"idx":"sources","params":"q=test"}',
);
ok( $resp = $browser->http_post(
        '/savedsearch.json',
        array( 'radix' => json_encode($test_ssearch) )
    ),
    "POST new saved search");
//diag_dump( $resp );
ok( $posted = json_decode($resp), "JSON decode POST");
is( $posted->success, true, "POST success");
is( $posted->radix->ssearch_uuid, $test_ssearch['ssearch_uuid'],
    "POST returns original value");

/**********************
 * list via GET
 */
ok( $resp = $browser->http_get('/savedsearch.json?limit=0'),
    "GET list of crud");
//diag_dump( $resp );
ok( $ssearch_list = json_decode($resp), "JSON decode GET list");
foreach ($ssearch_list->radix as $ssearch) {
    //diag_dump( $ssearch );
    if ($ssearch->ssearch_uuid == MY_SSEARCH_UUID) {
        pass("created, in list");
        //diag_dump( $ssearch );
    }
}

// test authz
define('MY_TEST_PASS', 'fooBar123.');

// create a test user
$user = new TestUser();
$user->user_encrypted_password = MY_TEST_PASS;
$user->save();
$browser2 = new AirHttpTest();
$browser2->set_content_type(AirHttpTest::$JSON);
$browser2->set_user($user);

//diag_dump($browser->cookies);
//diag_dump($browser2->cookies);

ok( $resp = $browser2->http_get('/savedsearch/' . MY_SSEARCH_UUID),
    "GET ssearch as temp user");
is( $browser2->resp_code(), 403, "temp user GETs 403");
//diag_dump( json_decode($resp) );

ok( $resp = $browser->http_get('/savedsearch/' . MY_SSEARCH_UUID),
    "GET ssearch as owner");
is( $browser->resp_code(), 200, "owner GETs 200");

ok( $resp = $browser2->http_delete('/savedsearch/' . MY_SSEARCH_UUID),
    "DELETE as temp user");
is( $browser2->resp_code(), 403, "no authz to DELETE since cannot view record");
//diag_dump( json_decode($resp) );

// then with the original user
ok( $resp = $browser->http_delete('/savedsearch/' . MY_SSEARCH_UUID),
    "DELETE as owner");
is( $browser->resp_code(), 200, "authz ok to DELETE");
//diag_dump( json_decode($resp) );

