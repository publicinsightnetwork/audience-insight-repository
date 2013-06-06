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

// unique names (use unique last names, since username can change)
$uuid1 = air2_str_to_uuid('023-nosuchemail-1');
$uuid2 = air2_str_to_uuid('023-nosuchemail-2');
$testemail1 = "$uuid1@nosuchemail.org";
$testemail2 = "$uuid2@nosuchemail.org";

// cleanup previously aborted run
$del = 'delete from source where src_last_name = ?';
$conn->exec($del, array($uuid1));
$conn->exec($del, array($uuid2));

$s1 = new TestSource();
$s1->src_username = $testemail1;
$s1->SrcEmail[]->sem_email = $testemail1;
$s1->save();

$tank = new TestTank();
$tank->tank_user_id = 1;
$tank->tank_type = 'F';
$tank->tank_status = Tank::$STATUS_READY;
$tank->save();

// setup tanksources
$ts1 = new TankSource();
$ts1->tsrc_tank_id = $tank->tank_id;
$ts1->sem_email = $testemail1;
$ts1->src_last_name = $uuid1;
$ts1->save();

$ts2 = new TankSource();
$ts2->tsrc_tank_id = $tank->tank_id;
$ts2->sem_email = $testemail2;
$ts2->src_last_name = $uuid2;
$ts2->save();

/**********************
 * Run the import
 */
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$s1->refresh();
$tank->clearRelated();
$tank->refresh();
$ts1 = $tank->TankSource[0];
$ts2 = $tank->TankSource[1];


plan(22);
/**********************
 * Resultz!
 */
ok( $report, 'nosuchemail - ok' );
is( $report['conflict'], 0, 'nosuchemail - conflict count' );
is( $report['error'], 0, 'nosuchemail - error count' );
is( $report['done_upd'], 1, 'nosuchemail - done upd' );
is( $report['done_cre'], 1, 'nosuchemail - done cre' );
is( $tank->tank_status, Tank::$STATUS_READY, 'nosuchemail - tank_status' );
is( $ts1->tsrc_status, TankSource::$STATUS_DONE, 'nosuchemail - tsrc1 status' );
is( $ts2->tsrc_status, TankSource::$STATUS_DONE, 'nosuchemail - tsrc2 status' );
is( $ts1->tsrc_created_flag, false, 'nosuchemail - tsrc1 updated' );
is( $ts2->tsrc_created_flag, true, 'nosuchemail - tsrc2 created' );

// tsrc1 identifies src1
ok( $ts1->src_id, 'nosuchemail 1 - src_id set' );
is( $ts1->src_id, $s1->src_id, 'nosuchemail 1 - identified src1' );
is( $ts1->Source->src_last_name, $uuid1, 'nosuchemail 1 - src_last_name' );

// tsrc2 creates new Source
ok( $ts2->src_id, 'nosuchemail 2 - src_id set' );
isnt( $ts2->src_id, $s1->src_id, 'nosuchemail 2 - did not identify src1' );
is( $ts2->Source->src_last_name, $uuid2, 'nosuchemail 2 - src_last_name' );
isnt( $ts2->Source->src_username, $testemail2, 'nosuchemail 2 - username changed' );
isnt( $ts2->Source->SrcEmail[0]->sem_email, $testemail2, 'nosuchemail 2 - email changed' );

// username/email should be generated from uuid
$uuid = $ts2->Source->src_uuid;
$email = "$uuid@nosuchemail.org";
is( $ts2->src_username, $email, 'nosuchemail 2 - tsrc username' );
is( $ts2->sem_email, $email, 'nosuchemail 2 - tsrc email' );
is( $ts2->Source->src_username, $email, 'nosuchemail 2 - src username' );
is( $ts2->Source->SrcEmail[0]->sem_email, $email, 'nosuchemail 2 - src email' );

/**********************
 * cleanup
 */
$n = $conn->exec($del, array($uuid1));
$n += $conn->exec($del, array($uuid2));
//if ($n > 0) diag("CLEANED UP $n THINGS!");
