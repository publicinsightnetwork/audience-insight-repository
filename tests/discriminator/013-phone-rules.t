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
$s = new TestSource();
$s->save();
$t = new TestTank();
$t->tank_user_id = 1;
$t->tank_type = Tank::$TYPE_FB;
$t->tank_status = Tank::$STATUS_READY;
$t->TankSource[0]->src_id = $s->src_id;
$t->save();
$ts = $t->TankSource[0];
$t->clearRelated();


plan(32);

/**********************
 * 1) blank phone values
 */
$ts->sph_primary_flag = false; //will be ignored
$ts->sph_context = SrcPhoneNumber::$CONTEXT_CELL;
$ts->sph_country = 'AAA';
$ts->sph_number = '6515555555';
$ts->sph_ext = 'x123';
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'blank - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'blank - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'blank - tsrc_status' );
is( $report['done_upd'], 1, 'blank - done count' );
is( count($s->SrcPhoneNumber), 1, 'blank - 1 mail address' );
is( $s->SrcPhoneNumber[0]->sph_primary_flag, true, 'blank - is primary' );


/**********************
 * 2) duplicate phone values
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'dup - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'dup - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'dup - tsrc_status' );
is( $report['done_upd'], 1, 'dup - done count' );
is( count($s->SrcPhoneNumber), 1, 'dup - 1 mail address' );
is( $s->SrcPhoneNumber[0]->sph_primary_flag, true, 'dup - still primary' );


/**********************
 * 3) new phone --- ADD
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->sph_primary_flag = true;
$ts->sph_context = SrcPhoneNumber::$CONTEXT_HOME;
$ts->sph_country = 'BBB';
$ts->sph_number = '9525555555';
$ts->sph_ext = 'x345';
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'new - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'new - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'new - tsrc_status' );
is( $report['done_upd'], 1, 'new - done count' );
is( count($s->SrcPhoneNumber), 2, 'new - 2 phones' );
is( $s->SrcPhoneNumber[0]->sph_primary_flag, false, 'new - 1st is not primary' );
is( $s->SrcPhoneNumber[1]->sph_primary_flag, true, 'new - 2nd is primary' );


/**********************
 * 4) conflict -- ID by number
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->sph_primary_flag = false; //will be ignored
$ts->sph_context = SrcPhoneNumber::$CONTEXT_WORK;
$ts->sph_country = 'CCC';
$ts->sph_number = '6515555555';
$ts->sph_ext = 'x345';
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'conflict1 - ok' );
is( $t->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'conflict1 - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'conflict1 - tsrc_status' );
is( $report['conflict'], 1, 'conflict1 - conflict count' );
is( count($s->SrcPhoneNumber), 2, 'conflict1 - 2 phones' );
is( $s->SrcPhoneNumber[0]->sph_primary_flag, false, 'conflict1 - 1st is not primary' );
is( $s->SrcPhoneNumber[1]->sph_primary_flag, true, 'conflict1 - 2nd is STILL primary' );

$errs = json_decode($ts->tsrc_errors, true);
ok( isset($errs['initial']), 'conflict1 - initial conflicts' );
$cons = $errs['initial'];

ok( !isset($cons['sph_primary_flag']), 'conflict1 - !primary' );
ok( isset($cons['sph_context']),       'conflict1 - context' );
ok( isset($cons['sph_country']),       'conflict1 - country' );
ok( !isset($cons['sph_number']),       'conflict1 - number' );
ok( isset($cons['sph_ext']),           'conflict1 - extension' );
