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

require_once 'Test.php';
require_once 'app/init.php';
require_once 'AirTestUtils.php';
require_once 'models/TestSource.php';
require_once 'models/TestOrganization.php';
require_once 'models/TestProject.php';
require_once 'models/TestInquiry.php';

// init
AIR2_DBManager::init();
plan(1);

// create some dummy data
$src = new TestSource();
$src->save();

$org1 = new TestOrganization();
$org1->save();

// add an email
$src->SrcEmail[0]->sem_email = 'ima-src-status-test@nosuchemail.org';
$src->SrcEmail[0]->sem_primary_flag = 1;
$src->save();

// add to some orgs
$so1 = new SrcOrg();
$so1->so_src_id = $src->src_id;
$so1->so_org_id = $org1->org_id;
$src->SrcOrg[] = $so1;
$src->save();

// add a sys-id
$osid = new OrgSysId();
$osid->osid_org_id = $org1->org_id;
$osid->osid_type = 'E';
$osid->osid_xuuid = 99999;
$osid->save();

// mock soe record for org
$soe = new SrcOrgEmail();
$soe->soe_org_id = $org1->org_id;
$soe->soe_sem_id = $src->SrcEmail[0]->sem_id;
$soe->soe_status = 'A';
$soe->soe_status_dtim = '2010-01-01 00:00:00';
$soe->soe_type = 'L';
$soe->save();

// unsubscribe the email
$src->SrcEmail[0]->refresh(true);
$src->SrcEmail[0]->sem_status = 'U';
$src->save();

// actual test: was JobQueue record created?
$q = AIR2_Query::create()->from('JobQueue jq')->where('jq.jq_start_dtim is null');
$jobs = $q->execute();
foreach ($jobs as $job) {
    //diag($job->jq_job);
    if (preg_match('/modify-lyris-email --org_id ' . $org1->org_id . '/', $job->jq_job)) {
        pass("got job_queue record for org_id " . $org1->org_id);
        // clean up as we go
        $job->delete();
    }
}

