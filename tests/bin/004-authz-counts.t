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

$p = new TestProject();
$p->add_orgs(array($o));
$p->save();

$i = new TestInquiry();
$i->add_projects(array($p));
$i->save();
$i_na = new TestInquiry();
$i_na->save();

$s1_na = new TestSource();
$s1_na->save();
$s2 = new TestSource();
$s2->add_orgs(array($o));
$s2->save();
$s3_unsub = new TestSource();
$s3_unsub->add_orgs(array($o), SrcOrg::$STATUS_OPTED_OUT);
$s3_unsub->save();

$r1 = new SrcResponseSet();
$r1->Source = $s1_na;
$r1->Inquiry = $i;
$r1->srs_date = air2_date();
$r1->save();

$r2_na = new SrcResponseSet();
$r2_na->Source = $s2;
$r2_na->Inquiry = $i_na;
$r2_na->srs_date = air2_date();
$r2_na->save();

$r3 = new SrcResponseSet();
$r3->Source = $s2;
$r3->Inquiry = $i;
$r3->srs_date = air2_date();
$r3->save();

$r4 = new SrcResponseSet();
$r4->Source = $s3_unsub;
$r4->Inquiry = $i;
$r4->srs_date = air2_date();
$r4->save();

// add to bin
$bin = new TestBin();
$bin->bin_user_id = $u->user_id;
$bin->save();
$uuid = $bin->bin_uuid;

$bin->BinSource[0]->bsrc_src_id = $s1_na->src_id;
$bin->BinSource[1]->bsrc_src_id = $s2->src_id;
$bin->BinSource[2]->bsrc_src_id = $s3_unsub->src_id;
$bin->BinSrcResponseSet[0]->bsrs_srs_id = $r1->srs_id;
$bin->BinSrcResponseSet[0]->bsrs_inq_id = $r1->srs_inq_id;
$bin->BinSrcResponseSet[0]->bsrs_src_id = $r1->srs_src_id;
$bin->BinSrcResponseSet[1]->bsrs_srs_id = $r2_na->srs_id;
$bin->BinSrcResponseSet[1]->bsrs_inq_id = $r2_na->srs_inq_id;
$bin->BinSrcResponseSet[1]->bsrs_src_id = $r2_na->srs_src_id;
$bin->BinSrcResponseSet[2]->bsrs_srs_id = $r3->srs_id;
$bin->BinSrcResponseSet[2]->bsrs_inq_id = $r3->srs_inq_id;
$bin->BinSrcResponseSet[2]->bsrs_src_id = $r3->srs_src_id;
$bin->BinSrcResponseSet[3]->bsrs_srs_id = $r4->srs_id;
$bin->BinSrcResponseSet[3]->bsrs_inq_id = $r4->srs_inq_id;
$bin->BinSrcResponseSet[3]->bsrs_src_id = $r4->srs_src_id;
$bin->save();


plan(30);

/**********************
 * Initial - test as reader
 */
$rs = $api->fetch("bin/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'reader - okay' );

$counts = isset($rs['radix']['counts']) ? $rs['radix']['counts'] : array();
is( $counts['src_total'],        3, 'reader - src_total' );
is( $counts['src_read'],         2, 'reader - src_read' );
is( $counts['src_update'],       0, 'reader - src_update' );
is( $counts['src_export_csv'],   2, 'reader - src_export_csv' );
is( $counts['src_export_lyris'], 1, 'reader - src_export_lyris' );
is( $counts['src_export_print'], 2, 'reader - src_export_print' );
is( $counts['subm_total'],       4, 'reader - subm_total' );
is( $counts['subm_read'],        3, 'reader - subm_read' );
is( $counts['subm_update'],      0, 'reader - subm_update' );


/**********************
 * Test as writer
 */
$u->UserOrg[0]->clearRelated();
$u->UserOrg[0]->uo_ar_id = AdminRole::WRITER;
$u->save();
$u->clear_authz();

$rs = $api->fetch("bin/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'writer - okay' );

$counts = isset($rs['radix']['counts']) ? $rs['radix']['counts'] : array();
is( $counts['src_total'],        3, 'writer - src_total' );
is( $counts['src_read'],         2, 'writer - src_read' );
is( $counts['src_update'],       2, 'writer - src_update' );
is( $counts['src_export_csv'],   2, 'writer - src_export_csv' );
is( $counts['src_export_lyris'], 1, 'writer - src_export_lyris' );
is( $counts['src_export_print'], 2, 'writer - src_export_print' );
is( $counts['subm_total'],       4, 'writer - subm_total' );
is( $counts['subm_read'],        3, 'writer - subm_read' );
is( $counts['subm_update'],      3, 'writer - subm_update' );


/**********************
 * Test as freemium
 */
$u->UserOrg[0]->clearRelated();
$u->UserOrg[0]->uo_ar_id = AdminRole::FREEMIUM;
$u->save();
$u->clear_authz();

$rs = $api->fetch("bin/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'freemium - okay' );

$counts = isset($rs['radix']['counts']) ? $rs['radix']['counts'] : array();
is( $counts['src_total'],        3, 'freemium - src_total' );
is( $counts['src_read'],         2, 'freemium - src_read' );
is( $counts['src_update'],       2, 'freemium - src_update' );
is( $counts['src_export_csv'],   2, 'freemium - src_export_csv' );
is( $counts['src_export_lyris'], 0, 'freemium - src_export_lyris' );
is( $counts['src_export_print'], 2, 'freemium - src_export_print' );
is( $counts['subm_total'],       4, 'freemium - subm_total' );
is( $counts['subm_read'],        3, 'freemium - subm_read' );
is( $counts['subm_update'],      0, 'freemium - subm_update' );
