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
    ok( $resp = $browser->http_get("search?i=$i&q=$q&c=1"), 'setup - get total' );
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


plan(33);

/**********************
 * adding a source search to a bin
 */
$query = 'oil spill';
$total = get_search_total('fuzzy-sources', $query);
$params = array('q' => $query, 'i' => 'fuzzy-sources', 'total' => $total);

$rs = $api->update("bin/$uuid", array('bulk_addsearch' => $params));
is( $rs['code'], AIRAPI::OKAY, 'add1 - okay' );
is( $rs['radix']['src_count'],           $total, "add1 - $total sources" );
is( $rs['radix']['subm_count'],          0,      "add1 - 0 submissions" );
is( $rs['meta']['bulk_rs']['total'],     $total, "add1 - $total total" );
is( $rs['meta']['bulk_rs']['insert'],    $total, "add1 - $total inserted" );
is( $rs['meta']['bulk_rs']['duplicate'], 0,      "add1 - 0 duplicate" );
is( $rs['meta']['bulk_rs']['invalid'],   0,      "add1 - 0 invalid" );


/**********************
 * add with some overlap
 */
$query = 'oil gulf';
$total2 = get_search_total('fuzzy-sources', $query);
$params = array('q' => $query, 'i' => 'fuzzy-sources', 'total' => $total2);
$grand = $total + $total2;

$rs = $api->update("bin/$uuid", array('bulk_addsearch' => $params));
is( $rs['code'], AIRAPI::OKAY, 'add2 - okay' );
ok( $rs['radix']['src_count'] < $grand,         "add2 - < $grand sources" );
is( $rs['radix']['subm_count'], 0,              "add2 - 0 submissions" );
is( $rs['meta']['bulk_rs']['total'], $total2,   "add2 - $total2 total" );
ok( $rs['meta']['bulk_rs']['insert'] < $total2, "add2 - < $total2 inserted" );
ok( $rs['meta']['bulk_rs']['duplicate'] > 0,    "add2 - > 0 duplicate" );
is( $rs['meta']['bulk_rs']['invalid'], 0,       "add2 - 0 invalid" );

$last_src_count = $rs['radix']['src_count'];


/**********************
 * add responses search
 */
$query = 'oil gulf';
$total3 = get_search_total('fuzzy-responses', $query);
$params = array('q' => $query, 'i' => 'fuzzy-responses', 'total' => $total3);

$rs = $api->update("bin/$uuid", array('bulk_addsearch' => $params));
//diag_dump($rs);
is( $rs['code'], AIRAPI::OKAY, 'add3 - okay' );
is( $rs['radix']['src_count'],   $last_src_count, "add3 - src_count stayed the same" );
is( $rs['radix']['subm_count'],          $total3, "add3 - $total3 submissions" );
is( $rs['meta']['bulk_rs']['total'],     $total3, "add3 - $total3 total" );
is( $rs['meta']['bulk_rs']['insert'],    $total3, "add3 - $total3 inserted" );
is( $rs['meta']['bulk_rs']['duplicate'], 0,       "add3 - 0 duplicate" );
is( $rs['meta']['bulk_rs']['invalid'],   0,       "add3 - 0 invalid" );
