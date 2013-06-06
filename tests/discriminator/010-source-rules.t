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


plan(20);

/**********************
 * 1) blank source values
 */
$s->src_first_name = null;
$s->src_last_name = null;
$s->src_middle_initial = null;
$s->src_pre_name = null;
$s->src_post_name = null;
//$s->src_status = null; ... can't do that!
$s->src_channel = null;
$s->save();

$ts->src_first_name = 'FirstName';
$ts->src_last_name = 'LastName';
$ts->src_middle_initial = 'M';
$ts->src_pre_name = 'PreName';
$ts->src_post_name = 'PostName';
$ts->src_channel = Source::$CHANNEL_EVENT;
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'blank - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'blank - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'blank - tsrc_status' );
is( $report['done_upd'], 1, 'blank - done count' );


/**********************
 * 2) duplicate source values
 */
$s->src_last_name = 'LastName222';
$s->save();
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->src_last_name = 'LastName222';
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'dup - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'dup - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'dup - tsrc_status' );
is( $report['done_upd'], 1, 'dup - done count' );


/**********************
 * 3) changed source values
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->src_first_name = 'FirstName2';
$ts->src_last_name = 'LastName2';
$ts->src_middle_initial = 'N';
$ts->src_pre_name = 'PreName2';
$ts->src_post_name = 'PostName2';
$ts->src_channel = Source::$CHANNEL_ONLINE;
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'changed - ok' );
is( $t->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'changed - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'changed - tsrc_status' );
is( $report['done_upd'], 0, 'changed - done count' );
is( $report['conflict'], 1, 'changed - conflict count' );

$errs = json_decode($ts->tsrc_errors, true);

is( count($errs['initial']), 6, 'changed - 6 conflicts' );
ok( isset($errs['initial']['src_first_name']), 'changed - first conflict' );
ok( isset($errs['initial']['src_last_name']), 'changed - last conflict' );
ok( isset($errs['initial']['src_middle_initial']), 'changed - middle conflict' );
ok( isset($errs['initial']['src_pre_name']), 'changed - pre conflict' );
ok( isset($errs['initial']['src_post_name']), 'changed - post conflict' );
ok( isset($errs['initial']['src_channel']), 'changed - channel conflict' );
