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
    $sources[$i]->add_orgs(array($o));
    $sources[$i]->save();
    $sids[$i] = $sources[$i]->src_uuid;
}


plan(18);

/**********************
 * Initial count
 */
$rs = $api->fetch("bin/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'init - okay' );
is( $rs['radix']['src_count'], 0, 'init - 0 sources' );


/**********************
 * bulk_add
 */
$adds = array($sids[0], $sids[1], $sids[2], $sids[3], $sids[4]);
$rs = $api->update("bin/$uuid", array('bulk_add' => $adds));
is( $rs['code'], AIRAPI::OKAY, 'add1 - okay' );
is( $rs['radix']['src_count'], 5, 'add1 - 5 sources' );
is( $rs['meta']['bulk_rs']['insert'], 5, 'add1 - 5 inserted' );

$adds = array($sids[3], $sids[4], $sids[5],  $sids[6], 'blahblahblah', $sids[6], $sids[3]);
$rs = $api->update("bin/$uuid", array('bulk_add' => $adds));
is( $rs['code'], AIRAPI::OKAY, 'add2 - okay' );
is( $rs['radix']['src_count'], 7, 'add2 - 7 sources' );
is( $rs['meta']['bulk_rs']['insert'], 2, 'add2 - 2 inserted' );
is( $rs['meta']['bulk_rs']['duplicate'], 4, 'add2 - 4 duplicates' );
is( $rs['meta']['bulk_rs']['invalid'], 1, 'add2 - 1 invalid' );


/**********************
 * bulk_remove, bulk_removeall
 */
$rem = array($sids[0], $sids[1], $sids[2]);
$rs = $api->update("bin/$uuid", array('bulk_remove' => $rem));
is( $rs['code'], AIRAPI::OKAY, 'remove1 - okay' );
is( $rs['radix']['src_count'], 4, 'remove1 - 4 sources' );

$rem = array($sids[1], $sids[3], 'blahblahblah');
$rs = $api->update("bin/$uuid", array('bulk_remove' => $rem));
is( $rs['code'], AIRAPI::OKAY, 'remove2 - okay' );
is( $rs['radix']['src_count'], 3, 'remove2 - 3 sources' );

$rem = array($sids[1], $sids[4], 'blahblahblah');
$rs = $api->update("bin/$uuid", array('bulk_removeall' => $rem));
is( $rs['code'], AIRAPI::OKAY, 'removeall1 - okay' );
is( $rs['radix']['src_count'], 1, 'removeall1 - 1 sources' );

$rs = $api->update("bin/$uuid", array('bulk_removeall' => true));
is( $rs['code'], AIRAPI::OKAY, 'removeall2 - okay' );
is( $rs['radix']['src_count'], 0, 'removeall2 - 0 sources' );
