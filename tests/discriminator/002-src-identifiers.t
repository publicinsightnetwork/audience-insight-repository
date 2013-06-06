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

// cleanup for any new sources created
class TestCleanup {
    private $test_source_idents = array(
        'src_id'       => array(),
        'src_uuid'     => array(),
        'src_username' => array(),
    );
    function add($column, $value) {
        $this->test_source_idents[$column][] = $value;
    }
    function __destruct() {
        $conn = AIR2_DBManager::get_master_connection();
        foreach ($this->test_source_idents as $col => $array) {
            $q = "delete from source where $col = ?";
            foreach ($array as $val) {
                $num = $conn->exec($q, array($val));
                if ($num > 1) {
                    echo "\nPROBLEM: deleted $num Sources on $col -> $val\n";
                }
            }
        }
    }
}
$cleanup = new TestCleanup();

// test data
$tank = new TestTank();
$tank->tank_user_id = 1;
$tank->tank_type = 'F';
$tank->tank_status = Tank::$STATUS_READY;
$tank->save();
$tank_id = $tank->tank_id;
$tsrc = new TankSource();
$tsrc->tsrc_tank_id = $tank->tank_id;
$tsrc->tsrc_status = TankSource::$STATUS_NEW;
$tsrc->save();
$tsrc_id = $tsrc->tsrc_id;

$src = new TestSource();
$src->src_username = 'testsourceblah45@blah.gov';
$src->save();
$src_id = $src->src_id;
$email = new SrcEmail();
$email->sem_src_id = $src->src_id;
$email->sem_context = 'L';
$email->sem_email = 'testsourceblah995@blah.gov';
$email->save();
$sem_id = $email->sem_id;

plan(75);


/**********************
 * No identifiers
 */
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh();
$tsrc->refresh();

ok( $report, 'no id - ok' );
is( $report['error'], 1, 'no id - error 1');
is( $tank->tank_status, Tank::$STATUS_TSRC_ERRORS, 'no id - ends tsrc errors' );
is( $tank->tank_errors, null, 'no id - no tank errors' );
is( $tsrc->tsrc_status, TankSource::$STATUS_ERROR, 'no id - tsrc errors' );
like( $tsrc->tsrc_errors, '/no identifier/i', 'no id - tsrc error msg' );


/**********************
 * Identify by src_id
 */
$tsrc->tsrc_status = TankSource::$STATUS_NEW;
$tsrc->src_id = 99999999;
$tsrc->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh();
$tsrc->refresh();

ok( $report, 'bad id - ok' );
is( $report['error'], 1, 'bad id - error 1');
is( $tank->tank_status, Tank::$STATUS_TSRC_ERRORS, 'bad id - ends tsrc errors' );
is( $tank->tank_errors, null, 'bad id - no tank errors' );
is( $tsrc->tsrc_status, TankSource::$STATUS_ERROR, 'bad id - tsrc errors' );
like( $tsrc->tsrc_errors, '/invalid src_id/i', 'bad id - tsrc error msg' );

// switch to correct src_id
$tsrc->tsrc_status = TankSource::$STATUS_NEW;
$tsrc->src_id = $src->src_id;
$tsrc->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh();
$tsrc->refresh();

ok( $report, 'good id - ok' );
is( $report['done_upd'], 1, 'good id - updated 1');
is( $tank->tank_status, Tank::$STATUS_READY, 'good id - ends tsrc ready' );
is( $tank->tank_errors, null, 'good id - no tank errors' );
is( $tsrc->tsrc_status, TankSource::$STATUS_DONE, 'good id - tsrc done' );


/**********************
 * Identify by src_uuid
 */
$tsrc->tsrc_status = TankSource::$STATUS_NEW;
$tsrc->src_id = null;
$tsrc->src_uuid = 'FAKEUUIDHERE';
$tsrc->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh();
$tsrc->refresh();

