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


plan(83);

/**********************
 * adding a source search to a bin
 */
$query = 'oil spill';
$total = get_search_total('fuzzy-sources', $query);
$params = array('q' => $query, 'i' => 'fuzzy-sources', 'total' => $total);
$rs = $api->update("bin/$uuid", array('bulk_addsearch' => $params));

is( $rs['code'], AIRAPI::OKAY, 'setup - okay' );
is( $rs['radix']['src_count'], $total, "setup - $total sources" );


/**********************
 * split into random bins
 */
$num = 4;
$rs = $api->update("bin/$uuid", array('bulk_random' => array('num' => $num)));

is( $rs['code'], AIRAPI::OKAY, 'random1 - okay' );
is( $rs['radix']['src_count'], $total, "random1 - still $total sources" );
is( $rs['meta']['bulk_rs']['total'],     $total, "random1 - $total total" );
is( $rs['meta']['bulk_rs']['insert'],    $total, "random1 - $total inserted" );
is( $rs['meta']['bulk_rs']['duplicate'], 0,      "random1 - 0 duplicate" );
is( $rs['meta']['bulk_rs']['invalid'],   0,      "random1 - 0 invalid" );

ok( isset($rs['meta']['bulk_rs']['bin_uuids']), "random1 - created bins" );
is( count($rs['meta']['bulk_rs']['bin_uuids']), $num, "random1 - created $num bins" );

$bin_uuids = $rs['meta']['bulk_rs']['bin_uuids'];
foreach ($bin_uuids as $idx => $bid) {
    $rs = $api->fetch("bin/$bid");
    is( $rs['code'], AIRAPI::OKAY, "random1 - $idx - okay" );

    // check overlap
    $myself = "select bin_id from bin where bin_uuid = '$bid'";
    $other_rand = "select bin_id from bin where bin_user_id = ? and bin_uuid != '$bid' and bin_id != ?";
    $srcids = "select bsrc_src_id from bin_source where bsrc_bin_id in ($other_rand)";
    $q = "select count(*) from bin_source where bsrc_bin_id = ($myself) and bsrc_src_id in ($srcids)";
    $overlaps = $conn->fetchOne($q, array($u->user_id, $bin->bin_id), 0);
    is( $overlaps, 0, "random1 - $idx - 0 overlaps" );

    // make sure total is nearly a quarter of the first bin total
    $low = floor($total / $num);
    $high = ceil($total / $num);
    ok( $rs['radix']['src_count'] >= $low, "random1 - $idx - total low" );
    ok( $rs['radix']['src_count'] <= $high, "random1 - $idx - total high" );
}

// nuke random before next test
foreach ($bin_uuids as $idx => $bid) {
    $rs = $api->delete("bin/$bid");
}


/**********************
 * single random bin
 */
$size = 200;
$rs = $api->update("bin/$uuid", array('bulk_random' => array('size' => $size)));

is( $rs['code'], AIRAPI::OKAY, 'random2 - okay' );
is( $rs['radix']['src_count'], $total, "random2 - still $total sources" );
is( $rs['meta']['bulk_rs']['total'],     $size, "random2 - $size total" );
is( $rs['meta']['bulk_rs']['insert'],    $size, "random2 - $size inserted" );
is( $rs['meta']['bulk_rs']['duplicate'], 0,     "random2 - 0 duplicate" );
is( $rs['meta']['bulk_rs']['invalid'],   0,     "random2 - 0 invalid" );

ok( isset($rs['meta']['bulk_rs']['bin_uuids']), "random2 - created bins" );
is( count($rs['meta']['bulk_rs']['bin_uuids']), 1, "random2 - created 1 bin" );

$bid = $rs['meta']['bulk_rs']['bin_uuids'][0];
$rs = $api->fetch("bin/$bid");
is( $rs['code'], AIRAPI::OKAY, "random2 - 0 - okay" );
is( $rs['radix']['src_count'], $size, "random2 - 0 - src_count" );

// nuke random before next test
$rs = $api->delete("bin/$bid");


/**********************
 * multiple fixed-size randoms
 */
$num = 11;
$size = 19;
$rs = $api->update("bin/$uuid", array('bulk_random' => array('num' => $num, 'size' => $size)));

is( $rs['code'], AIRAPI::OKAY, 'random3 - okay' );
is( $rs['radix']['src_count'], $total, "random3 - still $total sources" );
is( $rs['meta']['bulk_rs']['total'],     $num*$size, "random3 - total" );
is( $rs['meta']['bulk_rs']['insert'],    $num*$size, "random3 - inserted" );
is( $rs['meta']['bulk_rs']['duplicate'], 0,          "random3 - duplicate" );
is( $rs['meta']['bulk_rs']['invalid'],   0,          "random3 - invalid" );

ok( isset($rs['meta']['bulk_rs']['bin_uuids']), "random3 - created bins" );
is( count($rs['meta']['bulk_rs']['bin_uuids']), $num, "random3 - created $num bins" );

$bin_uuids = $rs['meta']['bulk_rs']['bin_uuids'];
foreach ($bin_uuids as $idx => $bid) {
    $rs = $api->fetch("bin/$bid");
    is( $rs['code'], AIRAPI::OKAY, "random3 - $idx - okay" );
    is( $rs['radix']['src_count'], $size, "random3 - $idx - src_count" );

    // check overlap
    $myself = "select bin_id from bin where bin_uuid = '$bid'";
    $other_rand = "select bin_id from bin where bin_user_id = ? and bin_uuid != '$bid' and bin_id != ?";
    $srcids = "select bsrc_src_id from bin_source where bsrc_bin_id in ($other_rand)";
    $q = "select count(*) from bin_source where bsrc_bin_id = ($myself) and bsrc_src_id in ($srcids)";
    $overlaps = $conn->fetchOne($q, array($u->user_id, $bin->bin_id), 0);
    is( $overlaps, 0, "random3 - $idx - 0 overlaps" );
}


/**********************
 * make some insane requests
 */
$params = array('num' => $total + 1);
$rs = $api->update("bin/$uuid", array('bulk_random' => $params));
is( $rs['code'], AIRAPI::BAD_DATA, 'num too big' );

$params = array('num' => 4, 'size' => floor($total / 3));
$rs = $api->update("bin/$uuid", array('bulk_random' => $params));
is( $rs['code'], AIRAPI::BAD_DATA, 'num * size too big' );
