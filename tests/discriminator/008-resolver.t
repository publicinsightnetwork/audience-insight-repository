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
plan(97);

/* get some fact/fact_value ids */
$f_gender = $tbl_fact->findOneBy('fact_identifier', 'gender')->fact_id;
$fv_gender_1 = $tbl_fv->findOneBy('fv_value', 'Male')->fv_id;
$fv_gender_2 = $tbl_fv->findOneBy('fv_value', 'Female')->fv_id;

function reset_source() {
    global $s;
    if ($s) $s->delete();
    $s = new TestSource();
    $s->src_first_name = 'Testfirstname';
    $s->src_last_name = 'Testlastname';
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
 * Import data into the Source (no conflicts)
 */
reset_all();
$ts->src_first_name = $s->src_first_name;
$ts->src_last_name = $s->src_last_name;
$ts->sph_primary_flag = true;
$ts->sph_number = '651-555-5555';
$ts->TankFact[0]->tf_fact_id = $f_gender;
$ts->TankFact[0]->sf_fv_id = $fv_gender_1;
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'source setup - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'source setup - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'source setup - tsrc_status' );
is( $report['done_upd'], 1, 'source setup - done count' );
is( $report['conflict'], 0, 'source setup - conflict count' );
is( $report['error'], 0, 'source setup - error count' );
is( count($s->SrcFact), 1, 'source setup - SrcFact count');


/**********************
 * Import conflicting src_first_name (REPLACE)
 */
reset_tank();
$ts->src_first_name = 'Haroldish';
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'first conflict - ok' );
is( $tank->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'first conflict - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'first conflict - tsrc_status' );
is( $report['done_upd'], 0, 'first conflict - done count' );
is( $report['conflict'], 1, 'first conflict - conflict count' );
is( $report['error'], 0, 'first conflict - error count' );
is( count($s->SrcAlias), 0, 'first conflict - SrcAlias count' );
isnt( $s->src_first_name, 'Haroldish', 'first conflict - first_name unchanged' );


$ops = array('src_first_name' => 'R');
$stat = CallPerl::exec('AIR2::TankSource->discriminate', $ts->tsrc_id, $ops);
refresh_all();

ok( $stat, 'first resolve - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'first resolve - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_RESOLVED, 'first resolve - tsrc_status' );
is( count($s->SrcAlias), 0, 'first resolve - SrcAlias count' );
is( $s->src_first_name, 'Haroldish', 'first resolve - first_name changed' );


/**********************
 * Import conflicting src_last_name (IGNORE)
 */
reset_tank();
$ts->src_last_name = 'Blah-ish';
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'last conflict - ok' );
is( $tank->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'last conflict - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'last conflict - tsrc_status' );
is( $report['done_upd'], 0, 'last conflict - done count' );
is( $report['conflict'], 1, 'last conflict - conflict count' );
is( $report['error'], 0, 'last conflict - error count' );
is( count($s->SrcAlias), 0, 'last conflict - SrcAlias count' );
isnt( $s->src_last_name, 'Blah-ish', 'last conflict - last_name unchanged' );

$ops = array('src_last_name' => 'I');
$stat = CallPerl::exec('AIR2::TankSource->discriminate', $ts->tsrc_id, $ops);
refresh_all();

ok( $stat, 'last resolve - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'last resolve - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_RESOLVED, 'last resolve - tsrc_status' );
is( count($s->SrcAlias), 0, 'last resolve - SrcAlias count' );
isnt( $s->src_last_name, 'Blah-ish', 'last resolve - last_name ignored' );


/**********************
 * Import alias src_first_name (ADD)
 */
reset_tank();
$ts->src_first_name = 'MYALIASNAME';
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'add alias - ok' );
is( $tank->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'add alias - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'add_alias - tsrc_status' );
is( $report['conflict'], 1, 'add alias - conflict count' );
is( count($s->SrcAlias), 0, 'add alias - SrcAlias count' );
is( $s->src_first_name, 'Haroldish', 'add alias - first_name unchanged' );

$ops = array('src_first_name' => 'A');
$stat = CallPerl::exec('AIR2::TankSource->discriminate', $ts->tsrc_id, $ops);
refresh_all();

ok( $stat, 'add alias - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'add alias - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_RESOLVED, 'add alias - tsrc_status' );
is( count($s->SrcAlias), 1, 'add alias - SrcAlias count' );
is( $s->SrcAlias[0]->sa_first_name, 'MYALIASNAME', 'add alias - SrcAlias value' );
is( $s->src_first_name, 'Haroldish', 'add alias - first_name unchanged' );

reset_tank();
$ts->src_first_name = 'MYALIASNAME';
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'add alias 2 - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'add alias 2 - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'add_alias 2 - tsrc_status' );
is( $report['done_upd'], 1, 'add alias 2 - done count' );
is( count($s->SrcAlias), 1, 'add alias 2 - SrcAlias count' );
is( $s->src_first_name, 'Haroldish', 'add alias 2 - first_name unchanged' );


