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

require_once 'app/init.php';
require_once 'rframe/AIRAPI.php';
$tdir = APPPATH.'../tests';
require_once "$tdir/Test.php";
require_once "$tdir/AirHttpTest.php";
require_once "$tdir/models/TestUser.php";
require_once "$tdir/models/TestOrganization.php";
require_once "$tdir/models/TestTank.php";
require_once "$tdir/models/TestBin.php";
require_once "$tdir/models/TestSource.php";


/**********************
 * Init
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$u = new TestUser();
$u->save();
$api = new AIRAPI($u);

$browser = new AirHttpTest();
$browser->set_test_user();
$browser->set_content_type(AirHttpTest::$JSON); // set to json

function get_search_total($i, $q) {
    global $browser;
    ok( $resp = $browser->http_get("/search?i=$i&q=$q&c=1"), 'setup - get total' );
    is( $browser->resp_code(), 200, 'setup - resp 200' );
    ok( $json = json_decode($resp, true), 'setup - json decode' );
    $total = isset($json['total']) ? $json['total'] : -1;
    ok( $total > 0, "setup - search has total $total" );
    return $total;
}


/**********************
 * Setup test data
 */
$o = new TestOrganization();
$o->add_users(array($u), AdminRole::READER);
$o->save();

$bin = new TestBin();
$bin->bin_user_id = $u->user_id;
$bin->save();
$uuid = $bin->bin_uuid;


plan(11);

/**********************
 * add a fairly large search to a bin ... this tends to fail if your database
 * isn't in-sync with the search indexes (invalid will be > 0)
 */
$query = 'test';
$total = get_search_total('sources', $query);
$params = array('q' => $query, 'i' => 'sources', 'total' => $total);

$rs = $api->update("bin/$uuid", array('bulk_addsearch' => $params));
is( $rs['code'], AIRAPI::OKAY, 'add big - okay' );
is( $rs['radix']['src_count'],           $total, "add big - $total sources" );
is( $rs['radix']['subm_count'],          0,      "add big - 0 submissions" );
is( $rs['meta']['bulk_rs']['total'],     $total, "add big - $total total" );
is( $rs['meta']['bulk_rs']['insert'],    $total, "add big - $total inserted" );
is( $rs['meta']['bulk_rs']['duplicate'], 0,      "add big - 0 duplicate" );
is( $rs['meta']['bulk_rs']['invalid'],   0,      "add big - 0 invalid" );