ok( $report, 'bad uuid - ok' );
is( $report['error'], 1, 'bad uuid - error 1');
is( $tank->tank_status, Tank::$STATUS_TSRC_ERRORS, 'bad uuid - ends tsrc errors' );
is( $tank->tank_errors, null, 'bad uuid - no tank errors' );
is( $tsrc->tsrc_status, TankSource::$STATUS_ERROR, 'bad uuid - tsrc errors' );
like( $tsrc->tsrc_errors, '/invalid src_uuid/i', 'bad uuid - tsrc error msg' );

// switch to correct src_uuid
$tsrc->tsrc_status = TankSource::$STATUS_NEW;
$tsrc->src_uuid = $src->src_uuid;
$tsrc->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh();
$tsrc->refresh();

ok( $report, 'good uuid - ok' );
is( $report['done_upd'], 1, 'good uuid - updated 1');
is( $tank->tank_status, Tank::$STATUS_READY, 'good uuid - ends tsrc ready' );
is( $tank->tank_errors, null, 'good uuid - no tank errors' );
is( $tsrc->tsrc_status, TankSource::$STATUS_DONE, 'good uuid - tsrc done' );
is( $tsrc->src_id, $src->src_id, 'good uuid - src_id set' );


/**********************
 * Identify by src_username
 */
$bad_username = 'badtestusername002@blah.biz';
$cleanup->add('src_username', $bad_username);
$tsrc->tsrc_status = TankSource::$STATUS_NEW;
$tsrc->src_id = null;
$tsrc->src_uuid = null;
$tsrc->src_username = $bad_username;
$tsrc->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh();
$tsrc->refresh();

ok( $report, 'bad username - ok' );
is( $report['done_cre'], 1, 'bad username - created 1');
is( $tank->tank_status, Tank::$STATUS_READY, 'bad username - ends tsrc ready' );
is( $tank->tank_errors, null, 'bad username - no tank errors' );
is( $tsrc->tsrc_status, TankSource::$STATUS_DONE, 'bad username - tsrc done' );
is( $tsrc->tsrc_created_flag, true, 'bad username - tsrc created flag' );

$new_src = $tsrc->Source;
if ($new_src) {
    is( $new_src->exists(), true, 'bad username - created source' );
    ok( $new_src->src_id, 'bad username - src_id' );
    is( $new_src->src_username, $bad_username, 'bad username - src_username' );
}
else {
    fail('bad username - created source');
    fail('bad username - src_id');
    fail('bad username - src_username');
}

// switch to correct src_username
$tsrc->tsrc_status = TankSource::$STATUS_NEW;
$tsrc->tsrc_created_flag = false;
$tsrc->src_id = null;
$tsrc->src_uuid = null;
$tsrc->src_username = $src->src_username;
$tsrc->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh();
$tsrc->refresh();

ok( $report, 'good username - ok' );
is( $report['done_upd'], 1, 'good username - updated 1');
is( $tank->tank_status, Tank::$STATUS_READY, 'good username - ends tsrc ready' );
is( $tank->tank_errors, null, 'good username - no tank errors' );
is( $tsrc->tsrc_status, TankSource::$STATUS_DONE, 'good username - tsrc done' );
is( $tsrc->src_id, $src->src_id, 'good username - src_id set' );

// camelcase should ID, but not update (case insensitive field - #2468
$tsrc->tsrc_status = TankSource::$STATUS_NEW;
$tsrc->tsrc_created_flag = false;
$tsrc->src_id = null;
$tsrc->src_uuid = null;
$tsrc->src_username = 'teStSourCeBLAH45@blah.GOV';
$tsrc->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh();
$tsrc->refresh();
$src->refresh();

