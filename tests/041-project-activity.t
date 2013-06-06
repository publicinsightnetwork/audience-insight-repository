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

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// helper to fetch NEW project activity activity
$old_pa_ids = array();
function get_activity($prj_id) {
    global $conn, $old_pa_ids;
    $rs = $conn->fetchAll("select * from project_activity where pa_prj_id = "
        . "$prj_id order by pa_id asc");
    foreach ($rs as $idx => $row) {
        $pa_id = $row['pa_id'];
        if (in_array($pa_id, $old_pa_ids)) {
            unset($rs[$idx]);
        }
        else {
            $old_pa_ids[] = $pa_id;
        }
    }
    return array_values($rs);
}

// test data
$u = new TestUser();
$u->save();
$u2 = new TestUser();
$u2->save();
$o = new TestOrganization();
$o->save();
$o2 = new TestOrganization();
$o2->save();
define('AIR2_REMOTE_USER_ID', $u->user_id);

plan(27);

/**********************
 * Non-logging
 */
AIR2Logger::$ENABLE_LOGGING = false;
$p = new TestProject();
$p->save();

$act = get_activity($p->prj_id);
is( count($act), 0, 'new prj - no activity without remote user id' );

/**********************
 * Log new project
 */
AIR2Logger::$ENABLE_LOGGING = true;
$p->delete();
$p = new TestProject();
$p->save();

$act = get_activity($p->prj_id);
$desc1;
$last_act = isset($act[0]) ? $act[0] : null;
is( count($act), 1, 'new prj - new activity created!' );
if ($last_act) {
    is( $last_act['pa_cre_user'], $u->user_id, 'new prj - user_id set' );
    is( $last_act['pa_actm_id'], ActivityMaster::PROJECT_UPDATED, 'new prj - actm_id set' );
    $desc1 = $last_act['pa_desc'];
}
else {
    fail('new prj - user_id set');
    fail('new prj - actm_id set');
}

/**********************
 * Update project
 */
$old_name = $p->prj_name;
$p->prj_name = 'test2';
$p->save();

$act = get_activity($p->prj_id);
$desc2;
$last_act = isset($act[0]) ? $act[0] : null;
is( count($act), 1, 'update prj - new activity created!' );
if ($last_act) {
    is( $last_act['pa_cre_user'], $u->user_id, 'update prj - user_id set' );
    is( $last_act['pa_actm_id'], ActivityMaster::PROJECT_UPDATED, 'update prj - actm_id set' );
    $desc2 = $last_act['pa_desc'];
    isnt( $desc1, $desc2, 'update prj - different desc than insert' );

    // json decode the changed fields
    $json = json_decode($last_act['pa_notes'], true);
    is( $json['old']['prj_name'], $old_name, 'update prj - old prj_name' );
    is( $json['new']['prj_name'], $p->prj_name, 'update prj - new prj_name' );
}
else {
    fail('update prj - user_id set');
    fail('update prj - actm_id set');
    fail('update prj - different desc than insert');
    fail('update prj - old prj_name');
    fail('update prj - new prj_name');
}

/**********************
 * Perform an update that fails on the project
 */
try {
    $p->prj_name = null;
    $p->save();
    fail('fail update prj');
}
catch (Exception $e) {
    pass('fail update prj'); // should throw exception
}

$p->refresh();
is( $p->prj_name, 'test2', 'fail update prj - project transactional' );
$act = get_activity($p->prj_id);
is( count($act), 0, 'fail update prj - activity transactional' );

/**********************
 * Create ProjectOrg
 */
$po = new ProjectOrg();
$po->porg_prj_id = $p->prj_id;
$po->porg_org_id = $o->org_id;
$po->porg_contact_user_id = $u->user_id;
$po->save();

$act = get_activity($p->prj_id);
$desc3;
$last_act = isset($act[0]) ? $act[0] : null;
is( count($act), 1, 'new porg - new activity created!' );
if ($last_act) {
    is( $last_act['pa_cre_user'], $u->user_id, 'new porg - user_id' );
    is( $last_act['pa_actm_id'], ActivityMaster::PRJORGS_UPDATED, 'new porg - actm_id' );
    is( $last_act['pa_xid'], $o->org_id, 'new porg - xid' );
    is( $last_act['pa_ref_type'], 'O', 'new porg - ref_type' );
    $desc3 = $last_act['pa_desc'];
    isnt( $desc3, $desc1, 'new porg - desc different than new proj' );

    // json decode the changed fields
    $json = json_decode($last_act['pa_notes'], true);
    is( $json['new']['porg_org_id'], $o->org_id, 'new porg - org_id' );
}
else {
    fail('new porg - user_id');
    fail('new porg - actm_id');
    fail('new porg - xid');
    fail('new porg - ref_type');
    fail('new porg - desc different than new proj');
    fail('new porg - org_id');
}

/**********************
 * Update ProjectOrg
 */
$po->porg_contact_user_id = $u2->user_id;
$po->save();

$act = get_activity($p->prj_id);
$desc4;
$last_act = isset($act[0]) ? $act[0] : null;
is( count($act), 1, 'update porg - new activity created!' );
if ($last_act) {
    $desc4 = $last_act['pa_desc'];
    isnt( $desc4, $desc3, 'update porg - desc changed' );

    // json decode the changed fields
    $json = json_decode($last_act['pa_notes'], true);
    is( $json['old']['porg_contact_user_id'], $u->user_id, 'update porg - old contact_user_id' );
    is( $json['new']['porg_contact_user_id'], $u2->user_id, 'update porg - new contact_user_id' );
}
else {
    fail('update porg - desc changed');
    fail('update porg - old contact_user_id');
    fail('update porg - new contact_user_id');
}

/**********************
 * Delete ProjectOrg
 */
$po->delete();
$act = get_activity($p->prj_id);
$desc5;
$last_act = isset($act[0]) ? $act[0] : null;
is( count($act), 1, 'delete porg - new activity created!' );
if ($last_act) {
    $desc5 = $last_act['pa_desc'];
    isnt( $desc5, $desc4, 'delete porg - desc not update' );
    isnt( $desc5, $desc3, 'delete porg - desc not insert' );
}
else {
    fail('delete porg - desc not update');
    fail('delete porg - desc not insert');
}
