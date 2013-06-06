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
require_once APPPATH.'/../tests/models/TestUser.php';
require_once APPPATH.'/../tests/models/TestOrganization.php';
require_once APPPATH.'/../tests/models/TestProject.php';
require_once 'phperl/callperl.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$test_first = 'Test019_discriminate_10kFirst'; //used for cleanup

function make_tanksource($tank_id, $idx) {
    global $conn, $test_first;
    $flds = "tsrc_tank_id, tsrc_status, tsrc_cre_user, tsrc_upd_user, tsrc_cre_dtim, tsrc_upd_dtim, "
        ."src_username, src_first_name, src_last_name, src_middle_initial, src_pre_name, src_post_name, "
        ."smadd_context, smadd_line_1, smadd_line_2, smadd_city, smadd_state, smadd_cntry, smadd_zip, "
        ."sph_context, sph_country, sph_number, sph_ext, "
        ."sem_context, sem_email, sem_effective_date, sem_expire_date, "
        ."srcan_value";
    $ss = TankSource::$STATUS_NEW;
    $mc = SrcMailAddress::$CONTEXT_HOME;
    $pc = SrcPhoneNumber::$CONTEXT_CELL;
    $ec = SrcEmail::$CONTEXT_OTHER;
    $dt = air2_date();
    $email = str_pad($idx, 4, 0, STR_PAD_LEFT).'@test.com';
    $vals = array($tank_id, "'$ss'", 1, 1, "'$dt'", "'$dt'",
        "'$email'", "'$test_first'", "'TestLast'", "'T'", "'TestPre'", "'TestPost'",
        "'$mc'", "'Test Line 1'", "'Test Line 2'", "'TestCity'", "'MN'", "'US'", "'55555'",
        "'$pc'", "'123'", "'555-555-5555'", "'x123'",
        "'$ec'", "'$email'", "'$dt'", "'$dt'",
        "'Test Annotation Value'",
    );
    $vals = implode(', ', $vals);
    $conn->exec("insert into tank_source ($flds) values ($vals)");
    $id = $conn->lastInsertId();

    // create some facts for the source
    $facts = array(
        /* fact_id, tsrc_id, fv_id, src_value */
        "(1, $id, 1, NULL)",
        "(2, $id, 6, NULL)",
        "(3, $id, 11, NULL)",
        "(4, $id, 18, NULL)",
        "(7, $id, NULL, '1800')",
    );
    $facts = implode(', ', $facts);
    $fact_flds = 'tf_fact_id, tf_tsrc_id, sf_fv_id, sf_src_value';
    $conn->exec("insert into tank_fact ($fact_flds) values $facts");
    return $id;
}
class Source_Cleanup {
    function  __construct() {
        // cleanup previous aborted runs
        global $test_first;
        $conn = AIR2_DBManager::get_master_connection();
        $conn->exec("delete from source where src_first_name = '$test_first'");
    }
    function  __destruct() {
        global $test_first;
        $conn = AIR2_DBManager::get_master_connection();
        $conn->exec("delete from source where src_first_name = '$test_first'");
    }
}
$cleanup = new Source_Cleanup();


/**********************
 * Setup related objects
 */
$u = new TestUser();
$u->save();
$o = new TestOrganization();
$o->add_users(array($u), 4); //manager
$o->save();
$p = new TestProject();
$p->add_orgs(array($o));
$p->save();


/**********************
 * Setup the tank
 */
$t = new TestTank();
$t->tank_user_id = $u->user_id;
$t->tank_status = Tank::$STATUS_READY;
$t->TankOrg[0]->to_org_id = $o->org_id;
$t->TankActivity[0]->tact_actm_id = 10;
$t->TankActivity[0]->tact_prj_id = $p->prj_id;
$t->TankActivity[0]->tact_dtim = air2_date();
$t->TankActivity[0]->tact_desc = 'blah';
$t->TankActivity[0]->tact_notes = 'blah blah blah';
$t->TankActivity[0]->tact_actm_id = 11;
$t->TankActivity[0]->tact_prj_id = $p->prj_id;
$t->TankActivity[0]->tact_dtim = air2_date();
$t->TankActivity[0]->tact_desc = 'blah2';
$t->TankActivity[0]->tact_notes = 'blah2 blah2 blah2';
$t->save();


/**********************
 * Add a bunch o' stuff to the tank
 */
$TEST_SIZE = 200;
for ($i=0; $i<$TEST_SIZE; $i++) {
    make_tanksource($t->tank_id, $i);
}


plan(5);
/**********************
 * Run the import
 * 
 * Now that this is in perl, we can't actually trace the memory usage.
 * But let's run it anyways!
 */

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);

$t->refresh();
ok( $report, 'memleak - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'memleak - tank_status' );
is( $report['error'], 0, 'memleak - error count' );
is( $report['conflict'], 0, 'memleak - conflict count' );
is( $report['done_cre'], $TEST_SIZE, 'memleak - done count' );
