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
require_once APPPATH.'/../tests/Test.php';
require_once APPPATH.'/../tests/models/TestTank.php';
require_once APPPATH.'/../tests/models/TestSource.php';
require_once APPPATH.'/../tests/models/TestOrganization.php';
require_once 'phperl/callperl.php';

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// setup
$o1 = new TestOrganization();
$o1->save();
$s = new TestSource();
$s->save();
$t = new TestTank();
$t->tank_user_id = 1;
$t->tank_type = Tank::$TYPE_FB;
$t->tank_status = Tank::$STATUS_READY;
$t->save();
$tank_id = $t->tank_id;
$ts = new TankSource();
$ts->tsrc_tank_id = $t->tank_id;
$ts->src_id = $s->src_id;
$ts->save();


/**
 *
 *
 * @param unknown $debug (optional)
 * @return unknown
 */
function run_tank($debug=false) {
    global $tank_id, $t, $s, $ts;
    $report = CallPerl::exec('AIR2::Tank->discriminate', $tank_id);
    $t->refresh();
    $ts->refresh();
    $s->refresh(true);
    return $report;
}


plan(2);

/**********************
 * 0) status baseline
 */
is( $s->src_status, Source::$STATUS_NO_PRIMARY_EMAIL,
    "default status is N" );

/**********************
 * 1) add new email, add source to new org
 */
$t->TankOrg[0]->to_org_id = $o1->org_id;
$t->save();
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->sem_primary_flag = true;
$ts->sem_context = SrcEmail::$CONTEXT_WORK;
$ts->sem_email = 'johnny@longtone.com';
$ts->sem_effective_date = air2_date(strtotime('-2 week'));
$ts->sem_expire_date = air2_date(strtotime('+1 month'));
$ts->save();

$res = run_tank();
//diag_dump($res);

/**********************
 * 2) status changed via discriminator
 */
$s->refresh(true);
is( $s->src_status, Source::$STATUS_ENROLLED,
    "after org additions, status==Enrolled" );
