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

require_once 'Test.php';
require_once 'app/init.php';
require_once 'AirTestUtils.php';
require_once 'models/TestProject.php';
require_once 'models/TestOrganization.php';
require_once 'models/TestUser.php';
require_once 'models/TestSource.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// helper to fetch NEW source activity
$old_sact_ids = array();
function get_activity($src_id) {
    global $conn, $old_sact_ids;
    $rs = $conn->fetchAll("select * from src_activity where sact_src_id = "
        . "$src_id order by sact_id asc");
    foreach ($rs as $idx => $row) {
        $sact_id = $row['sact_id'];
        if (in_array($sact_id, $old_sact_ids)) {
            unset($rs[$idx]);
        }
        else {
            $old_sact_ids[] = $sact_id;
        }
    }
    return array_values($rs);
}

// test data
$u = new TestUser();
$u->save();
$o = new TestOrganization();
$o->save();
$o2 = new TestOrganization();
$o2->save();
define('AIR2_REMOTE_USER_ID', $u->user_id);

plan(46);

/**********************
 * New/update source
 */
AIR2Logger::$ENABLE_LOGGING = true;
$s = new TestSource();
$s->save();

$act = get_activity($s->src_id);
is( count($act), 0, 'new src - no activity' );

$s->src_first_name = 'blah';
$s->save();

$act = get_activity($s->src_id);
$last_act = isset($act[0]) ? $act[0] : null;
is( count($act), 1, 'update src - new activity created!' );
if ($last_act) {
    is( $last_act['sact_cre_user'], $u->user_id, 'update src - cre_user set' );
    is( $last_act['sact_actm_id'], ActivityMaster::SRCINFO_UPDATED, 'update src - actm_id set' );
}
else {
    fail('update src - user_id set');
    fail('update src - actm_id set');
}

/**********************
 * SrcEmail
 */
$se = new SrcEmail();
$se->sem_src_id = $s->src_id;
$se->sem_email = $s->src_username.'@test.com';
$se->sem_primary_flag = true;
$se->sem_context = SrcEmail::$CONTEXT_PERSONAL;
$se->save();

$act = get_activity($s->src_id);
$last_act = isset($act[0]) ? $act[0] : null;
is( count($act), 1, 'new email - new activity created!' );
if ($last_act) {
    is( $last_act['sact_cre_user'], $u->user_id, 'new email - cre_user' );
    is( $last_act['sact_actm_id'], ActivityMaster::SRCINFO_UPDATED, 'new email - actm_id' );
    ok( preg_match('/added/', $last_act['sact_desc']), 'new email - desc 1' );
    ok( preg_match('/email/', $last_act['sact_desc']), 'new email - desc 2' );
}
else {
    fail('new email - user_id');
    fail('new email - actm_id');
    fail('new email - desc 1');
    fail('new email - desc 2');
}

$se->sem_context = SrcEmail::$CONTEXT_WORK;
$se->save();

$act = get_activity($s->src_id);
$last_act = isset($act[0]) ? $act[0] : null;
is( count($act), 1, 'update email - new activity created!' );
if ($last_act) {
    ok( preg_match('/updated/', $last_act['sact_desc']), 'update email - desc 1' );
    ok( preg_match('/email/', $last_act['sact_desc']), 'update email - desc 2' );
}
else {
    fail('update email - desc 1');
    fail('update email - desc 2');
}

$se->delete();

$act = get_activity($s->src_id);
$last_act = isset($act[0]) ? $act[0] : null;
is( count($act), 1, 'delete email - new activity created!' );
if ($last_act) {
    ok( preg_match('/removed/', $last_act['sact_desc']), 'delete email - desc 1' );
    ok( preg_match('/email/', $last_act['sact_desc']), 'delete email - desc 2' );
}
else {
    fail('delete email - desc 1');
    fail('delete email - desc 2');
}

/**********************
 * SrcPhoneNumber (abbreviated, since we did C-U-D with email)
 */
$sp = new SrcPhoneNumber();
$sp->sph_src_id = $s->src_id;
$sp->sph_number = '5555555555';
$sp->sph_context = SrcPhoneNumber::$CONTEXT_CELL;
$sp->save();

$act = get_activity($s->src_id);
$last_act = isset($act[0]) ? $act[0] : null;
is( count($act), 1, 'new phone - new activity created!' );
if ($last_act) {
    is( $last_act['sact_cre_user'], $u->user_id, 'new phone - cre_user' );
    is( $last_act['sact_actm_id'], ActivityMaster::SRCINFO_UPDATED, 'new phone - actm_id' );
    ok( preg_match('/added/', $last_act['sact_desc']), 'new phone - desc 1' );
    ok( preg_match('/phone/', $last_act['sact_desc']), 'new phone - desc 2' );
}
else {
    fail('new phone - user_id');
    fail('new phone - actm_id');
    fail('new phone - desc 1');
    fail('new phone - desc 2');
}

// fail to update (check transactionality)
$sp->sph_context = 'toomanyletters';
try {
    $sp->save();
    fail("update phone - exception");
}
catch (Exception $e) {
    pass("update phone - exception");
}
$sp->refresh();
is( $sp->sph_context, SrcPhoneNumber::$CONTEXT_CELL, 'update phone - not updated' );
$act = get_activity($s->src_id);
is( count($act), 0, 'update phone - no new activity (transactional)' );

/**********************
 * SrcMailAddress (abbreviated, since we did C-U-D with email)
 */
