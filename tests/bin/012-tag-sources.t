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
require_once "$tdir/models/TestUser.php";
require_once "$tdir/models/TestOrganization.php";
require_once "$tdir/models/TestProject.php";
require_once "$tdir/models/TestInquiry.php";
require_once "$tdir/models/TestBin.php";
require_once "$tdir/models/TestSource.php";
require_once "$tdir/models/TestTagMaster.php";


/**********************
 * Init
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$u = new TestUser();
$u->save();
$api = new AIRAPI($u);


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

$sources = array();
$sids = array();
for ($i=0; $i<25; $i++) {
    $sources[$i] = new TestSource();
    if ($i < 20) $sources[$i]->add_orgs(array($o));
    $sources[$i]->save();
    $sids[$i] = $sources[$i]->src_uuid;
}

$tm1 = new TestTagMaster();
$tm1->save();
$t1 = $tm1->tm_name;
$tm2 = new TestTagMaster();
$tm2->save();
$t2 = $tm2->tm_name;
$tm3 = new TestTagMaster();
$tm3->save();
$t3 = $tm3->tm_name;


plan(28);

/**********************
 * 2-ops concurrent
 */
$add_uuids = array_slice($sids, 0, 15);
$rs = $api->update("bin/$uuid", array('bulk_add' => $add_uuids, 'bulk_tag' => $t1));
is( $rs['code'], AIRAPI::BAD_DATA, 'bulk_tag 2-ops - failed' );
like( $rs['message'], '/cannot run/i', 'bulk_tag 2-ops - message' );

$rs = $api->update("bin/$uuid", array('bulk_add' => $add_uuids));
is( $rs['code'], AIRAPI::OKAY, 'bulk_tag add - okay' );
is( $rs['radix']['src_count'], 15, 'bulk_tag add - src_count' );


/**********************
 * Invalid tag
 */
$rs = $api->update("bin/$uuid", array('bulk_tag' => 'this,is-bad&tag'));
is( $rs['code'], AIRAPI::BAD_DATA, 'bulk_tag invalid - bad data' );
like( $rs['message'], '/invalid character/i', 'bulk_tag invalid - message' );


/**********************
 * Tag 1
 */
$rs = $api->update("bin/$uuid", array('bulk_tag' => $t1));
is( $rs['code'], AIRAPI::OKAY, 'tag1 - okay' );
is( $rs['meta']['bulk_rs']['total'],     15, 'tag1 - total' );
is( $rs['meta']['bulk_rs']['insert'],    15, 'tag1 - inserted' );
is( $rs['meta']['bulk_rs']['duplicate'], 0,  'tag1 - duplicates' );
is( $rs['meta']['bulk_rs']['invalid'],   0,  'tag1 - invalid' );

$rs = $api->query("source/{$sids[0]}/tag");
is( $rs['code'], AIRAPI::OKAY, 'tag1 - check tags - okay' );
is( count($rs['radix']), 1, 'tag1 - check tags - radix count' );
is( $rs['radix'][0]['tm_name'], $t1, 'tag1 - check tags - tag name' );


/**********************
 * Tag 2 - overlap
 */
$add_uuids = array_slice($sids, 15, 5);
$rs = $api->update("bin/$uuid", array('bulk_add' => $add_uuids));
is( $rs['code'], AIRAPI::OKAY, 'bulk_tag add2 - okay' );
is( $rs['radix']['src_count'], 20, 'bulk_tag add2 - src_count' );

$rs = $api->update("bin/$uuid", array('bulk_tag' => $t1));
is( $rs['code'], AIRAPI::OKAY, 'tag2 - okay' );
is( $rs['meta']['bulk_rs']['total'],     20, 'tag2 - total' );
is( $rs['meta']['bulk_rs']['insert'],    5,  'tag2 - inserted' );
is( $rs['meta']['bulk_rs']['duplicate'], 15, 'tag2 - duplicates' );
is( $rs['meta']['bulk_rs']['invalid'],   0,  'tag2 - invalid' );


/**********************
 * Tag 3 - invalid
 */
$add_uuids = array_slice($sids, 20, 5);
$rs = $api->update("bin/$uuid", array('bulk_add' => $add_uuids));
is( $rs['code'], AIRAPI::OKAY, 'bulk_tag add3 - okay' );
is( $rs['radix']['src_count'], 25, 'bulk_tag add3 - src_count' );

$rs = $api->update("bin/$uuid", array('bulk_tag' => $t2));
is( $rs['code'], AIRAPI::OKAY, 'tag3 - okay' );
is( $rs['meta']['bulk_rs']['total'],     25, 'tag3 - total' );
is( $rs['meta']['bulk_rs']['insert'],    20, 'tag3 - inserted' );
is( $rs['meta']['bulk_rs']['duplicate'], 0,  'tag3 - duplicates' );
is( $rs['meta']['bulk_rs']['invalid'],   5,  'tag3 - invalid' );
