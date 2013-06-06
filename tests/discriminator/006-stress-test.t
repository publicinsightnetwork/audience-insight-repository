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

/* helper functions */
function get_test_username($idx) {
    return "006TESTSOURCEUSERNAME$idx";
}
function delete_test_sources() {
    $q = Doctrine_Query::create();
    $q->delete('Source');
    $usrname = get_test_username('');
    $q->where("src_username like '$usrname%'");
    $rows = $q->execute();
    return $rows;
}


AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

/* cleanup any previous aborted run */
delete_test_sources();

$tank = new TestTank();
$tank->tank_user_id = 1;
$tank->tank_type = 'F';
$tank->tank_status = Tank::$STATUS_READY;
$tank->save();

$inq = new TestInquiry();
for ($i=0; $i<10; $i++) {
    $inq->Question[$i]->ques_value = "Test Question number $i";
    $inq->Question[$i]->ques_dis_seq = 10 * $i;
}
$inq->save();

// responses by sources already in AIR2 (id's by src_username)
$sources = array();
for ($i=0; $i<10; $i++) {
    $s = new TestSource();
    $s->save();
    $sources[] = $s;

    $ts = new TankSource();
    $ts->tsrc_tank_id = $tank->tank_id;
    $ts->src_username = $s->src_username;
    $ts->save();

    $trs = new TankResponseSet();
    $trs->trs_tsrc_id = $ts->tsrc_id;
    $trs->srs_inq_id = $inq->inq_id;
    $trs->srs_date = air2_date();
    $trs->srs_type = 'T'; //test
    foreach ($inq->Question as $idx => $ques) {
        $trs->TankResponse[$idx]->tr_tsrc_id = $ts->tsrc_id;
        $trs->TankResponse[$idx]->sr_ques_id = $ques->ques_id;
        $trs->TankResponse[$idx]->sr_orig_value = "Test Response $idx";
    }
    $trs->save();
}

// responses by sources new to AIR2
for ($i=0; $i<100; $i++) {
    $ts = new TankSource();
    $ts->tsrc_tank_id = $tank->tank_id;
    $ts->src_username = get_test_username($i);
    $ts->save();

    $trs = new TankResponseSet();
    $trs->trs_tsrc_id = $ts->tsrc_id;
    $trs->srs_inq_id = $inq->inq_id;
    $trs->srs_date = air2_date();
    $trs->srs_type = 'T'; //test
    foreach ($inq->Question as $idx => $ques) {
        $trs->TankResponse[$idx]->tr_tsrc_id = $ts->tsrc_id;
        $trs->TankResponse[$idx]->sr_ques_id = $ques->ques_id;
        $trs->TankResponse[$idx]->sr_orig_value = "Test Answer number $idx";
    }
    $trs->save();

    $ts->free();
    unset($ts);
    $trs->free(true);
    unset($trs);
}


plan(8);

/**********************
 * Run the import
 */
$t_start = microtime(true);
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$t_end = microtime(true);
$tank->refresh();

ok( $report, 'stress - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'stress - tank_status' );
is( $report['error'], 0, 'stress - error count' );
is( $report['conflict'], 0, 'stress - conflict count' );
is( $report['done_upd']+$report['done_cre'], 110, 'stress - done count' );
is( $inq->SrcResponseSet->count(), 110, 'stress - resp set count' );

$rspcount = 0;
foreach ($inq->Question as $ques) {
    $count = $ques->SrcResponse->count();
    $rspcount += $count;
}
is( $rspcount, 1100, 'stress - resp count' );

/**********************
 * Arbitrary runtime test
 */
$t = round($t_end - $t_start, 1);
ok( $t, "stress - imported 1100 responses in $t seconds" );


// delete sources first, to prevent data integrity errors
foreach ($sources as $s) $s->delete();
$rows = delete_test_sources();