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

/**
 * NOTE: these tests are to make sure the tank/tank_sources lock properly
 * when the discriminator runs.  Also makes sure the discriminator won't run
 * on things in the wrong states.
 */

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
plan(41);

$tank = new TestTank();
$tank->tank_user_id = 1;
$tank->tank_type = Tank::$TYPE_FB;
for ($i=0; $i<5; $i++) {
    $s = new TestSource();
    $s->save();
    $tank->TankSource[$i]->tsrc_status = TankSource::$STATUS_NEW;
    $tank->TankSource[$i]->src_id = $s->src_id;
}
$tank->save();


/**********************
 * Tank in ready status
 */
$tank->tank_status = Tank::$STATUS_READY;
$tank->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh(true);

ok( $report, 'disc ready - ok' );
is( $report['done_upd'], 5, 'disc ready - updated 5');
is( $tank->tank_status, Tank::$STATUS_READY, 'disc ready - ends ready' );
is( $tank->tank_errors, null, 'disc ready - no errors' );
is( $tank->TankSource[0]->tsrc_status, TankSource::$STATUS_DONE, 'disc ready - tsrc0 done' );


/**********************
 * Tank in tsrc_conflicts status
 */
$tank->TankSource[0]->tsrc_status = TankSource::$STATUS_CONFLICT;
$tank->TankSource[1]->tsrc_status = TankSource::$STATUS_DONE;
$tank->TankSource[2]->tsrc_status = TankSource::$STATUS_CONFLICT;
$tank->TankSource[3]->tsrc_status = TankSource::$STATUS_NEW;
$tank->TankSource[4]->tsrc_status = TankSource::$STATUS_CONFLICT;
$tank->tank_status = Tank::$STATUS_TSRC_CONFLICTS;
$tank->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh(true);

ok( $report, 'disc conflicts - ok' );
is( $report['done_upd'], 1, 'disc conflicts - updated 1');
is( $report['skipped'], 4, 'disc conflicts - skipped 4');
is( $tank->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'disc conflicts - ends conflicts' );
is( $tank->tank_errors, null, 'disc conflicts - no errors' );
is( $tank->TankSource[0]->tsrc_status, TankSource::$STATUS_CONFLICT, 'disc conflicts - tsrc0 still conflict' );
is( $tank->TankSource[3]->tsrc_status, TankSource::$STATUS_DONE, 'disc conflicts - tsrc3 done' );


/**********************
 * Tank in tsrc_errors status
 */
$tank->TankSource[0]->tsrc_status = TankSource::$STATUS_ERROR;
$tank->TankSource[1]->tsrc_status = TankSource::$STATUS_NEW;
$tank->tank_status = Tank::$STATUS_TSRC_ERRORS;
$tank->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh(true);

ok( $report, 'disc errors - ok' );
is( $report['done_upd'], 1, 'disc errors - updated 1');
is( $report['skipped'], 4, 'disc errors - skipped 4');
is( $tank->tank_status, Tank::$STATUS_TSRC_ERRORS, 'disc errors - ends errors' );
is( $tank->tank_errors, null, 'disc errors - no errors' );
is( $tank->TankSource[0]->tsrc_status, TankSource::$STATUS_ERROR, 'disc errors - tsrc0 still error' );
is( $tank->TankSource[1]->tsrc_status, TankSource::$STATUS_DONE, 'disc errors - tsrc1 done' );


/**********************
 * Locked (running) tank
 */
$tank->tank_status = Tank::$STATUS_LOCKED;
$tank->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh(true);

ok( !$report, 'disc lock - NOT ok' );
is( $tank->tank_status, Tank::$STATUS_LOCKED, 'disc lock - ends locked' );
is( $tank->tank_errors, null, 'disc lock - no errors' );


/**********************
 * Locked (errors) tank
 */
$tank->tank_status = Tank::$STATUS_LOCKED_ERROR;
$tank->TankSource[2]->tsrc_status = TankSource::$STATUS_LOCKED;
$tank->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh(true);

ok( !$report, 'disc lock errors - NOT ok' );
is( $tank->tank_status, Tank::$STATUS_LOCKED_ERROR, 'disc lock errors - ends locked' );
is( $tank->tank_errors, null, 'disc lock errors - no errors' );
is( $tank->TankSource[2]->tsrc_status, TankSource::$STATUS_LOCKED, 'disc lock errors - tsrc2 locked' );


/**********************
 * Partial locked tank (tank unlocked, tsrc locked)
 */
$tank->tank_status = Tank::$STATUS_READY;
$tank->save();
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh(true);
is( $tank->tank_status, Tank::$STATUS_TSRC_ERRORS, 'disc partial - ends errors' );


/**********************
 * Resolve individual tank_sources
 */
is( $tank->TankSource[0]->tsrc_status, TankSource::$STATUS_ERROR, 'tsrc0 - init' );
$stat = CallPerl::exec('AIR2::TankSource->discriminate', $tank->TankSource[0]->tsrc_id);
is( $stat, TankSource::$STATUS_DONE, 'tsrc0 - error to done' );

is( $tank->TankSource[1]->tsrc_status, TankSource::$STATUS_DONE, 'tsrc1 - init' );
$stat = CallPerl::exec('AIR2::TankSource->discriminate', $tank->TankSource[1]->tsrc_id);
is( $stat, TankSource::$STATUS_DONE, 'tsrc1 - done to done' );

is( $tank->TankSource[2]->tsrc_status, TankSource::$STATUS_LOCKED, 'tsrc2 - init' );
try {
    $stat = CallPerl::exec('AIR2::TankSource->discriminate', $tank->TankSource[2]->tsrc_id);
    fail( 'tsrc2 - no exception' );
}
catch (Exception $e) {
    pass( 'tsrc2 - exception' );
}

is( $tank->TankSource[4]->tsrc_status, TankSource::$STATUS_CONFLICT, 'tsrc4 - init' );
$stat = CallPerl::exec('AIR2::TankSource->discriminate', $tank->TankSource[4]->tsrc_id);
is( $stat, TankSource::$STATUS_RESOLVED, 'tsrc4 - conflict to resolved' );

$tank->refresh(true);
is( $tank->tank_status, Tank::$STATUS_READY, 'tsrcs - tank back to ready' );


/**********************
 * Empty tank
 */
$tank->tank_status = Tank::$STATUS_READY;
$tank->save();
foreach ($tank->TankSource as $tsrc) {
    $tsrc->delete();
}

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh(true);

ok( $report, 'disc empty - ok' );
is( $report['done_upd'], 0, 'disc empty - updated 0');
is( $report['skipped'], 0, 'disc empty - skipped 0');
is( $tank->tank_status, Tank::$STATUS_READY, 'disc empty - ends ready' );
is( $tank->tank_errors, null, 'disc empty - no errors' );
