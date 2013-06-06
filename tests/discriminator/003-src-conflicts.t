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
require_once 'phperl/callperl.php';

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
plan(27);

$tank = new TestTank();
$tank->tank_user_id = 1;
$tank->tank_type = 'F';
$tank->tank_status = Tank::$STATUS_READY;
$tank->save();
$tank_data = $tank->toArray();

$s = new TestSource();
$s->save();
$s_data = $s->toArray();

$ts = new TankSource();
$ts->tsrc_tank_id = $tank->tank_id;
$ts->src_id = $s->src_id;
$ts->save();
$ts_data = $ts->toArray();

function reset_all() {
    global $tank, $ts, $s, $tank_data, $ts_data, $s_data;
    $ts->synchronizeWithArray($ts_data);
    $ts->save();
    $s->synchronizeWithArray($s_data);
    $s->save();
}
function refresh_all() {
    global $tank, $ts, $s;
    $tank->refresh();
    $s->refresh();
    $ts = $tank->TankSource[0];
    $tank->clearRelated();
}


/**********************
 * Test non-conflict (new value same as old)
 */
$s->src_last_name = 'testlastname';
$s->save();
$ts->src_last_name = 'testlastname';
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'non-conflict - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'non-conflict - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'non-conflict - tsrc_status' );
is( $report['done_upd'], 1, 'non-conflict - done count' );
is( $s->src_last_name, 'testlastname', 'non-conflict - src_last_name');


/**********************
 * Test conflicting last name
 */
reset_all();
$s->src_last_name = 'testlastname2';
$s->save();
$ts->src_last_name = 'testlastname';
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'lastname conflict - ok' );
is( $tank->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'lastname conflict - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'lastname conflict - tsrc_status' );
is( $report['conflict'], 1, 'lastname conflict - conflict count' );
ok( $ts->tsrc_errors && strlen($ts->tsrc_errors) > 0, 'lastname conflict - tsrc_errors' );
is( $s->src_last_name, 'testlastname2', 'lastname conflict - src_last_name');


/**********************
 * Test updating tank and re-running
 */
$ts->src_last_name = 'testlastname2';
$ts->save();
$stat = CallPerl::exec('AIR2::TankSource->discriminate', $ts->tsrc_id);
refresh_all();

is( $stat, TankSource::$STATUS_RESOLVED, 'lastname rerun - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'lastname rerun - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_RESOLVED, 'lastname rerun - tsrc_status' );
ok( is_null($ts->tsrc_errors), 'lastname rerun - tsrc_errors' );
is( $s->src_last_name, 'testlastname2', 'lastname rerun - src_last_name');


/**********************
 * Test conflicting username
 */
reset_all();
$ts->src_username = 'testusername';
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'username conflict - ok' );
is( $tank->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'username conflict - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'username conflict - tsrc_status' );
is( $report['conflict'], 1, 'username conflict - conflict count' );
ok( $ts->tsrc_errors && strlen($ts->tsrc_errors) > 0, 'username conflict - tsrc_errors' );


/**********************
 * Blanks count as nulls
 */
reset_all();
$s->src_first_name = 'OLDFIRST';
$s->src_last_name = '';
$s->save();
$ts->src_first_name = '';
$ts->src_last_name = 'NEWLASTNAME';
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'blanks are null - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'blanks are null - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'blanks are null - tsrc_status' );
is( $report['done_upd'], 1, 'blanks are null - done count' );
is( $s->src_first_name, 'OLDFIRST', 'blanks are null - src_first_name');
is( $s->src_last_name, 'NEWLASTNAME', 'blanks are null - src_last_name');
