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

// setup
$report;
$s = new TestSource();
$s->save();
$t = new TestTank();
$t->tank_user_id = 1;
$t->tank_type = Tank::$TYPE_FB;
$t->tank_status = Tank::$STATUS_READY;
$t->save();
$ts = new TankSource();
$ts->tsrc_tank_id = $t->tank_id;
$ts->src_id = $s->src_id;
$ts->save();

function run_tank() {
    global $t, $report, $s, $ts;

    // reset
    $ts->tsrc_status = TankSource::$STATUS_NEW;
    $ts->tsrc_errors = null;
    $ts->save();

    // run
    $report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
    $t->refresh();
    $ts->refresh();
    $s->refresh(true);
}


// birth year facts
$f_born = $conn->fetchOne("select fact_id from fact where fact_identifier = ?",
    array('birth_year'), 0);
$sane1 = '1982';
$sane2 = ' 2011';
$insane1 = '0';
$insane2 = '2020';
$insane3 = '10/10/1972';

plan(40);

/**********************
 * 1) existing DNE ... incoming sane
 */
$ts->TankFact[0]->tf_fact_id = $f_born;
$ts->TankFact[0]->sf_src_value = $sane1;
$ts->save();

run_tank();
ok( $report, 'DNE to sane - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'DNE to sane - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'DNE to sane - tsrc_status' );
is( $report['done_upd'], 1, 'DNE to sane - done count' );
is( count($s->SrcFact), 1, 'DNE to sane - 1 fact' );
is( $s->SrcFact[0]->sf_src_value, $sane1, 'DNE to sane - value' );


/**********************
 * 2) existing sane ... incoming insane (keep sane)
 */
$ts->TankFact[0]->sf_src_value = $insane1;
$ts->save();

run_tank();
ok( $report, 'sane to insane - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'sane to insane - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'sane to insane - tsrc_status' );
is( $report['done_upd'], 1, 'sane to insane - done count' );
is( $report['conflict'], 0, 'sane to insane - no conflict' );
is( count($s->SrcFact), 1, 'sane to insane - 1 fact' );
is( $s->SrcFact[0]->sf_src_value, $sane1, 'sane to insane - value' );


/**********************
 * 3) existing sane ... incoming sane (conflict)
 */
$ts->TankFact[0]->sf_src_value = $sane2;
$ts->save();

run_tank();
ok( $report, 'sane to sane - ok' );
is( $t->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'sane to sane - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'sane to sane - tsrc_status' );
is( $report['done_upd'], 0, 'sane to sane - 0 done' );
is( $report['conflict'], 1, 'sane to sane - 1 conflict' );
is( count($s->SrcFact), 1, 'sane to sane - 1 fact' );
is( $s->SrcFact[0]->sf_src_value, $sane1, 'sane to sane - value' );


/**********************
 * 4) existing DNE ... incoming insane
 */
$s->SrcFact[0]->delete();
$ts->TankFact[0]->tf_fact_id = $f_born;
$ts->TankFact[0]->sf_src_value = $insane1;
$ts->TankFact[0]->save();

run_tank();
ok( $report, 'DNE to insane - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'DNE to insane - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'DNE to insane - tsrc_status' );
is( $report['done_upd'], 1, 'DNE to insane - done count' );
is( count($s->SrcFact), 1, 'DNE to insane - 1 fact' );
is( $s->SrcFact[0]->sf_src_value, $insane1, 'DNE to insane - value' );


/**********************
 * 5) existing insane ... incoming sane (replace)
 */
$ts->TankFact[0]->sf_src_value = $sane1;
$ts->save();

run_tank();
ok( $report, 'insane to sane - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'insane to sane - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'insane to sane - tsrc_status' );
is( $report['done_upd'], 1, 'insane to sane - 1 done' );
is( $report['conflict'], 0, 'insane to sane - 0 conflict' );
is( count($s->SrcFact), 1, 'insane to sane - 1 fact' );
is( $s->SrcFact[0]->sf_src_value, $sane1, 'insane to sane - value' );


/**********************
 * 6) existing insane ... incoming insane
 */
$s->SrcFact[0]->sf_src_value = $insane2;
$s->SrcFact[0]->save();
$ts->TankFact[0]->sf_src_value = $insane3;
$ts->save();

run_tank();
ok( $report, 'insane to insane - ok' );
is( $t->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'insane to insane - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'insane to insane - tsrc_status' );
is( $report['done_upd'], 0, 'insane to insane - 0 done' );
is( $report['conflict'], 1, 'insane to insane - 1 conflict' );
is( count($s->SrcFact), 1, 'insane to insane - 1 fact' );
is( $s->SrcFact[0]->sf_src_value, $insane2, 'insane to insane - value' );
