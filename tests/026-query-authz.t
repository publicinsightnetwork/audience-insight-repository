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
$browser = new AirHttpTest();
$browser->set_content_type(AirHttpTest::$JSON);


/**********************
 * HELPER FUNCTIONS
 */
function user_nav($src, $expected_code, $test_name) {
    global $browser;
    $r = $browser->http_get("/source/".$src->src_uuid);
    is( $browser->resp_code(), $expected_code, $test_name.' resp code' );
}


/**********************
 * SETUP
 */
// create some parent-child organizations
$org_top = new TestOrganization();
$org_top->save();
$org_b1 = new TestOrganization();
$org_b1->org_parent_id = $org_top->org_id;
$org_b1->save();
$org_b2 = new TestOrganization();
$org_b2->org_parent_id = $org_top->org_id;
$org_b2->save();

// create some sources and opt them into organizations
$src_none = new TestSource();
$src_none->save();

$src_top = new TestSource();
$src_top->add_orgs(array($org_top));
$src_top->save();

$src_bottom1 = new TestSource();
$src_bottom1->add_orgs(array($org_b1));
$src_bottom1->save();

$src_bottom2 = new TestSource();
$src_bottom2->add_orgs(array($org_b2));
$src_bottom2->save();

$src_both = new TestSource();
$src_both->add_orgs(array($org_top, $org_b1));
$src_both->save();

// create some users for us to masquerade as
$usr_none = new TestUser();
$usr_none->save();
$usr_top = new TestUser();
$usr_top->save();
$usr_bottom = new TestUser();
$usr_bottom->save();
$usr_no_bottom = new TestUser();
$usr_no_bottom->save();
$usr_sys = Doctrine::getTable('User')->find(1);

// join users to orgs
$org_top->add_users(array($usr_top, $usr_no_bottom));
$org_top->save();
$org_b1->add_users(array($usr_bottom));
$org_b1->add_users(array($usr_no_bottom), 1);
$org_b1->save();

/**********************
 * TESTS
 */
plan(25);

$browser->set_user($usr_none);
user_nav($src_top, 403, 'usrnone-srctop');
user_nav($src_bottom1, 403, 'usrnone-srcbottom1');
user_nav($src_bottom2, 403, 'usrnone-srcbottom2');
user_nav($src_both, 403, 'usrnone-srcboth');
user_nav($src_none, 403, 'usrnone-srcnone');

$browser->set_user($usr_top);
user_nav($src_top, 200, 'usrtop-srctop');
user_nav($src_bottom1, 200, 'usrtop-srcbottom1');
user_nav($src_bottom2, 200, 'usrtop-srcbottom2');
user_nav($src_both, 200, 'usrtop-srcboth');
user_nav($src_none, 403, 'usrtop-srcnone');

$browser->set_user($usr_bottom);
user_nav($src_top, 200, 'usrbottom-srctop');
user_nav($src_bottom1, 200, 'usrbottom-srcbottom1');
user_nav($src_bottom2, 403, 'usrbottom-srcbottom2');
user_nav($src_both, 200, 'usrbottom-srcboth');
user_nav($src_none, 403, 'usrbottom-srcnone');

$browser->set_user($usr_no_bottom);
user_nav($src_top, 200, 'usrnobottom-srctop');
user_nav($src_bottom1, 403, 'usrnobottom-srcbottom1');
user_nav($src_bottom2, 200, 'usrnobottom-srcbottom2');
user_nav($src_both, 200, 'usrnobottom-srcboth');
user_nav($src_none, 403, 'usrnobottom-srcnone');

$browser->set_user($usr_sys);
user_nav($src_top, 200, 'usrsys-srctop');
user_nav($src_bottom1, 200, 'usrsys-srcbottom1');
user_nav($src_bottom2, 200, 'usrsys-srcbottom2');
user_nav($src_both, 200, 'usrsys-srcboth');
user_nav($src_none, 200, 'usrsys-srcnone');

?>
