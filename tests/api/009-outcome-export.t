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
require_once "$tdir/models/TestCleanup.php";
require_once "$tdir/models/TestUser.php";
require_once "$tdir/models/TestOrganization.php";
require_once "$tdir/models/TestInquiry.php";
require_once "$tdir/models/TestSource.php";
require_once "$tdir/models/TestOutcome.php";


/**********************
 * Init
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$u = new TestUser();
$u->save();
$api = new AIRAPI($u);

$o1 = new TestOrganization();
$o1->add_users(array($u), 4);
$o1->save();

$s1 = new TestSource();
$s1->add_orgs(array($o1));
$s1->save();
$s2 = new TestSource();
$s2->add_orgs(array($o1));
$s2->save();

$p1 = new TestProject();
$p1->add_orgs(array($o1));
$p1->save();
$p2 = new TestProject();
$p2->add_orgs(array($o1));
$p2->save();

$i1 = new TestInquiry();
$i1->inq_cre_user = $u->user_id;
$i1->add_projects(array($p1));
$i1->save();

$out = new TestOutcome();
$out->out_org_id = $o1->org_id;
$out->PrjOutcome[0]->pout_prj_id = $p1->prj_id;
$out->PrjOutcome[1]->pout_prj_id = $p2->prj_id;
$out->SrcOutcome[0]->sout_src_id = $s1->src_id;
$out->SrcOutcome[1]->sout_src_id = $s2->src_id;
$out->InqOutcome[0]->iout_inq_id = $i1->inq_id;
$out->save();


plan(27);

/**********************
 * 1) Export with org_id
 */
$rs = $api->query("outcomeexport", array('org_uuid' => 'NOTHING'));
is( $rs['code'], AIRAPI::BAD_DATA, 'org_uuid - bad' );
$rs = $api->query("outcomeexport", array('org_uuid' => $o1->org_uuid));
is( $rs['code'], AIRAPI::OKAY, 'org_uuid - okay' );
is( count($rs['radix']), 1, 'org_uuid - radix count' );

$row = $rs['radix'][0];
is( $row['Story Headline'], $out->out_headline, 'org_uuid - headline' );
is( $row['# Projects'], 2, 'org_uuid - 2 projects' );
is( $row['Organization'], $o1->org_display_name, 'org_uuid - org name' );
is( $row['# Queries'], 1, 'org_uuid - 1 query' );
is( $row['# Informing Sources'], 2, 'org_uuid - 2 informing sources' );


/**********************
 * 2) Export with prj_id
 */
$rs = $api->query("outcomeexport", array('prj_uuid' => 'NOTHING'));
is( $rs['code'], AIRAPI::BAD_DATA, 'prj_uuid - bad' );
$rs = $api->query("outcomeexport", array('prj_uuid' => $p1->prj_uuid));
is( $rs['code'], AIRAPI::OKAY, 'prj_uuid - okay' );
is( count($rs['radix']), 1, 'prj_uuid - radix count' );


/**********************
 * 3) Export with inq_id
 */
$rs = $api->query("outcomeexport", array('inq_uuid' => 'NOTHING'));
is( $rs['code'], AIRAPI::BAD_DATA, 'inq_uuid - bad' );
$rs = $api->query("outcomeexport", array('inq_uuid' => $i1->inq_uuid));
is( $rs['code'], AIRAPI::OKAY, 'inq_uuid - okay' );
is( count($rs['radix']), 1, 'inq_uuid - radix count' );


/**********************
 * 4) Start and end dates
 */
$out->out_dtim = '1941-10-12 09:15:12';
$out->save();

$rs = $api->query("outcomeexport", array('end_date' => 'Not-A-Date'));
is( $rs['code'], AIRAPI::BAD_DATA, 'end_date - bad' );
$rs = $api->query("outcomeexport", array('end_date' => '1943-01-01'));
is( $rs['code'], AIRAPI::OKAY, 'end_date - okay' );
is( count($rs['radix']), 1, 'end_date - radix count' );

$params = array('start_date' => 'Not-A-Date', 'end_date' => '1943-01-01');
$rs = $api->query("outcomeexport", $params);
is( $rs['code'], AIRAPI::BAD_DATA, 'start_date - bad' );
$params['start_date'] = '1942-01-01';
$rs = $api->query("outcomeexport", $params);
is( $rs['code'], AIRAPI::OKAY, 'start_date - okay' );
is( count($rs['radix']), 0, 'start_date - radix count' );


/**********************
 * 5) With sources
 */
$params = array('org_uuid' => $o1->org_uuid, 'sources' => true);
$rs = $api->query("outcomeexport", $params);
is( $rs['code'], AIRAPI::OKAY, 'w/sources - okay' );
is( count($rs['radix']), 2, 'w/sources - radix count' );
$src_row = $rs['radix'][0];
ok( count($src_row) > count($row), 'w/sources - more stuff than usual' );


/**********************
 * 6) Initiate an email through the job_queue
 */
$params = array('org_uuid' => $o1->org_uuid, 'email' => true);
$rs = $api->query("outcomeexport", $params);
is( $rs['code'], AIRAPI::BGND_CREATE, 'send email - bg-create' );

$uid = $u->user_id;
$oid = $o1->org_id;
$jobs = $conn->fetchAll("select * from job_queue where jq_job like '%--user_id=$uid%'");
if (count($jobs) == 1) {
    $conn->exec("delete from job_queue where jq_job like '%--user_id=$uid%'");
    pass( "send email - scheduled 1 job" );
    like( $jobs[0]['jq_job'], "/org_id=$oid/", 'send email - job org_id' );
    like( $jobs[0]['jq_job'], "/--format=email/", 'send email - job format' );
}
else {
    fail( "send email - scheduled 1 job" );
    fail( "send email - job org_id" );
    fail( "send email - job format" );
}
