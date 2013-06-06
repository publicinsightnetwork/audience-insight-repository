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

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// unique names
$testname1 = '024-unique-columns-name1@test.com';
$testname2 = '024-unique-columns-name2@test.com';
$testname3 = '024-unique-columns-name3@test.com';
$testname4 = '024-unique-columns-name4@test.com';

// cleanup previously aborted run
$names = array($testname1, $testname2, $testname3, $testname4);
$del = 'delete from source where src_username = ? or src_id = '.
    '(select sem_src_id from src_email where sem_email = ?)';
$n = 0;
foreach ($names as $name) {
    $n += $conn->exec($del, array($name, $name));
}
//if ($n > 0) diag("CLEANED UP $n THINGS!");

$s1 = new TestSource();
$s1->src_username = $testname1;
$s1->save();
$s2 = new TestSource();
$s2->src_username = $testname2;
$s2->SrcEmail[]->sem_email = $testname2;
$s2->save();
$s3 = new TestSource();
$s3->SrcEmail[]->sem_email = $testname3;
$s3->save();

$tank = new TestTank();
$tank->tank_user_id = 1;
$tank->tank_type = 'F';
$tank->tank_status = Tank::$STATUS_READY;
$tank->save();

// setup tanksources
$ts1 = new TankSource();
$ts1->tsrc_tank_id = $tank->tank_id;
$ts1->sem_email = $testname1;
$ts1->src_middle_initial = '1';
$ts1->save();

$ts2 = new TankSource();
$ts2->tsrc_tank_id = $tank->tank_id;
$ts2->sem_email = $testname2;
$ts2->src_middle_initial = '2';
$ts2->save();

$ts3 = new TankSource();
$ts3->tsrc_tank_id = $tank->tank_id;
$ts3->sem_email = $testname3;
$ts3->src_middle_initial = '3';
$ts3->save();

$ts4 = new TankSource();
$ts4->tsrc_tank_id = $tank->tank_id;
$ts4->sem_email = $testname4;
$ts4->src_middle_initial = '4';
$ts4->save();

/**********************
 * Run the import
 */
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$s1->refresh();
$s2->refresh();
$tank->clearRelated();
$tank->refresh();
$ts1 = $tank->TankSource[0];
$ts2 = $tank->TankSource[1];
$ts3 = $tank->TankSource[2];
$ts4 = $tank->TankSource[3];


plan(26);
/**********************
 * Resultz!
 */
ok( $report, 'uniques - ok' );
is( $report['conflict'], 0, 'uniques - conflict count' );
is( $report['error'], 0, 'uniques - error count' );
is( $report['done_cre'], 2, 'uniques - create count' );
is( $report['done_upd'], 2, 'uniques - update count' );
is( $tank->tank_status, Tank::$STATUS_READY, 'uniques - tank_status' );
is( $ts1->tsrc_status, TankSource::$STATUS_DONE, 'uniques - tsrc1 status' );
is( $ts2->tsrc_status, TankSource::$STATUS_DONE, 'uniques - tsrc2 status' );
is( $ts3->tsrc_status, TankSource::$STATUS_DONE, 'uniques - tsrc3 status' );
is( $ts4->tsrc_status, TankSource::$STATUS_DONE, 'uniques - tsrc4 status' );

// tsrc1 should have created new source
ok( $ts1->src_id, 'uniques 1 - src_id set' );
isnt( $ts1->src_id, $s1->src_id, 'uniques 1 - did not identify src1' );
is( $ts1->Source->src_middle_initial, '1', 'uniques 1 - src_middle_initial' );
$uuid = $ts1->Source->src_uuid;
ok( preg_match("/$uuid/", $ts1->Source->src_username), 'uniques 1 - src_username has uuid' );
is( $ts1->Source->SrcEmail[0]->sem_email, $testname1, 'uniques 1 - sem_email' );

// tsrc2 identifies src2
ok( $ts2->src_id, 'uniques 2 - src_id set' );
is( $ts2->src_id, $s2->src_id, 'uniques 2 - identified src2' );
is( $ts2->Source->src_middle_initial, '2', 'uniques 2 - src_middle_initial' );

// tsrc3 identifies src3
ok( $ts3->src_id, 'uniques 3 - src_id set' );
is( $ts3->src_id, $s3->src_id, 'uniques 3 - identified src3' );
is( $ts3->Source->src_middle_initial, '3', 'uniques 3 - src_middle_initial' );
isnt( $ts3->Source->src_username, $testname3, 'uniques 3 - username unchanged' );

// tsrc4 creates new Source
ok( $ts4->src_id, 'uniques 4 - src_id set' );
is( $ts4->Source->src_middle_initial, '4', 'uniques 4 - src_middle_initial' );
is( $ts4->Source->src_username, $testname4, 'uniques 4 - src_username' );
is( $ts4->Source->SrcEmail[0]->sem_email, $testname4, 'uniques 4 - sem_email' );


/**********************
 * cleanup
 */
$n = 0;
foreach ($names as $name) {
    $n += $conn->exec($del, array($name, $name));
}
//if ($n > 0) diag("CLEANED UP $n THINGS!");