ok( $report, 'camelcase username - ok' );
is( $report['done_upd'], 1, 'camelcase username - updated 1');
is( $tank->tank_status, Tank::$STATUS_READY, 'camelcase username - ends tsrc ready' );
is( $tank->tank_errors, null, 'camelcase username - no tank errors' );
is( $tsrc->tsrc_status, TankSource::$STATUS_DONE, 'camelcase username - tsrc done' );
is( $tsrc->src_id, $src->src_id, 'camelcase username - src_id set' );
isnt( $src->src_username, $tsrc->src_username, 'camelcase username - not updated' );

/**********************
 * Identify by email
 */
$bad_email = 'badTestUsername002@blah.edu';
$cleanup->add('src_username', $bad_email);
$tsrc->clearRelated();
$tsrc->tsrc_status = TankSource::$STATUS_NEW;
$tsrc->tsrc_created_flag = false;
$tsrc->src_id = null;
$tsrc->src_uuid = null;
$tsrc->src_username = null;
$tsrc->sem_email = $bad_email;
$tsrc->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh();
$tsrc->refresh();

ok( $report, 'bad email - ok' );
is( $report['done_cre'], 1, 'bad email - created 1');
is( $tank->tank_status, Tank::$STATUS_READY, 'bad email - ends tsrc ready' );
is( $tank->tank_errors, null, 'bad email - no tank errors' );
is( $tsrc->tsrc_status, TankSource::$STATUS_DONE, 'bad email - tsrc done' );
is( $tsrc->tsrc_created_flag, true, 'bad email - tsrc created flag' );

$new_src = $tsrc->Source;
if ($new_src) {
    is( $new_src->exists(), true, 'bad email - created source' );
    ok( $new_src->src_id, 'bad email - src_id' );
    is( $new_src->src_username, strtolower($bad_email), 'bad email - src_username' );
    is( $new_src->SrcEmail[0]->sem_email, strtolower($bad_email), 'bad email - sem_email' );
}
else {
    fail('bad email - created source');
    fail('bad email - src_id');
    fail('bad email - src_username');
    fail('bad email - sem_email');
}

// switch to correct email
$email_before = $email->sem_email;
$tsrc->clearRelated();
$tsrc->tsrc_status = TankSource::$STATUS_NEW;
$tsrc->tsrc_created_flag = false;
$tsrc->src_id = null;
$tsrc->src_uuid = null;
$tsrc->src_username = null;
$tsrc->sem_email = $email->sem_email;
$tsrc->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh();
$tsrc->refresh();
$email->refresh();

ok( $report, 'good email - ok' );
is( $report['done_upd'], 1, 'good email - updated 1');
is( $tank->tank_status, Tank::$STATUS_READY, 'good email - ends tsrc ready' );
is( $tank->tank_errors, null, 'good email - no tank errors' );
is( $tsrc->tsrc_status, TankSource::$STATUS_DONE, 'good email - tsrc done' );
is( $tsrc->src_id, $src->src_id, 'good email - src_id set' );
is( $email->sem_email, $email_before, 'good email - sem_email' );

// camelcase should ID, and should NOT cause a conflict on sem_email!
$tsrc->clearRelated();
$tsrc->tsrc_status = TankSource::$STATUS_NEW;
$tsrc->tsrc_created_flag = false;
$tsrc->src_id = null;
$tsrc->src_uuid = null;
$tsrc->src_username = null;
$tsrc->sem_email = 'tEstSouRCeBLah995@blAh.gOv';
$tsrc->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->refresh();
$tsrc->refresh();
$email->refresh();

ok( $report, 'camelcase email - ok' );
is( $report['done_upd'], 1, 'camelcase email - updated 1');
is( $tank->tank_status, Tank::$STATUS_READY, 'camelcase email - ends tsrc ready' );
is( $tank->tank_errors, null, 'camelcase email - no tank errors' );
is( $tsrc->tsrc_status, TankSource::$STATUS_DONE, 'camelcase email - tsrc done' );
is( $tsrc->src_id, $src->src_id, 'camelcase email - src_id set' );
is( $email->sem_email, $email_before, 'camelcase email - sem_email' );
