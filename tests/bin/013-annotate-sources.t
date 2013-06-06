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
$o1 = new TestOrganization();
$o1->add_users(array($u), AdminRole::WRITER);
$o1->save();
$o2 = new TestOrganization();
$o2->add_users(array($u), AdminRole::READER);
$o2->save();

$bin = new TestBin();
$bin->bin_user_id = $u->user_id;
$bin->save();
$uuid = $bin->bin_uuid;

$sources = array();
$sids = array();
for ($i=0; $i<25; $i++) {
    $sources[$i] = new TestSource();
    if ($i < 10) $sources[$i]->add_orgs(array($o1));
    if ($i < 20) $sources[$i]->add_orgs(array($o2));
    $sources[$i]->save();
    $sids[$i] = $sources[$i]->src_uuid;
}


plan(14);

/**********************
 * Setup bin
 */
$rs = $api->update("bin/$uuid", array('bulk_add' => $sids));
is( $rs['code'], AIRAPI::OKAY, 'setup - okay' );
is( $rs['radix']['src_count'],            25, 'setup - src_count' );
is( $rs['radix']['counts']['src_read'],   20, 'setup - src_read' );
is( $rs['radix']['counts']['src_update'], 10, 'setup - src_update' );


/**********************
 * Invalid annotation
 */
$rs = $api->update("bin/$uuid", array('bulk_annot' => '   '));
is( $rs['code'], AIRAPI::BAD_DATA, 'bulk_annotate invalid - bad data' );
like( $rs['message'], '/invalid annotation/i', 'bulk_annotate invalid - message' );


/**********************
 * Annotate 1
 */
$rs = $api->update("bin/$uuid", array('bulk_annot' => 'blah blah blah'));
is( $rs['code'], AIRAPI::OKAY, 'annot1 - okay' );
is( $rs['meta']['bulk_rs']['total'],     25, 'annot1 - total' );
is( $rs['meta']['bulk_rs']['insert'],    10, 'annot1 - inserted' );
is( $rs['meta']['bulk_rs']['duplicate'], 0,  'annot1 - duplicates' );
is( $rs['meta']['bulk_rs']['invalid'],   15, 'annot1 - invalid' );

$rs = $api->query("source/{$sids[0]}/annotation");
is( $rs['code'], AIRAPI::OKAY, 'annot1 - check annotations - okay' );
is( count($rs['radix']), 1, 'annot1 - check annotations - radix count' );
is( $rs['radix'][0]['srcan_value'], 'blah blah blah', 'annot1 - check annotations - value' );
