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
$tbl_fact = Doctrine::getTable('Fact');
$tbl_fv = Doctrine::getTable('FactValue');
plan(36);

/* get some fact/fact_value ids */
$f_income = $tbl_fact->findOneBy('fact_identifier', 'household_income')->fact_id;
$f_gender = $tbl_fact->findOneBy('fact_identifier', 'gender')->fact_id;
$f_ethnic = $tbl_fact->findOneBy('fact_identifier', 'ethnicity')->fact_id;
$f_birthy = $tbl_fact->findOneBy('fact_identifier', 'birth_year')->fact_id;
$fv_income_1 = $tbl_fv->findOneBy('fv_value', 'Less than $15000')->fv_id;
$fv_income_2 = $tbl_fv->findOneBy('fv_value', '$15000-$50000')->fv_id;
$fv_gender_1 = $tbl_fv->findOneBy('fv_value', 'Male')->fv_id;
$fv_gender_2 = $tbl_fv->findOneBy('fv_value', 'Female')->fv_id;
$fv_ethnic_1 = $tbl_fv->findOneBy('fv_value', 'Asian')->fv_id;
$fv_ethnic_2 = $tbl_fv->findOneBy('fv_value', 'Middle Eastern')->fv_id;

function reset_source() {
    global $s;
    if ($s) $s->delete();
    $s = new TestSource();
    $s->save();
}
function reset_tank() {
    global $tank, $ts, $s;
    if ($tank) $tank->delete();

    $tank = new TestTank();
    $tank->tank_user_id = 1;
    $tank->tank_type = Tank::$TYPE_FB;
    $tank->tank_status = Tank::$STATUS_READY;
    $tank->TankSource[0]->src_id = $s->src_id;
    $tank->save();

    $ts = $tank->TankSource[0];
    $tank->clearRelated();
}
function reset_all() {
    reset_source();
    reset_tank();
    refresh_all();
}
function refresh_all() {
    global $tank, $ts, $s;
    $tank->clearRelated();
    $tank->refresh();
    $s->clearRelated();
    $s->refresh();
    $ts = $tank->TankSource[0];
    $tank->clearRelated();
}


/**********************
 * Test non-conflict (no existing fact)
 */
reset_all();
$ts->TankFact[0]->tf_fact_id = $f_income;
$ts->TankFact[0]->sf_fv_id = $fv_income_1;
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'non-conflict - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'non-conflict - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'non-conflict - tsrc_status' );
is( $report['done_upd'], 1, 'non-conflict - done count' );
is( $report['conflict'], 0, 'non-conflict - conflict count' );
is( $report['error'], 0, 'non-conflict - error count' );
is( count($s->SrcFact), 1, 'non-conflict - SrcFact count');


/**********************
 * Save duplicate fact
 */
reset_tank();
$ts->TankFact[0]->tf_fact_id = $f_income;
$ts->TankFact[0]->sf_fv_id = $fv_income_1;
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'duplicate - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'duplicate - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'duplicate - tsrc_status' );
is( $report['done_upd'], 1, 'duplicate - done count' );
is( count($s->SrcFact), 1, 'duplicate - SrcFact count');


/**********************
 * Change the fact falue (NOTE: due to fact disc rules, this is a NON-CONFLICT!)
 */
reset_tank();
$ts->TankFact[0]->tf_fact_id = $f_income;
$ts->TankFact[0]->sf_fv_id = $fv_income_2;
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'change income - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'change income - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'change income - tsrc_status' );
is( $report['done_upd'], 1, 'change income - done count' );
is( $report['conflict'], 0, 'change income - conflict count' );
is( $report['error'], 0, 'change income - error count' );
is( count($s->SrcFact), 1, 'change income - SrcFact count');


/**********************
 * Add some multi-value facts
 */
reset_tank();
$ts->TankFact[0]->tf_fact_id = $f_gender;
$ts->TankFact[0]->sf_src_fv_id = $fv_gender_1;
$ts->TankFact[0]->sf_src_value = 'something1';
$ts->TankFact[1]->tf_fact_id = $f_ethnic;
$ts->TankFact[1]->sf_fv_id = $fv_ethnic_1;
$ts->TankFact[1]->sf_src_value = 'something2';
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'change multi - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'change multi - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'change multi - tsrc_status' );
is( $report['done_upd'], 1, 'change multi - done count' );
is( $report['conflict'], 0, 'change multi - conflict count' );
is( $report['error'], 0, 'change multi - error count' );
is( count($s->SrcFact), 3, 'change multi - SrcFact count');


/**********************
 * Add new fact field to a multi-value
 */
reset_tank();
$ts->TankFact[0]->tf_fact_id = $f_gender;
$ts->TankFact[0]->sf_fv_id = $fv_gender_2;
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'add multi - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'add multi - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'add multi - tsrc_status' );
is( $report['done_upd'], 1, 'add multi - done count' );
is( count($s->SrcFact), 3, 'add multi - SrcFact count');


/**********************
 * Add a text-only value
 */
reset_tank();
$ts->TankFact[0]->tf_fact_id = $f_birthy;
$ts->TankFact[0]->sf_src_value = 'Sometime in the 1980s';
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'add text - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'add text - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'add text - tsrc_status' );
is( $report['done_upd'], 1, 'add text - done count' );
is( count($s->SrcFact), 4, 'add text - SrcFact count');

