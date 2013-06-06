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
$o1 = new TestOrganization();
$o1->add_users(array($u), AdminRole::READER);
$o1->save();
$o2 = new TestOrganization();
$o2->add_users(array($u), AdminRole::NOACCESS);
$o2->save();

$p = new TestProject();
$p->add_orgs(array($o1));
$p->save();

$inq = new TestInquiry();
$inq->add_projects(array($p));
$inq->save();

$bin = new TestBin();
$bin->bin_user_id = $u->user_id;
$bin->save();
$uuid = $bin->bin_uuid;


/**********************
 * Setup sources
 */

// READER sources (7)
for ($i=0; $i<7; $i++) {
    $src = new TestSource();
    $src->add_orgs(array($o1));
    $src->save();
    $bin->BinSource[]->bsrc_src_id = $src->src_id;
}

// NOACCESS sources (4)
for ($i=0; $i<4; $i++) {
    $src = new TestSource();
    $src->add_orgs(array($o2));
    $src->save();
    $bin->BinSource[]->bsrc_src_id = $src->src_id;
}

// no org sources (3)
for ($i=0; $i<3; $i++) {
    $src = new TestSource();
    $src->save();
    $bin->BinSource[]->bsrc_src_id = $src->src_id;
}

// submission-accessible sources (2)
for ($i=0; $i<2; $i++) {
    $src = new TestSource();
    $src->save();
    $bin->BinSource[]->bsrc_src_id = $src->src_id;
    $srs = new SrcResponseSet();
    $srs->Source = $src;
    $srs->Inquiry = $inq;
    $srs->srs_date = air2_date();
    $srs->save();
    $bsrs = new BinSrcResponseSet();
    $bsrs->bsrs_srs_id = $srs->srs_id;
    $bsrs->bsrs_inq_id = $srs->srs_inq_id;
    $bsrs->bsrs_src_id = $srs->srs_src_id;
    $bin->BinSrcResponseSet[] = $bsrs;
}
$bin->save();


plan(31);

/**********************
 * Check counts
 */
$rs = $api->fetch("bin/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'counts - okay' );
is( $rs['radix']['src_count'],               16, 'counts - src_count' );
is( $rs['radix']['counts']['src_read'],       7, 'counts - src_read' );
is( $rs['radix']['counts']['src_export_csv'], 7, 'counts - src_update' );

$rs = $api->query("bin/$uuid/source");
is( $rs['code'], AIRAPI::OKAY, 'source - okay' );
is( $rs['meta']['total'], 9, 'source - total' );

$s1_uuid = $rs['radix'][0]['src_uuid'];
$src1 = AIR2_Record::find('Source', $s1_uuid);


/**********************
 * 1) Normal exporter
 */
$rs = $api->query("bin/$uuid/exportsource", array('logging' => 0));
is( $rs['code'], AIRAPI::OKAY, 'expsrc - okay' );
is( count($rs['radix']), 7, 'expsrc - count' );
ok( isset($rs['radix'][0]['City']), 'expsrc - has city' );
ok( !isset($rs['radix'][0]['Household Income Src Map']), 'expsrc - no complex fact' );

$rs = $api->query("bin/$uuid/export");
is( $rs['code'], AIRAPI::OKAY, 'export - okay' );
is( $rs['meta']['total'], 0, 'export - total' );
is( $src1->SrcActivity->count(), 0, 'expsrc - no src_activity' );


/**********************
 * 2) Export with facts
 */
$rs = $api->query("bin/$uuid/exportsource", array('logging' => 0, 'allfacts' => 1));
is( $rs['code'], AIRAPI::OKAY, 'expsrc allfacts - okay' );
is( count($rs['radix']), 7, 'expsrc allfacts - count' );
ok( isset($rs['radix'][0]['City']), 'expsrc allfacts - has city' );
ok( isset($rs['radix'][0]['Household Income Src Map']), 'expsrc allfacts - has complex fact' );

$rs = $api->query("bin/$uuid/export");
is( $rs['code'], AIRAPI::OKAY, 'export allfacts - okay' );
is( $rs['meta']['total'], 0, 'export allfacts - total' );
$src1->clearRelated();
is( $src1->SrcActivity->count(), 0, 'expsrc allfacts - no src_activity' );


/**********************
 * 3) Logging
 */
$rs = $api->query("bin/$uuid/exportsource", array('logging' => 1));
is( $rs['code'], AIRAPI::OKAY, 'expsrc logging - okay' );
is( count($rs['radix']), 7, 'expsrc logging - count' );

$rs = $api->query("bin/$uuid/export");
is( $rs['code'], AIRAPI::OKAY, 'export logging - okay' );
is( $rs['meta']['total'], 1, 'export logging - total' );
$src1->clearRelated();
is( $src1->SrcActivity->count(), 1, 'expsrc - has src_activity' );

// cleanup
foreach ($rs['radix'] as $se) {
    $conn->exec('delete from src_export where se_uuid = ?', array($se['se_uuid']));
}


/**********************
 * 4) Email
 */
$rs = $api->query("bin/$uuid/exportsource", array('logging' => 0, 'email' => 1));
is( $rs['code'], AIRAPI::BAD_DATA, 'expsrc email - fail' );
like( $rs['message'], '/must have an email/i', 'expsrc email - message' );

$u->UserEmailAddress[0]->uem_address = "#{$u->user_username}@test.com";
$u->UserEmailAddress[0]->uem_primary_flag = true;
$u->save();

$rs = $api->query("bin/$uuid/exportsource", array('logging' => 0, 'email' => 1));
is( $rs['code'], AIRAPI::BGND_CREATE, 'expsrc email - okay' );

$uid = $u->user_id;
$bid = $bin->bin_id;
$q = Doctrine_Query::create()->from('JobQueue');
$q->where("jq_job like '%--user_id=$uid%'");
$jq = $q->fetchOne();

ok( $jq, 'expsrc email - job queued' );
like( $jq->jq_job, "/$bid/", 'expsrc email - job bin_id' );
like( $jq->jq_job, "/format=email/", 'expsrc email - job format' );

$jq->delete();