/**********************
 * Import conflicting fact (REPLACE)
 */
reset_tank();
$ts->src_pre_name = 'Duke';
$ts->TankFact[0]->tf_fact_id = $f_gender;
$ts->TankFact[0]->sf_fv_id = $fv_gender_2;
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'fact conflict - ok' );
is( $tank->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'fact conflict - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'fact conflict - tsrc_status' );
is( $report['done_upd'], 0, 'fact conflict - done count' );
is( $report['conflict'], 1, 'fact conflict - conflict count' );
is( $report['error'], 0, 'fact conflict - error count' );
isnt( $s->src_pre_name, 'Duke', 'fact conflict - pre_name unchanged' );
is( $s->SrcFact[0]->sf_fact_id, $f_gender, 'fact conflict - fact_id' );
is( $s->SrcFact[0]->sf_fv_id, $fv_gender_1, 'fact conflict - fv_id' );

$ops = array("gender" => 'R');
$stat = CallPerl::exec('AIR2::TankSource->discriminate', $ts->tsrc_id, $ops);
refresh_all();

ok( $stat, 'fact resolve - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'fact resolve - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_RESOLVED, 'fact resolve - tsrc_status' );
is( $s->src_pre_name, 'Duke', 'fact resolve - pre_name changed' );
is( $s->SrcFact[0]->sf_fact_id, $f_gender, 'fact resolve - fact_id' );
is( $s->SrcFact[0]->sf_fv_id, $fv_gender_2, 'fact resolve - fv_id' );


/**********************
 * Create 2 conflicts
 */
reset_tank();
$ts->src_pre_name = 'King';
$ts->TankFact[0]->tf_fact_id = $f_gender;
$ts->TankFact[0]->sf_fv_id = $fv_gender_1;
$ts->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
refresh_all();

ok( $report, 'double conflict - ok' );
is( $tank->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'double conflict - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'double conflict - tsrc_status' );
is( $report['done_upd'], 0, 'double conflict - done count' );
is( $report['conflict'], 1, 'double conflict - conflict count' );
is( $report['error'], 0, 'double conflict - error count' );
is( $s->src_pre_name, 'Duke', 'double conflict - pre_name unchanged' );
is( $s->SrcFact[0]->sf_fact_id, $f_gender, 'double conflict - fact_id' );
is( $s->SrcFact[0]->sf_fv_id, $fv_gender_2, 'double conflict - fv_id' );

$errs = json_decode($ts->tsrc_errors, true);
is( count($errs['initial']), 2, 'double conflict - tsrc conflict count' );
ok( $errs['initial']['src_pre_name'], 'double conflict - src_pre_name' );
is( $errs['initial']['src_pre_name']['ops'], 'IR', 'double conflict - pre_name valid ops' );
is( $errs['initial']['src_pre_name']['val'], 'Duke', 'double conflict - pre_name val' );
ok( $errs['initial']['gender.sf_fv_id'], 'double conflict - gender sf_fv_id' );
is( $errs['initial']['gender.sf_fv_id']['ops'], 'IR', 'double conflict - gender valid ops' );
is( $errs['initial']['gender.sf_fv_id']['val'], $fv_gender_2, 'double conflict - gender val' );


/**********************
 * Half resolve the conflict
 */
$ops = array("gender" => 'R');
$stat = CallPerl::exec('AIR2::TankSource->discriminate', $ts->tsrc_id, $ops);
refresh_all();

ok( $stat, 'half resolve - ok' );
is( $tank->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'half resolve - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'half resolve - tsrc_status' );
is( $s->src_pre_name, 'Duke', 'half resolve - pre_name unchanged' );
is( $s->SrcFact[0]->sf_fact_id, $f_gender, 'half resolve - fact_id' );
is( $s->SrcFact[0]->sf_fv_id, $fv_gender_2, 'half resolve - fv_id' );

$errs = json_decode($ts->tsrc_errors, true);
is( count($errs['initial']), 2, 'half resolve - tsrc initial conflict count' );
is( count($errs['last']), 1, 'half resolve - tsrc last conflict count' );


/**********************
 * Resolve the entire conflict
 */
$ops = array("gender.sf_fv_id" => 'R', 'src_pre_name' => 'R');
$stat = CallPerl::exec('AIR2::TankSource->discriminate', $ts->tsrc_id, $ops);
refresh_all();

ok( $stat, 'whole resolve - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'whole resolve - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_RESOLVED, 'whole resolve - tsrc_status' );
is( $s->src_pre_name, 'King', 'whole resolve - pre_name changed' );
is( $s->SrcFact[0]->sf_fact_id, $f_gender, 'whole resolve - fact_id' );
is( $s->SrcFact[0]->sf_fv_id, $fv_gender_1, 'whole resolve - fv_id' );
is( $ts->tsrc_errors, null, 'whole resolve - errors null' );
