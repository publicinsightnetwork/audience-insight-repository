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
require_once 'rframe/AIRAPI.php';
$tdir = APPPATH.'../tests';
require_once "$tdir/Test.php";
require_once "$tdir/AirHttpTest.php";
require_once "$tdir/models/TestUser.php";
require_once "$tdir/models/TestOrganization.php";
require_once "$tdir/models/TestProject.php";
require_once "$tdir/models/TestInquiry.php";
require_once "$tdir/models/TestBin.php";
require_once "$tdir/models/TestSource.php";


/**********************
 * Init
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$browser = new AirHttpTest();
$browser->set_content_type(AirHttpTest::$HTML);
$browser->base_url = ''; //base_url will already be attached


/**********************
 * Setup test data
 */
$u = new TestUser();
$u->save();

$project = new TestProject();
$project->save();

$o = new TestOrganization();
$o->add_users(array($u), AdminRole::MANAGER);
$o->save();

$project->add_orgs(array($o));
$project->save();

$inq = new TestInquiry();
$inq->add_orgs(array($o));
$inq->add_projects(array($project));
$inq->save();
$uuid = $inq->inq_uuid;

$api = new AIRAPI($u);

$csv_dir = dirname(__FILE__).'/examples';
$jpg_file = "$csv_dir/org-banner.jpg";
$gif_file = "$csv_dir/org-banner.gif";


plan(24);

/**********************
 * Initial Check
 */
$rs = $api->fetch("inquiry/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'fetch - okay' );
ok( array_key_exists('Logo', $rs['radix']), 'fetch - Logo set' );
is( $rs['radix']['Logo'], null, 'fetch - Logo null' );

// check the in-one-level resource
$rs = $api->fetch("inquiry/$uuid/logo");
is( $rs['code'], AIRAPI::ONE_DNE, 'fetch logo - DNE' );
//diag_dump( $rs );

/**********************
 * Create Logo for parent Org
 */
$rs = $api->update("organization/".$o->org_uuid, array('logo' => $gif_file));
is( $rs['code'], AIRAPI::OKAY, "create parent org logo - okay");
//diag_dump( $rs );

/**********************
 * Create a logo
 */
$rs = $api->create("inquiry/$uuid/logo", array('logo' => $jpg_file));
is( $rs['code'], AIRAPI::OKAY, 'set logo - okay' );
//diag_dump( $rs );
ok( isset($rs['radix']), 'set logo - isset' );
is( $rs['radix']['img_file_name'], 'org-banner.jpg', 'set logo - filename' );
$inq_logo_radix = $rs['radix'];

$logo_orig = $rs['radix']['original'];
$thing1 = $browser->http_get($logo_orig);

// check via parent api
$rs = $api->fetch("inquiry/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'fetch - okay' );
ok( array_key_exists('Logo', $rs['radix']), 'fetch - Logo set' );
is( $rs['radix']['Logo'], $inq_logo_radix, 'fetch - Logo via parent' );
isnt( $rs['radix']['InqOrg'][0]['OrgLogo'], null, "fetch parent, OrgLogo defined");
//diag_dump( $rs );

sleep(1);


/**********************
 * Update logo
 */
$rs = $api->update("inquiry/$uuid/logo", array('logo' => $gif_file));
is( $rs['code'], AIRAPI::OKAY, 'update logo - okay' );
ok( isset($rs['radix']), 'update logo - isset logo' );
is( $rs['radix']['img_file_name'], 'org-banner.gif', 'update logo - logo filename' );

$up_logo_orig = $rs['radix']['original'];
isnt( $up_logo_orig, $logo_orig, 'update logo - logo timestamp changed' );

$thing2 = $browser->http_get($up_logo_orig);
is( $browser->resp_code(), 200, 'get updated original - 200' );
is( $browser->resp_content_type(), 'image/png', 'get updated original - content type' );
ok( $thing1 != $thing2, 'binary files differ' );


/**********************
 * Delete logo
 */
$rs = $api->delete("inquiry/$uuid/logo");
is( $rs['code'], AIRAPI::OKAY, 'unset logo - okay' );

$rs = $api->fetch("inquiry/$uuid");
ok( array_key_exists('Logo', $rs['radix']), 'unset logo - Logo set' );
is( $rs['radix']['Logo'], null, 'unset logo - Logo null' );

$rs = $api->fetch("inquiry/$uuid/logo");
is( $rs['code'], AIRAPI::ONE_DNE, 'unset logo - fetch-one DNE' );

$browser->http_get($up_logo_orig);
is( $browser->resp_code(), 404, 'get original - logo 404' );
