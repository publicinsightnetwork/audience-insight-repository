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
$o2 = new TestOrganization();
$o2->save();
$s = new TestSource();
$s->save();
$s2 = new TestSource();
$s2->save();
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

function run_tank($debug=false) {
    global $tank_id, $t, $s, $ts;
    $report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
    $t->refresh();
    $ts->refresh();
    $s->refresh(true);
    return $report;
}

plan(48);

/**********************
 * 1) add source to new org
 */
$t->TankOrg[0]->to_org_id = $o1->org_id;
$t->save();

$res = run_tank();

is( $res, true, 'new org - result' );
is( $t->tank_status, Tank::$STATUS_READY, 'new org - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'new org - tsrc_status' );
is( $res['done_upd'], 1, 'new org - done count' );
is( count($s->SrcOrg), 2, 'new org - 2 SrcOrg' );
$so = $s->SrcOrg[0]->so_org_id == 1 ? $s->SrcOrg[1] : $s->SrcOrg[0];
$apm = $s->SrcOrg[0]->so_org_id == 1 ? $s->SrcOrg[0] : $s->SrcOrg[1];
is( $so->so_org_id, $o1->org_id, 'new org - org_id' );
is( $so->so_status, SrcOrg::$STATUS_OPTED_IN, 'new org - opted in' );
is( $so->so_home_flag, true, 'new org - home flag' );
is( $apm->so_org_id, Organization::$APMPIN_ORG_ID, 'new org - apmg forced' );
is( $apm->so_status, SrcOrg::$STATUS_OPTED_IN, 'new org - apmg opted in' );
is( $apm->so_home_flag, false, 'new org - apmg home flag' );


/**********************
 * 2) re-join a source to opted-out organization
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->save();
$so->so_status = SrcOrg::$STATUS_OPTED_OUT;
$so->save();

$res = run_tank();
$so->refresh();
$apm->refresh();

is( $res, true, 're-opt - result' );
is( $t->tank_status, Tank::$STATUS_READY, 're-opt - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 're-opt - tsrc_status' );
is( $res['done_upd'], 1, 're-opt - done count' );
is( count($s->SrcOrg), 2, 're-opt - 2 SrcOrg' );
is( $so->so_org_id, $o1->org_id, 're-opt - org_id' );
is( $so->so_status, SrcOrg::$STATUS_OPTED_IN, 're-opt - opted in' );
is( $so->so_home_flag, true, 're-opt - home flag' );


/**********************
 * 3) join source to a second organization
 */
$t->TankOrg[1]->to_org_id = $o2->org_id;
$t->save();
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->save();

$res = run_tank();
$so->refresh();
$apm->refresh();

is( $res, true, '2-opt - result' );
is( $t->tank_status, Tank::$STATUS_READY, '2-opt - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, '2-opt - tsrc_status' );
is( $res['done_upd'], 1, '2-opt - done count' );
is( count($s->SrcOrg), 3, '2-opt - 3 SrcOrgs' );
$so2 = $s->SrcOrg[2];
is( $so->so_org_id, $o1->org_id, '2-opt - org_id 1' );
is( $so2->so_org_id, $o2->org_id, '2-opt - org_id 2' );
is( $so->so_status, SrcOrg::$STATUS_OPTED_IN, '2-opt - opted in 1' );
is( $so2->so_status, SrcOrg::$STATUS_OPTED_IN, '2-opt - opted in 2' );
is( $so->so_home_flag, true, '2-opt - home flag 1' );
is( $so2->so_home_flag, false, '2-opt - home flag 2' );


/**********************
 * 4) re-join source to duplicate org
 */
$t->TankOrg[2]->to_org_id = $o2->org_id;
$t->TankOrg[2]->to_so_status = SrcOrg::$STATUS_OPTED_OUT;
$t->TankOrg[2]->to_so_home_flag = true;
$t->save();
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->save();

$res = run_tank();
$so->refresh();
$apm->refresh();
$so2->refresh();

is( $res, true, 'dup-opt - result' );
is( $t->tank_status, Tank::$STATUS_READY, 'dup-opt - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'dup-opt - tsrc_status' );
is( $res['done_upd'], 1, 'dup-opt - done count' );
is( count($s->SrcOrg), 3, 'dup-opt - 2 SrcOrgs' );
is( $so->so_org_id, $o1->org_id, 'dup-opt - org_id 1' );
is( $so2->so_org_id, $o2->org_id, 'dup-opt - org_id 2' );
is( $so->so_status, SrcOrg::$STATUS_OPTED_IN, 'dup-opt - opted in 1' );
is( $so2->so_status, SrcOrg::$STATUS_OPTED_OUT, 'dup-opt - opted out 2' );
is( $so->so_home_flag, false, 'dup-opt - home flag 1' );
is( $so2->so_home_flag, true, 'dup-opt - home flag 2' );


/**********************
 * 5) join new source to APMG (should only add 1 org)
 */
$t->TankOrg->delete();
$t->TankSource->delete();
$ts = new TankSource();
$ts->Tank = $t;
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->src_id = $s2->src_id;
$ts->save();

// add ONLY apmg org
$t->TankOrg[0]->to_org_id = Organization::$APMPIN_ORG_ID;
$t->save();

is( $s2->SrcOrg->count(), 0, 'src2 - 0 orgs' );
$res = run_tank();
$so->refresh();
$apm->refresh();
$so2->refresh();

$s2->refresh(true);
is( $res, true, 'src2 - result' );
is( $t->tank_status, Tank::$STATUS_READY, 'src2 - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'src2 - tsrc_status' );
is( $res['done_upd'], 1, 'src2 - done count' );
is( count($s2->SrcOrg), 1, 'src2 - 1 SrcOrgs' );
$so = $s2->SrcOrg[0];
is( $so->so_org_id, Organization::$APMPIN_ORG_ID, 'src2 - org_id apmg' );
