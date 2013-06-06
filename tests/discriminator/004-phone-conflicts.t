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
plan(30);

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
 * Test non-conflict (new value)
 */
$ts->sph_number = '555-555-5555';
$ts->sph_primary_flag = true;
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'new phone - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'new phone - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'new phone - tsrc_status' );
is( $report['done_upd'], 1, 'new phone - done count' );
is( $s->SrcPhoneNumber->count(), 1, 'new phone - phone number count' );
is( $s->SrcPhoneNumber[0]->sph_number, '5555555555', 'new phone - sph_number' );
is( $s->SrcPhoneNumber[0]->sph_primary_flag, true, 'new phone - sph_primary_flag' );


/**********************
 * Test discriminating a different phone value
 */
$s->clearRelated(); //keep old src_phone_number
reset_all();
$ts->sph_number = '555-555-6666';
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'different - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'different - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'different - tsrc_status' );
is( $report['done_upd'], 1, 'different - done count' );
is( $s->SrcPhoneNumber->count(), 2, 'different - phone number count' );
is( $s->SrcPhoneNumber[1]->sph_number, '5555556666', 'different - sph_number' );
is( $s->SrcPhoneNumber[1]->sph_primary_flag, false, 'different - sph_primary_flag' );


/**********************
 * Test discriminating an existing phone value (should KEEP that value)
 */
$s->clearRelated(); //keep old src_phone_numbers
reset_all();
$ts->sph_number = '555-555-6666';
$ts->sph_ext = 'x123';
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'existing - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'existing - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'existing - tsrc_status' );
is( $report['done_upd'], 1, 'existing - done count' );
is( $s->SrcPhoneNumber->count(), 2, 'existing - phone number count' );
is( $s->SrcPhoneNumber[1]->sph_number, '5555556666', 'existing - sph_number' );
is( $s->SrcPhoneNumber[1]->sph_primary_flag, false, 'existing - sph_primary_flag' );
is( $s->SrcPhoneNumber[1]->sph_ext, 'x123', 'existing - sph_ext' );


/**********************
 * Test conflict on an existing phone value (changed sph_ext)
 */
$s->clearRelated(); //keep old src_phone_numbers
reset_all();
$ts->sph_number = '555-555-6666';
$ts->sph_ext = 'x456';
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'update - ok' );
is( $tank->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'update - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'update - tsrc_status' );
is( $report['conflict'], 1, 'update - conflict count' );
is( $s->SrcPhoneNumber->count(), 2, 'update - phone number count' );
is( $s->SrcPhoneNumber[1]->sph_number, '5555556666', 'update - sph_number' );
is( $s->SrcPhoneNumber[1]->sph_primary_flag, false, 'update - sph_primary_flag' );
is( $s->SrcPhoneNumber[1]->sph_ext, 'x123', 'update - sph_ext' );
