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

$p = new TestProject();
$p->add_orgs(array($o));
$p->save();

$inq = new TestInquiry();
$inq->add_projects(array($p));
$inq->save();

$bin = new TestBin();
$bin->bin_user_id = $u->user_id;
$bin->save();
$uuid = $bin->bin_uuid;

$sources = array();
$sids = array();
for ($i=0; $i<10; $i++) {
    $sources[$i] = new TestSource();
    $sources[$i]->add_orgs(array($o));
    $sources[$i]->save();
    $sids[$i] = $sources[$i]->src_uuid;
}


plan(32);

/**********************
 * Initial values
 */
$rs = $api->fetch("bin/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'fetch - okay' );
is( $rs['radix']['bin_uuid'],   $uuid, 'fetch - uuid' );
is( $rs['radix']['src_count'],  0, 'fetch - src_count' );
ok( $rs['authz']['may_read'],   'fetch - may_read' );
ok( $rs['authz']['may_write'],  'fetch - may_write' );
ok( $rs['authz']['may_manage'], 'fetch - may_manage' );

$rs = $api->query("bin/$uuid/source");
is( $rs['code'], AIRAPI::OKAY, 'query sources - okay' );
is( count($rs['radix']), 0, 'query sources - count' );


/**********************
 * Add unnoted source
 */
$rs = $api->update("bin/$uuid", array('bulk_add' => array($sids[0])));
is( $rs['code'], AIRAPI::OKAY, 'bulk_add unnoted - okay' );
is( $rs['radix']['src_count'], 1, 'bulk_add unnoted - src_count' );

$rs = $api->fetch("bin/$uuid/source/{$sids[0]}");
is( $rs['code'], AIRAPI::OKAY, 'fetch unnoted - okay' );
is( $rs['radix']['src_uuid'], $sids[0], 'fetch unnoted - uuid' );
ok( array_key_exists('bsrc_notes', $rs['radix']), 'fetch unnoted - has notes' );
is( $rs['radix']['bsrc_notes'], null, 'fetch unnoted - null notes' );


/**********************
 * Add noted sources
 */
$rs = $api->update("bin/$uuid", array('bulk_add' => array($sids[1], $sids[2]), 'bulk_add_notes' => 'foobar'));
is( $rs['code'], AIRAPI::OKAY, 'bulk_add noted - okay' );
is( $rs['radix']['src_count'], 3, 'bulk_add noted - src_count' );

$rs = $api->fetch("bin/$uuid/source/{$sids[1]}");
is( $rs['code'], AIRAPI::OKAY, 'fetch noted 1 - okay' );
is( $rs['radix']['bsrc_notes'], 'foobar', 'fetch noted 1 - notes' );

$rs = $api->fetch("bin/$uuid/source/{$sids[2]}");
is( $rs['code'], AIRAPI::OKAY, 'fetch noted 2 - okay' );
is( $rs['radix']['bsrc_notes'], 'foobar', 'fetch noted 2 - notes' );


/**********************
 * Add overlap notes
 */
$rs = $api->update("bin/$uuid", array('bulk_add' => array($sids[2], $sids[3], $sids[4]), 'bulk_add_notes' => 'purple the color'));
is( $rs['code'], AIRAPI::OKAY, 'bulk_add overlap - okay' );
is( $rs['radix']['src_count'], 5, 'bulk_add overlap - src_count' );

$rs = $api->fetch("bin/$uuid/source/{$sids[2]}");
is( $rs['code'], AIRAPI::OKAY, 'fetch overlap 2 - okay' );
is( $rs['radix']['bsrc_notes'], 'foobar', 'fetch overlap 2 - notes' );

$rs = $api->fetch("bin/$uuid/source/{$sids[3]}");
is( $rs['code'], AIRAPI::OKAY, 'fetch overlap 3 - okay' );
is( $rs['radix']['bsrc_notes'], 'purple the color', 'fetch overlap 3 - notes' );

$rs = $api->fetch("bin/$uuid/source/{$sids[4]}");
is( $rs['code'], AIRAPI::OKAY, 'fetch overlap 4 - okay' );
is( $rs['radix']['bsrc_notes'], 'purple the color', 'fetch overlap 4 - notes' );


/**********************
 * Add notes while adding submission
 */
$srs = new SrcResponseSet();
$srs->Source = $sources[5];
$srs->Inquiry = $inq;
$srs->srs_date = air2_date();
$srs->save();

$rs = $api->update("bin/$uuid", array('bulk_addsub' => $srs->srs_uuid, 'bulk_add_notes' => 'rooftop'));
is( $rs['code'], AIRAPI::OKAY, 'bulk_add submission - okay' );
is( $rs['radix']['src_count'], 6, 'bulk_add submission - src_count' );

$rs = $api->fetch("bin/$uuid/source/{$sids[5]}");
is( $rs['code'], AIRAPI::OKAY, 'fetch submission 5 - okay' );
is( $rs['radix']['bsrc_notes'], 'rooftop', 'fetch submission 5 - notes' );
