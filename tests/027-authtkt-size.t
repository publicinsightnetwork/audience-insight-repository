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
require_once 'AirHttpTest.php';
require_once 'AirTestUtils.php';
require_once 'models/TestUser.php';
require_once 'models/TestOrganization.php';
require_once 'models/TestSource.php';

/**********************
 * INIT
 */
AIR2_DBManager::init();


/**********************
 * HELPER FUNCTIONS
 */
function join_user($usr, $org, $ar_id) {
    $i = $usr->UserOrg->count();
    $usr->UserOrg[$i]->uo_org_id = $org->org_id;
    $usr->UserOrg[$i]->uo_ar_id = $ar_id;
    $usr->UserOrg[$i]->uo_status = 'A';
    $usr->UserOrg[$i]->uo_notify_flag = true;
    $usr->UserOrg[$i]->uo_home_flag = false;
    $usr->save();
}


/**********************
 * SETUP
 */
$usr = new TestUser();
$usr->save();

// max out fields
// NOTE: 255 is the max username, but that's a bit ridiculous.  Let's go with
// something a bit less for this test.
$usr->user_username = str_pad($usr->user_username, 155, '0');
$usr->user_last_name = str_pad($usr->user_last_name, 64, '0');
$usr->user_first_name = str_pad($usr->user_first_name, 64, '0');
$usr->save();

// create a really-long-name org, and set as home
$o = new TestOrganization();
$o->add_users(array($usr));
$o->save();
$o->org_name = str_pad($o->org_name, 16, '0');
$o->UserOrg[0]->uo_home_flag = true;
$o->save();

// add user to all top-level orgs
$top_orgs = AIR2_Query::create()
    ->from('Organization')
    ->where('org_id != ?', $o->org_id)
    ->andWhere('org_parent_id is null')
    ->execute();
foreach ($top_orgs as $org) {
    join_user($usr, $org, 1);
}

// create the auth_tkt
$airuser = new AirUser();
$tkt = $airuser->create_tkt($usr, false, true);


/**********************
 * TESTS
 */
plan(1);
// The ONLY test ... will this fit in a cookie? (4K)
$size = strlen($tkt[AIR2_AUTH_TKT_NAME]);
ok( $size < 4096, "maxed-out user auth_tkt will fit in a cookie - $size" );


?>
