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


plan(78);

/**********************
 * 1) blank mail address values
 */
//$ts->smadd_primary_flag = true;
$ts->smadd_context = SrcMailAddress::$CONTEXT_HOME;
$ts->smadd_line_1 = 'Address Line 1';
$ts->smadd_line_2 = 'Address Line 2';
$ts->smadd_city = 'AddressCity';
$ts->smadd_state = 'MN';
$ts->smadd_cntry = 'US';
$ts->smadd_zip = '55555';
$ts->smadd_lat = 12.5;
$ts->smadd_long = 13.5;
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
is( count($s->SrcMailAddress), 1, 'blank - 1 mail address' );
is( $s->SrcMailAddress[0]->smadd_primary_flag, true, 'blank - is primary' );


/**********************
 * 2) duplicate mail address values
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
is( count($s->SrcMailAddress), 1, 'dup - 1 mail address' );


/**********************
 * 3) new mail address --- ADD
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->smadd_primary_flag = true;
$ts->smadd_context = SrcMailAddress::$CONTEXT_WORK;
$ts->smadd_line_1 = 'Address2 Line 1';
$ts->smadd_line_2 = 'Address2 Line 2';
$ts->smadd_city = 'Address2City';
$ts->smadd_state = 'WI';
$ts->smadd_cntry = 'CN';
$ts->smadd_zip = '66666';
$ts->smadd_lat = 12.6;
$ts->smadd_long = 13.6;
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
is( count($s->SrcMailAddress), 2, 'new - 2 mail address' );
is( $s->SrcMailAddress[0]->smadd_primary_flag, false, 'new - 1st is not primary' );
is( $s->SrcMailAddress[1]->smadd_primary_flag, true, 'new - 2nd is primary' );


/**********************
 * 4) conflict -- ID by line_1
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->smadd_primary_flag = false; // IGNORED
$ts->smadd_context = SrcMailAddress::$CONTEXT_HOME;
$ts->smadd_line_1 = 'Address2 Line 1'; // IDENTIFY
$ts->smadd_line_2 = 'Address3 Line 2';
$ts->smadd_city = 'Address3City';
$ts->smadd_state = 'WA';
$ts->smadd_cntry = 'GM';
$ts->smadd_zip = '77777';
$ts->smadd_lat = 12.7;
$ts->smadd_long = 13.7;
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
is( count($s->SrcMailAddress), 2, 'conflict1 - 2 mail address' );
is( $s->SrcMailAddress[0]->smadd_primary_flag, false, 'conflict1 - 1st is not primary' );
is( $s->SrcMailAddress[1]->smadd_primary_flag, true, 'conflict1 - 2nd is STILL primary' );

$errs = json_decode($ts->tsrc_errors, true);
ok( isset($errs['initial']), 'conflict1 - initial conflicts' );
$cons = $errs['initial'];

ok( !isset($cons['smadd_primary_flag']), 'conflict1 - !primary' );
ok( isset($cons['smadd_context']),       'conflict1 - context' );
ok( !isset($cons['smadd_line_1']),       'conflict1 - !line1' );
ok( isset($cons['smadd_line_2']),        'conflict1 - line2' );
ok( isset($cons['smadd_city']),          'conflict1 - city' );
ok( isset($cons['smadd_state']),         'conflict1 - state' );
ok( isset($cons['smadd_cntry']),         'conflict1 - cntry' );
ok( isset($cons['smadd_zip']),           'conflict1 - zip' );
ok( isset($cons['smadd_lat']),           'conflict1 - lat' );
ok( isset($cons['smadd_long']),          'conflict1 - long' );


/**********************
 * 5) conflict -- ID by city
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->smadd_context = SrcMailAddress::$CONTEXT_OTHER;
$ts->smadd_line_1 = 'Address4 Line 1'; // IDENTIFY
$ts->smadd_line_2 = 'Address4 Line 2';
$ts->smadd_city = 'Address2City';
$ts->smadd_state = 'WA';
$ts->smadd_cntry = 'AA';
$ts->smadd_zip = '88888';
$ts->smadd_lat = 12.8;
$ts->smadd_long = 13.8;
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'conflict2 - ok' );
is( $t->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'conflict2 - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'conflict2 - tsrc_status' );
is( $report['conflict'], 1, 'conflict2 - conflict count' );
is( count($s->SrcMailAddress), 2, 'conflict2 - 2 mail address' );
is( $s->SrcMailAddress[0]->smadd_primary_flag, false, 'conflict2 - 1st is not primary' );
is( $s->SrcMailAddress[1]->smadd_primary_flag, true, 'conflict2 - 2nd is STILL primary' );

$errs = json_decode($ts->tsrc_errors, true);
ok( isset($errs['initial']), 'conflict2 - initial conflicts' );
$cons = $errs['initial'];

ok( !isset($cons['smadd_primary_flag']), 'conflict2 - !primary' );
ok( isset($cons['smadd_context']),       'conflict2 - context' );
ok( isset($cons['smadd_line_1']),        'conflict2 - line1' );
ok( isset($cons['smadd_line_2']),        'conflict2 - line2' );
ok( !isset($cons['smadd_city']),         'conflict2 - !city' );
ok( isset($cons['smadd_state']),         'conflict2 - state' );
ok( isset($cons['smadd_cntry']),         'conflict2 - cntry' );
ok( isset($cons['smadd_zip']),           'conflict2 - zip' );
ok( isset($cons['smadd_lat']),           'conflict2 - lat' );
ok( isset($cons['smadd_long']),          'conflict2 - long' );


/**********************
 * 6) conflict -- ID by zip
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->smadd_primary_flag = false;
$ts->smadd_context = SrcMailAddress::$CONTEXT_OTHER;
$ts->smadd_line_1 = 'Address5 Line 1'; // IDENTIFY
$ts->smadd_line_2 = 'Address5 Line 2';
$ts->smadd_city = 'Address5City';
$ts->smadd_state = 'AL';
$ts->smadd_cntry = 'BB';
$ts->smadd_zip = '66666';
$ts->smadd_lat = 12.9;
$ts->smadd_long = 13.9;
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'conflict3 - ok' );
is( $t->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'conflict3 - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'conflict3 - tsrc_status' );
is( $report['conflict'], 1, 'conflict3 - conflict count' );
is( count($s->SrcMailAddress), 2, 'conflict3 - 2 mail address' );
is( $s->SrcMailAddress[0]->smadd_primary_flag, false, 'conflict3 - 1st is not primary' );
is( $s->SrcMailAddress[1]->smadd_primary_flag, true, 'conflict3 - 2nd is STILL primary' );

$errs = json_decode($ts->tsrc_errors, true);
ok( isset($errs['initial']), 'conflict2 - initial conflicts' );
$cons = $errs['initial'];

ok( !isset($cons['smadd_primary_flag']), 'conflict3 - !primary' );
ok( isset($cons['smadd_context']),       'conflict3 - context' );
ok( isset($cons['smadd_line_1']),        'conflict3 - line1' );
ok( isset($cons['smadd_line_2']),        'conflict3 - line2' );
ok( isset($cons['smadd_city']),          'conflict3 - city' );
ok( isset($cons['smadd_state']),         'conflict3 - state' );
ok( isset($cons['smadd_cntry']),         'conflict3 - cntry' );
ok( !isset($cons['smadd_zip']),          'conflict3 - !zip' );
ok( isset($cons['smadd_lat']),           'conflict3 - lat' );
ok( isset($cons['smadd_long']),          'conflict3 - long' );


/**********************
 * 7) non-conflict -- blank (non-null) smadd_context
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->smadd_primary_flag = null;
$ts->smadd_context = '';
$ts->smadd_line_1 = null; // IDENTIFY
$ts->smadd_line_2 = null;
$ts->smadd_city = null;
$ts->smadd_state = null;
$ts->smadd_cntry = null;
$ts->smadd_zip = '55555';
$ts->smadd_lat = null;
$ts->smadd_long = null;
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'conflict4 - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'conflict4 - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'conflict4 - tsrc_status' );
is( $report['done_upd'], 1, 'conflict4 - done count' );
is( count($s->SrcMailAddress), 2, 'conflict4 - 2 mail address' );
is( $s->SrcMailAddress[0]->smadd_context, SrcMailAddress::$CONTEXT_HOME, 'conflict4 - context unchanged' );
