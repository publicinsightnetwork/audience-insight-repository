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
require_once APPPATH.'/../tests/models/TestInquiry.php';
require_once 'phperl/callperl.php';

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
plan(16);

$tank = new TestTank();
$tank->tank_user_id = 1;
$tank->tank_type = 'F';
$tank->tank_status = Tank::$STATUS_READY;
$tank->save();

$i = new TestInquiry();
$i->Question[0]->ques_value = 'Test Question number 1';
$i->Question[0]->ques_dis_seq = 10;
$i->Question[1]->ques_value = 'Test Question number 2';
$i->Question[1]->ques_dis_seq = 20;
$i->Question[2]->ques_value = 'Test Question number 3';
$i->Question[2]->ques_dis_seq = 30;
$i->save();

$s = new TestSource();
$s->save();

$ts = new TankSource();
$ts->tsrc_tank_id = $tank->tank_id;
$ts->src_id = $s->src_id;
$ts->save();

$trs = new TankResponseSet();
$trs->trs_tsrc_id = $ts->tsrc_id;
$trs->srs_inq_id = $i->inq_id;
$trs->srs_date = air2_date();
$trs->srs_type = 'T'; //test
$trs->TankResponse[0]->tr_tsrc_id = $ts->tsrc_id;
$trs->TankResponse[0]->sr_ques_id = $i->Question[0]->ques_id;
$trs->TankResponse[0]->sr_orig_value = 'Test Answer number 1';
$trs->TankResponse[1]->tr_tsrc_id = $ts->tsrc_id;
$trs->TankResponse[1]->sr_ques_id = $i->Question[1]->ques_id;
$trs->TankResponse[1]->sr_orig_value = 'Test Answer number 2';
$trs->TankResponse[2]->tr_tsrc_id = $ts->tsrc_id;
$trs->TankResponse[2]->sr_ques_id = $i->Question[2]->ques_id;
$trs->TankResponse[2]->sr_orig_value = 'Test Answer number 3';
$trs->save();

function refresh_all() {
    global $tank, $ts, $s;
    $tank->refresh();
    $s->refresh(true);
    $ts = $tank->TankSource[0];
    $tank->clearRelated();
}


/**********************
 * Import responses from tank
 */
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'responses - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'responses - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'responses - tsrc_status' );
is( $report['error'], 0, 'responses - error count' );
is( $report['conflict'], 0, 'responses - conflict count' );
is( $report['done_upd'], 1, 'responses - done count' );
is( $s->SrcResponseSet->count(), 1, 'responses - resp set count' );
is( $s->SrcResponse->count(), 3, 'responses - resp count' );


/**********************
 * Importing the same thing again should just add it again
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'responses 2 - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'responses 2 - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'responses 2 - tsrc_status' );
is( $report['error'], 0, 'responses 2 - error count' );
is( $report['conflict'], 0, 'responses 2 - conflict count' );
is( $report['done_upd'], 1, 'responses 2 - done count' );
is( $s->SrcResponseSet->count(), 2, 'responses 2 - resp set count' );
is( $s->SrcResponse->count(), 6, 'responses 2 - resp count' );


// delete the source first, to prevent data integrity errors
$s->delete();
