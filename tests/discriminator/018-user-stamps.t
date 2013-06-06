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
require_once APPPATH.'/../tests/models/TestUser.php';
require_once 'phperl/callperl.php';

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// cleanup
class AIR2_Source_Cleanup {
    public $uname;
    function  __construct($usrname) {
        $this->uname = $usrname;
    }
    function  __destruct() {
        $s = Doctrine::getTable('Source')->findOneBy('src_username', $this->uname);
        if ($s) $s->delete();
    }
}

$usr = new TestUser();
$usr->save();

$tank = new TestTank();
$tank->tank_user_id = $usr->user_id;
$tank->tank_type = Tank::$TYPE_CSV;
$tank->tank_status = Tank::$STATUS_READY;
$tank->save();

$ts = new TankSource();
$ts->tsrc_tank_id = $tank->tank_id;
$ts->src_username = 'TESTTANKSOURCEUSER';
$ts->src_first_name = 'TESTUSER';
$ts->src_last_name = 'TESTUSER';
$ts->src_channel = Source::$CHANNEL_ONLINE;
$ts->smadd_line_1 = 'First Line';
$ts->smadd_city = 'Nowheresville';
$ts->save();

// destructor will cleanup for us
$clean = new AIR2_Source_Cleanup($ts->src_username);


plan(12);
/**********************
 * Import new source
 */
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh(true);
$ts = $tank->TankSource[0];

ok( $report, 'new source - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'new source - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'new source - tsrc_status' );
is( $report['done_cre'], 1, 'new source - done count' );


/**********************
 * Check the source's userstamps
 */
$s = Doctrine::getTable('Source')->findOneBy('src_username', $ts->src_username);
ok( $s && $s->exists(), 'new source - exists in DB' );
is( $s->src_first_name, $ts->src_first_name, 'new source - first name' );
is( $s->src_cre_user, $tank->tank_user_id, 'new source - cre_user' );
is( $s->src_upd_user, $tank->tank_user_id, 'new source - upd_user' );
is( count($s->SrcMailAddress), 1, 'new source - count smadd' );
$add = $s->SrcMailAddress[0];
is( $add->smadd_line_1, $ts->smadd_line_1, 'new source - smadd_line_1' );
is( $add->smadd_cre_user, $tank->tank_user_id, 'new source - smadd_cre_user' );
is( $add->smadd_upd_user, $tank->tank_user_id, 'new source - smadd_upd_user' );