$sm = new SrcMailAddress();
$sm->smadd_src_id = $s->src_id;
$sm->smadd_context = SrcMailAddress::$CONTEXT_HOME;
$sm->smadd_line_1 = 'test line 1';
$sm->smadd_city = 'St. Paul';
$sm->save();

$sm->smadd_city = 'Denver';
$sm->save();

$act = get_activity($s->src_id);
$last_act = isset($act[1]) ? $act[1] : null;
is( count($act), 2, 'cre/upd address - 2 activities created' );
if ($last_act) {
    is( $last_act['sact_cre_user'], $u->user_id, 'upd address - cre_user' );
    is( $last_act['sact_actm_id'], ActivityMaster::SRCINFO_UPDATED, 'upd address - actm_id' );
    ok( preg_match('/updated/', $last_act['sact_desc']), 'upd address - desc 1' );
    ok( preg_match('/address/', $last_act['sact_desc']), 'upd address - desc 2' );

    // json decode the changed fields
    $json = json_decode($last_act['sact_notes'], true);
    is( $json['old']['smadd_city'], 'St. Paul', 'upd address - old city' );
    is( $json['new']['smadd_city'], 'Denver', 'upd address - new city' );
}
else {
    fail('upd address - user_id');
    fail('upd address - actm_id');
    fail('upd address - desc 1');
    fail('upd address - desc 2');
    fail('upd address - old city');
    fail('upd address - new city');
}

/**********************
 * SrcFacts
 */
$f_gender = $conn->fetchOne("select fact_id from fact where fact_identifier = 'gender'", array(), 0);
$fv_gender = $conn->fetchOne("select fv_id from fact_value where fv_fact_id = $f_gender", array(), 0);

$sf = new SrcFact();
$sf->sf_src_id = $s->src_id;
$sf->sf_fact_id = $f_gender;
$sf->sf_fv_id = $fv_gender;
$sf->save();

$act = get_activity($s->src_id);
$last_act = isset($act[0]) ? $act[0] : null;
is( count($act), 1, 'create fact - new activity created' );
if ($last_act) {
    is( $last_act['sact_cre_user'], $u->user_id, 'create fact - cre_user' );
    is( $last_act['sact_actm_id'], ActivityMaster::SRCINFO_UPDATED, 'create fact - actm_id' );
    ok( preg_match('/added/', $last_act['sact_desc']), 'create fact - desc verb' );
    ok( preg_match('/gender/i', $last_act['sact_desc']), 'create fact - desc fact name' );
}
else {
    fail('create fact - cre_user');
    fail('create fact - actm_id');
    fail('create fact - desc verb');
    fail('create fact - desc fact name');
}

$sf->sf_src_fv_id = $fv_gender;
$sf->save();
$sf->delete();
$act = get_activity($s->src_id);
is( count($act), 2, 'upd/delete fact - 2 activities created' );

/**********************
 * SrcVita
 */
$sv1 = new SrcVita();
$sv1->sv_src_id = $s->src_id;
$sv1->sv_type = SrcVita::$TYPE_EXPERIENCE;
$sv1->sv_start_date = air2_date();
$sv1->sv_value = 'Bank Robber';
$sv1->sv_basis = 'Canada';
$sv1->save();

$sv2 = new SrcVita();
$sv2->sv_src_id = $s->src_id;
$sv2->sv_type = SrcVita::$TYPE_INTEREST;
$sv2->sv_notes = 'A bunch of text here';
$sv2->save();

$act = get_activity($s->src_id);
$act_1 = isset($act[0]) ? $act[0] : null;
$act_2 = isset($act[1]) ? $act[1] : null;
is( count($act), 2, 'create vita - 2 activities created' );
if ($act_1 && $act_2) {
    ok( preg_match('/experience/i', $act_1['sact_desc']), 'create vita - desc vita type 1' );
    ok( preg_match('/interest/i', $act_2['sact_desc']), 'create vita - desc vita type 2' );
}
else {
    fail('create vita - desc vita type 1');
    fail('create vita - desc vita type 2');
}

/**********************
 * SrcOrgs
 */
$s->add_orgs(array($o));
$s->add_orgs(array($o2), SrcOrg::$STATUS_OPTED_OUT);
$s->save();
$s->clearRelated(); // prevent delete error

$act = get_activity($s->src_id);
$act_1 = isset($act[0]) ? $act[0] : null;
$act_2 = isset($act[1]) ? $act[1] : null;
is( count($act), 2, 'srcorg - 2 activities created' );
if ($act_1 && $act_2) {
    ok( preg_match('/opted-in/i', $act_1['sact_desc']), 'srcorg - desc 1' );
    is( $act_1['sact_xid'], $o->org_id, 'srcorg - xid 1' );
    is( $act_1['sact_actm_id'], ActivityMaster::SRCINFO_UPDATED, 'srcorg - actm 1' );
    ok( preg_match('/opted-out/i', $act_2['sact_desc']), 'srcorg - desc 2' );
    is( $act_2['sact_xid'], $o2->org_id, 'srcorg - xid 2' );
    is( $act_2['sact_actm_id'], ActivityMaster::SRCINFO_UPDATED, 'srcorg - actm 2' );
}
else {
    fail('srcorg - desc 1');
    fail('srcorg - xid 1');
    fail('srcorg - actm 1');
    fail('srcorg - desc 2');
    fail('srcorg - xid 2');
    fail('srcorg - actm 2');
}

