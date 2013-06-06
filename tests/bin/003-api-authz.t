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
$o->add_users(array($u), AdminRole::WRITER);
$o->save();

$p = new TestProject();
$p->add_orgs(array($o));
$p->save();

$i = new TestInquiry();
$i->add_projects(array($p));
$i->save();
$i_na = new TestInquiry();
$i_na->save();

$s1 = new TestSource();
$s1->save();
$s2 = new TestSource();
$s2->add_orgs(array($o));
$s2->save();
$s3 = new TestSource();
$s3->save();

$r1 = new SrcResponseSet();
$r1->Source = $s1;
$r1->Inquiry = $i;
$r1->srs_date = air2_date();
$r1->save();

$r2_na = new SrcResponseSet();
$r2_na->Source = $s1;
$r2_na->Inquiry = $i_na;
$r2_na->srs_date = air2_date();
$r2_na->save();

$r3_not_in_bin = new SrcResponseSet();
$r3_not_in_bin->Source = $s1;
$r3_not_in_bin->Inquiry = $i;
$r3_not_in_bin->srs_date = air2_date();
$r3_not_in_bin->save();

$r4_also_not_in_bin = new SrcResponseSet();
$r4_also_not_in_bin->Source = $s3;
$r4_also_not_in_bin->Inquiry = $i;
$r4_also_not_in_bin->srs_date = air2_date();
$r4_also_not_in_bin->save();

// add to bin
$bin = new TestBin();
$bin->bin_user_id = $u->user_id;
$bin->save();
$uuid = $bin->bin_uuid;

$bin->BinSource[0]->bsrc_src_id = $s1->src_id;
$bin->BinSource[1]->bsrc_src_id = $s2->src_id;
$bin->BinSource[2]->bsrc_src_id = $s3->src_id;
$bin->BinSrcResponseSet[0]->bsrs_srs_id = $r1->srs_id;
$bin->BinSrcResponseSet[0]->bsrs_inq_id = $r1->srs_inq_id;
$bin->BinSrcResponseSet[0]->bsrs_src_id = $r1->srs_src_id;
$bin->BinSrcResponseSet[1]->bsrs_srs_id = $r2_na->srs_id;
$bin->BinSrcResponseSet[1]->bsrs_inq_id = $r2_na->srs_inq_id;
$bin->BinSrcResponseSet[1]->bsrs_src_id = $r2_na->srs_src_id;
$bin->save();


plan(22);

/**********************
 * Initial Check
 */
$rs = $api->fetch("bin/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'fetch - okay' );
is( $rs['radix']['src_count'], 3, 'fetch - src_count' );
is( $rs['radix']['subm_count'], 2, 'fetch - subm_count' );


/**********************
 * Query bin sources
 */
$rs = $api->query("bin/$uuid/source");
is( $rs['code'], AIRAPI::OKAY, 'query sources - okay' );
is( count($rs['radix']), 2, 'query sources - count' );

$src_uuids = array();
foreach ($rs['radix'] as $row) {
    $src_uuids[$row['src_uuid']] = $row['subm_count'];
}
ok( isset($src_uuids[$s1->src_uuid]),  'query sources - s1 present' );
ok( isset($src_uuids[$s2->src_uuid]),  'query sources - s2 present' );
ok( !isset($src_uuids[$s3->src_uuid]), 'query sources - s3 not present' );
is( $src_uuids[$s1->src_uuid], 2, 'query sources - s1 2-subm' );
is( $src_uuids[$s2->src_uuid], 0, 'query sources - s2 0-subm' );


/**********************
 * Query bin submissions
 */
$rs = $api->query("bin/$uuid/srcsub");
is( $rs['code'], AIRAPI::OKAY, 'query submissions - okay' );
is( count($rs['radix']), 2, 'query submissions - count' );

$src_uuids = array();
$srs_uuids = array();
foreach ($rs['radix'] as $row) {
    $src_uuids[$row['src_uuid']] = $row;
    foreach ($row['SrcResponseSet'] as $srsrow) {
        $srs_uuids[$srsrow['srs_uuid']] = $srsrow;
    }
}
ok( isset($src_uuids[$s1->src_uuid]),  'query submissions - s1 present' );
ok( isset($src_uuids[$s2->src_uuid]),  'query submissions - s2 present' );
ok( !isset($src_uuids[$s3->src_uuid]), 'query submissions - s3 not present' );
is( $src_uuids[$s1->src_uuid]['subm_count'], 2, 'query submissions - s1 2-subm' );
is( $src_uuids[$s2->src_uuid]['subm_count'], 0, 'query submissions - s2 0-subm' );

// should only actually have 1 submission (that we have authz for)
is( count($src_uuids[$s1->src_uuid]['SrcResponseSet']), 1, 'query submissions - s1 1-subm with authz' );

// check that we got the right submission back
ok( isset($srs_uuids[$r1->srs_uuid]),                  'query submissions - r1 present' );
ok( !isset($srs_uuids[$r2_na->srs_uuid]),              'query submissions - r2 not present' );
ok( !isset($srs_uuids[$r3_not_in_bin->srs_uuid]),      'query submissions - r3 not present' );
ok( !isset($srs_uuids[$r4_also_not_in_bin->srs_uuid]), 'query submissions - r4 not present' );
