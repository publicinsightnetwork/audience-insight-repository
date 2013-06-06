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
 * 1) blank email values
 */
$ts->sem_primary_flag = false; //will be ignored
$ts->sem_context = SrcEmail::$CONTEXT_PERSONAL;
$ts->sem_email = 'harold@blah.com';
$ts->sem_effective_date = air2_date(strtotime('-1 week'));
$ts->sem_expire_date = air2_date(strtotime('+1 year'));
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'blank  - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'blank - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'blank - tsrc_status' );
is( $report['done_upd'], 1, 'blank - done count' );
is( count($s->SrcEmail), 1, 'blank - 1 email' );
is( $s->SrcEmail[0]->sem_primary_flag, true, 'blank - is primary' );


/**********************
 * 2) duplicate email
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

ok( $report, 'dup  - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'dup - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'dup - tsrc_status' );
is( $report['done_upd'], 1, 'dup - done count' );
is( count($s->SrcEmail), 1, 'dup - 1 email' );
is( $s->SrcEmail[0]->sem_primary_flag, true, 'dup - still primary' );


/**********************
 * 3) new email --- ADD
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->sem_primary_flag = true;
$ts->sem_context = SrcEmail::$CONTEXT_WORK;
$ts->sem_email = 'johnny@longtone.com';
$ts->sem_effective_date = air2_date(strtotime('-2 week'));
$ts->sem_expire_date = air2_date(strtotime('+1 month'));
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'new  - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'new - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'new - tsrc_status' );
is( $report['done_upd'], 1, 'new - done count' );
is( count($s->SrcEmail), 2, 'new - 2 email' );
is( $s->SrcEmail[0]->sem_primary_flag, false, 'new - 1st is not primary' );
is( $s->SrcEmail[1]->sem_primary_flag, true, 'new - 2nd is primary' );


/**********************
 * 4) conflict -- ID by email
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->sem_primary_flag = false;
$ts->sem_context = SrcEmail::$CONTEXT_OTHER;
$ts->sem_email = 'johnny@longtone.com';
$ts->sem_effective_date = air2_date(strtotime('-4 week'));
$ts->sem_expire_date = air2_date(strtotime('+4 month'));
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'conflict1  - ok' );
is( $t->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'conflict1 - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'conflict1 - tsrc_status' );
is( $report['conflict'], 1, 'conflict1 - conflict count' );
is( count($s->SrcEmail), 2, 'conflict1 - 2 email' );
is( $s->SrcEmail[0]->sem_primary_flag, false, 'conflict1 - 1st is not primary' );
is( $s->SrcEmail[1]->sem_primary_flag, true, 'conflict1 - 2nd is STILL primary' );

$errs = json_decode($ts->tsrc_errors, true);
ok( isset($errs['initial']), 'conflict1 - initial conflicts' );
$cons = $errs['initial'];

ok( !isset($cons['sem_primary_flag']),  'conflict1 - !primary' );
ok( isset($cons['sem_context']),        'conflict1 - context' );
ok( !isset($cons['sem_email']),         'conflict1 - !email' );
ok( isset($cons['sem_effective_date']), 'conflict1 - effective' );
ok( isset($cons['sem_expire_date']),    'conflict1 - expire' );
