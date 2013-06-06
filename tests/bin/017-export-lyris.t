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
$o2->add_users(array($u), AdminRole::WRITER);
$o2->save();
$o3 = new TestOrganization();
$o3->add_users(array($u), AdminRole::NOACCESS);
$o3->save();
$o4 = new TestOrganization();
$o4->save();

$prj = new TestProject();
$prj->add_orgs(array($o1));
$prj->save();

$inq = new TestInquiry();
$inq->add_projects(array($prj));
$inq->save();

// sources in orgs
$o1_s1 = new TestSource();
$o1_s1->add_orgs(array($o1), SrcOrg::$STATUS_OPTED_IN);
$o1_s1->save();
$o1_s2 = new TestSource();
$o1_s2->add_orgs(array($o1), SrcOrg::$STATUS_OPTED_OUT);
$o1_s2->save();
$o1_s3 = new TestSource();
$o1_s3->add_orgs(array($o1), SrcOrg::$STATUS_EDITORIAL_DEACTV);
$o1_s3->save();
$o1_s4 = new TestSource();
$o1_s4->add_orgs(array($o1), SrcOrg::$STATUS_DELETED);
$o1_s4->save();
$o2_s1 = new TestSource();
$o2_s1->add_orgs(array($o2), SrcOrg::$STATUS_OPTED_IN);
$o2_s1->save();
$o3_s1 = new TestSource();
$o3_s1->add_orgs(array($o3), SrcOrg::$STATUS_OPTED_IN);
$o3_s1->save();
$o4_s1 = new TestSource();
$o4_s1->add_orgs(array($o4), SrcOrg::$STATUS_OPTED_IN);
$o4_s1->save();

// bin1 - org1 only
$b1 = new TestBin();
$b1->bin_user_id = $u->user_id;
$b1->BinSource[]->bsrc_src_id = $o1_s1->src_id;
$b1->BinSource[]->bsrc_src_id = $o1_s2->src_id;
$b1->BinSource[]->bsrc_src_id = $o1_s3->src_id;
$b1->BinSource[]->bsrc_src_id = $o1_s4->src_id;
$b1->save();
$uuid1 = $b1->bin_uuid;

// bin2 - all orgs
$b2 = new TestBin();
$b2->bin_user_id = $u->user_id;
$b2->BinSource[]->bsrc_src_id = $o1_s1->src_id;
$b2->BinSource[]->bsrc_src_id = $o1_s2->src_id;
$b2->BinSource[]->bsrc_src_id = $o1_s3->src_id;
$b2->BinSource[]->bsrc_src_id = $o1_s4->src_id;
$b2->BinSource[]->bsrc_src_id = $o2_s1->src_id;
$b2->BinSource[]->bsrc_src_id = $o3_s1->src_id;
$b2->BinSource[]->bsrc_src_id = $o4_s1->src_id;
$b2->save();
$uuid2 = $b2->bin_uuid;


plan(26);

/**********************
 * Check counts
 */
$rs = $api->fetch("bin/$uuid1");
is( $rs['code'], AIRAPI::OKAY, 'counts 1 - okay' );
is( $rs['radix']['src_count'],                  4, 'counts 1 - src_count' );
is( $rs['radix']['counts']['src_read'],         3, 'counts 1 - src_read' );
is( $rs['radix']['counts']['src_export_lyris'], 1, 'counts 1 - src_export_lyris' );

$rs = $api->query("bin/$uuid1/export");
is( $rs['code'], AIRAPI::OKAY, 'counts export 1 - okay' );
is( count($rs['radix']), 0, 'counts export 1 - radix count' );

$rs = $api->fetch("bin/$uuid2");
is( $rs['code'], AIRAPI::OKAY, 'counts 2 - okay' );
is( $rs['radix']['src_count'],                  7, 'counts 2 - src_count' );
is( $rs['radix']['counts']['src_read'],         4, 'counts 2 - src_read' );
is( $rs['radix']['counts']['src_export_lyris'], 2, 'counts 2 - src_export_lyris' );

$rs = $api->query("bin/$uuid2/export");
is( $rs['code'], AIRAPI::OKAY, 'counts export 2 - okay' );
is( count($rs['radix']), 0, 'counts export 2 - radix count' );


/**********************
 * run a fake export
 */
$export = array(
    'se_type'       => SrcExport::$TYPE_LYRIS,
    'prj_uuid'      => $prj->prj_uuid,
    'inq_uuid'      => $inq->inq_uuid,
    'org_uuid'      => $o1->org_uuid,
    'strict_check'  => false,
    'dry_run'       => true,
    'no_export'     => true,
);
$rs = $api->create("bin/$uuid1/export", $export);
is( $rs['code'], AIRAPI::BGND_CREATE, 'fake export - okay' );
like( $rs['message'], '/background proc/i', 'fake export - message' );


/**********************
 * find the job_queue record
 */
$bid = $b1->bin_id;
$q = Doctrine_Query::create()->from('JobQueue');
$q->where('jq_job like ?', "% --bin_id $bid %");
$job = $q->fetchOne();

// abort remaining tests if no job
if (!$job) {
    fail('Job created');
}
pass('Job created');
like( $job->jq_job, '/strict=0/', 'Job - strict' );
like( $job->jq_job, '/dry_run=1/', 'Job - dry_run' );
like( $job->jq_job, '/no_exp=1/', 'Job - no_exp' );


/**********************
 * run the job (USER has no EMAIL!)
 */
$ret = $job->run();
ok( !$ret, 'Job run unsuccess' );
ok( $job->jq_start_dtim, 'Job started' );
ok( $job->jq_complete_dtim, 'Job ended' );
like( $job->jq_error_msg, '/no email address/i', 'Job failed with no email error' );


/**********************
 * set email an rerun
 */
$u->UserEmailAddress[0]->uem_address = $u->user_uuid.'@nosuchemail.org';
$u->UserEmailAddress[0]->uem_primary_flag = true;
$u->save();
$job->jq_start_dtim = null;
$job->jq_complete_dtim = null;
$job->jq_error_msg = null;
$job->jq_pid = null;
$job->jq_host = null;
$job->save();

// rerun
$ret = $job->run();
ok( !$ret, 'Job run 2 unsuccess' );
ok( $job->jq_start_dtim, 'Job started' );
ok( $job->jq_complete_dtim, 'Job ended' );
like( $job->jq_error_msg, '/no mailing list id/i', 'Job failed with mailing-list error' );

// TODO: other tests?

// cleanup
$job->delete();
