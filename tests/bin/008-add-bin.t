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

$bin2 = new TestBin();
$bin2->bin_user_id = 1;
$bin2->bin_shared_flag = true;
$bin2->save();
$uuid2 = $bin2->bin_uuid;

$bin3 = new TestBin();
$bin3->bin_user_id = 1;
$bin3->bin_shared_flag = true;
$bin3->save();
$uuid3 = $bin3->bin_uuid;

$bin4 = new TestBin();
$bin4->bin_user_id = 1;
$bin4->bin_shared_flag = true;
$bin4->save();
$uuid4 = $bin4->bin_uuid;

$sids = array();
for ($i=0; $i<25; $i++) {
    $src = new TestSource();
    $src->add_orgs(array($o));
    $src->save();
    $subm = new SrcResponseSet();
    $subm->Source = $src;
    $subm->Inquiry = $inq;
    $subm->srs_date = air2_date();
    $subm->save();
    $sids[$i] = $src->src_uuid;
    if ($i < 10) {
        $bin2->BinSource[]->bsrc_src_id = $src->src_id;
        $bsrs = new BinSrcResponseSet();
        $bsrs->bsrs_src_id = $subm->srs_src_id;
        $bsrs->bsrs_srs_id = $subm->srs_id;
        $bsrs->bsrs_inq_id = $subm->srs_inq_id;
        $bin2->BinSrcResponseSet[] = $bsrs;
    }
    if (7 < $i && $i < 20) {
        $bin3->BinSource[]->bsrc_src_id = $src->src_id;
        $bsrs = new BinSrcResponseSet();
        $bsrs->bsrs_src_id = $subm->srs_src_id;
        $bsrs->bsrs_srs_id = $subm->srs_id;
        $bsrs->bsrs_inq_id = $subm->srs_inq_id;
        $bin3->BinSrcResponseSet[] = $bsrs;
    }
    if (14 < $i && $i < 25) {
        $bin4->BinSource[]->bsrc_src_id = $src->src_id;
        $bsrs = new BinSrcResponseSet();
        $bsrs->bsrs_src_id = $subm->srs_src_id;
        $bsrs->bsrs_srs_id = $subm->srs_id;
        $bsrs->bsrs_inq_id = $subm->srs_inq_id;
        $bin4->BinSrcResponseSet[] = $bsrs;
    }

}
$bin2->save();
$bin3->save();
$bin4->save();


plan(24);

/**********************
 * Initial counts
 */
$rs = $api->fetch("bin/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'init1 - okay' );
is( $rs['radix']['src_count'], 0, 'init1 - 0 sources' );
is( $rs['radix']['subm_count'], 0, 'init1 - 0 submissions' );

$rs = $api->fetch("bin/$uuid2");
is( $rs['code'], AIRAPI::OKAY, 'init2 - okay' );
is( $rs['radix']['src_count'], 10, 'init2 - 10 sources' );
is( $rs['radix']['subm_count'], 10, 'init2 - 10 submissions' );

$rs = $api->fetch("bin/$uuid3");
is( $rs['code'], AIRAPI::OKAY, 'init3 - okay' );
is( $rs['radix']['src_count'], 12, 'init3 - 12 sources' );
is( $rs['radix']['subm_count'], 12, 'init3 - 12 submissions' );

$rs = $api->fetch("bin/$uuid4");
is( $rs['code'], AIRAPI::OKAY, 'init4 - okay' );
is( $rs['radix']['src_count'], 10, 'init4 - 10 sources' );
is( $rs['radix']['subm_count'], 10, 'init4 - 10 submissions' );


/**********************
 * bulk_addbin
 */
$rs = $api->update("bin/$uuid", array('bulk_addbin' => $bin2->bin_uuid));
is( $rs['code'], AIRAPI::OKAY, 'add1 - okay' );
is( $rs['radix']['src_count'], 10, 'add1 - 10 sources' );
is( $rs['radix']['subm_count'], 10, 'add1 - 10 submissions' );
is( $rs['meta']['bulk_rs']['insert'], 10, 'add1 - 10 inserted' );
is( $rs['meta']['bulk_rs']['total'],  10, 'add1 - 10 total' );


/**********************
 * add the other 2
 */
$add_em = array($bin3->bin_uuid, $bin4->bin_uuid);
$rs = $api->update("bin/$uuid", array('bulk_addbin' => $add_em));
is( $rs['code'], AIRAPI::OKAY, 'add2 - okay' );
is( $rs['radix']['src_count'], 25, 'add2 - 25 sources' );
is( $rs['radix']['subm_count'], 25, 'add2 - 25 submissions' );
is( $rs['meta']['bulk_rs']['total'],     22, 'add2 - 22 total' );
is( $rs['meta']['bulk_rs']['insert'],    15, 'add2 - 15 inserted' );
is( $rs['meta']['bulk_rs']['duplicate'], 7,  'add2 - 7 duplicate' );
is( $rs['meta']['bulk_rs']['invalid'],   0,  'add2 - 0 invalid' );
