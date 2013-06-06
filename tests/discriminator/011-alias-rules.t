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
$s->src_first_name = 'First';
$s->src_last_name = 'Last';
$s->save();
$t = new TestTank();
$t->tank_user_id = 1;
$t->tank_type = Tank::$TYPE_FB;
$t->tank_status = Tank::$STATUS_READY;
$t->TankSource[0]->src_id = $s->src_id;
$t->save();
$ts = $t->TankSource[0];
$t->clearRelated();


plan(25);

/**********************
 * 1) no alias set
 */
$ts->src_first_name = 'AliasFirst';
$ts->src_last_name = 'AliasLast';
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'blank - ok' );
is( $t->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'blank - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'blank - tsrc_status' );
is( $report['conflict'], 1, 'blank - conflict count' );
is( count($s->SrcAlias), 0, 'blank - no src_alias' );


/**********************
 * 2) with existing alias
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->save();

$s->SrcAlias[0]->sa_first_name = 'AliasFirst';
$s->SrcAlias[1]->sa_last_name = 'AliasLast';
$s->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'w/alias - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'w/alias - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'w/alias - tsrc_status' );
is( $report['done_upd'], 1, 'w/alias - done count' );
is( $s->src_first_name, 'First', 'w/alias - first same' );
is( $s->src_last_name, 'Last', 'w/alias - last same' );
is( count($s->SrcAlias), 2, 'w/alias - still just 2 src_alias' );


/**********************
 * 3) create a new alias
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->src_first_name = 'AliasFirst2';
$ts->src_last_name = 'AliasLast2';
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'new alias - ok' );
is( $t->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'new alias - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'new alias - tsrc_status' );
is( $report['conflict'], 1, 'new alias - conflict count' );
is( $s->src_first_name, 'First', 'new alias - first same' );
is( $s->src_last_name, 'Last', 'new alias - last same' );
is( count($s->SrcAlias), 2, 'new alias - still just 2 src_alias' );

$ops = array(
    'src_first_name' => 'R',
    'src_last_name' => 'A',
);
$stat = CallPerl::exec('AIR2::TankSource->discriminate', $ts->tsrc_id, $ops);
$s->refresh();
$s->clearRelated();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $stat, 'create - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'create - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_RESOLVED, 'create - tsrc_status' );
is( $s->src_first_name, 'AliasFirst2', 'create - first changed' );
is( $s->src_last_name, 'Last', 'create - last same' );
is( count($s->SrcAlias), 3, 'create - now 3 src_alias' );
