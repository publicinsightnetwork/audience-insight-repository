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

$bin = new TestBin();
$bin->bin_user_id = $u->user_id;
$bin->save();
$uuid = $bin->bin_uuid;

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

$sources = array();
$ids = array();
for ($i=0; $i<10; $i++) {
    $src = new TestSource();
    $src->add_orgs(array($o));
    $src->save();
    $sources[$i] = $src;
    $subm1 = new SrcResponseSet();
    $subm1->Source = $src;
    $subm1->Inquiry = $inq;
    $subm1->srs_date = air2_date();
    $subm1->save();
    $ids[] = $subm1->srs_uuid;
    $subm2 = new SrcResponseSet();
    $subm2->Source = $src;
    $subm2->Inquiry = $inq;
    $subm2->srs_date = air2_date();
    $subm2->save();
    $ids[] = $subm2->srs_uuid;
}


plan(16);

/**********************
 * Initial count
 */
$rs = $api->fetch("bin/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'init - okay' );
is( $rs['radix']['src_count'], 0, 'init - 0 sources' );
is( $rs['radix']['subm_count'], 0, 'init - 0 submissions' );


/**********************
 * bulk_add
 */
$adds = array($ids[0], $ids[1], $ids[2], $ids[3], $ids[4]);
$rs = $api->update("bin/$uuid", array('bulk_addsub' => $adds));
is( $rs['code'], AIRAPI::OKAY, 'add1 - okay' );
is( $rs['radix']['src_count'], 3, 'add1 - 3 sources' );
is( $rs['radix']['subm_count'], 5, 'add1 - 5 submissions' );
is( $rs['meta']['bulk_rs']['insert'], 5, 'add1 - 5 inserted' );

$adds = array($ids[3], $ids[4], $ids[5],  $ids[6], 'blahblahblah', $ids[6], $ids[3]);
$rs = $api->update("bin/$uuid", array('bulk_addsub' => $adds));
is( $rs['code'], AIRAPI::OKAY, 'add2 - okay' );
is( $rs['radix']['src_count'], 4, 'add2 - 4 sources' );
is( $rs['radix']['subm_count'], 7, 'add2 - 7 submissions' );
is( $rs['meta']['bulk_rs']['insert'], 2, 'add2 - 2 inserted' );
is( $rs['meta']['bulk_rs']['duplicate'], 4, 'add2 - 4 duplicates' );
is( $rs['meta']['bulk_rs']['invalid'], 1, 'add2 - 1 invalid' );


/**********************
 * remove a source
 */
$rem = array($sources[0]->src_uuid);
$rs = $api->update("bin/$uuid", array('bulk_remove' => $rem));
is( $rs['code'], AIRAPI::OKAY, 'remove1 - okay' );
is( $rs['radix']['src_count'], 3, 'remove1 - 3 sources' );
is( $rs['radix']['subm_count'], 5, 'remove1 - 5 submissions' );
