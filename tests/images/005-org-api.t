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

$o = new TestOrganization();
$o->add_users(array($u), AdminRole::MANAGER);
$o->save();
$uuid = $o->org_uuid;

$api = new AIRAPI($u);

$csv_dir = dirname(__FILE__).'/examples';
$jpg_file = "$csv_dir/org-banner.jpg";
$gif_file = "$csv_dir/org-banner.gif";


plan(40);

/**********************
 * Initial Check
 */
$rs = $api->fetch("organization/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'fetch - okay' );
ok( array_key_exists('Banner', $rs['radix']), 'fetch - Banner set' );
is( $rs['radix']['Banner'], null, 'fetch - Banner null' );
ok( array_key_exists('Logo', $rs['radix']), 'fetch - Logo set' );
is( $rs['radix']['Logo'], null, 'fetch - Logo null' );


/**********************
 * Create a banner
 */
$rs = $api->update("organization/$uuid", array('banner' => $jpg_file));
is( $rs['code'], AIRAPI::OKAY, 'set banner - okay' );
ok( isset($rs['radix']['Banner']), 'set banner - isset' );
is( $rs['radix']['Banner']['img_file_name'], 'org-banner.jpg', 'set banner - filename' );

$original = $rs['radix']['Banner']['original'];
$thumb    = $rs['radix']['Banner']['thumb'];
$medium   = $rs['radix']['Banner']['medium'];
like( $original, '/banner\.png/', 'set banner - original' );
like( $thumb, '/banner_thumb\.png/', 'set banner - thumb' );
like( $medium, '/banner_medium\.png/', 'set banner - medium' );

$thing1 = $browser->http_get($original);
is( $browser->resp_code(), 200, 'get original - 200' );
is( $browser->resp_content_type(), 'image/png', 'get original - content type' );
$browser->http_get($thumb);
is( $browser->resp_code(), 200, 'get thumb - 200' );
is( $browser->resp_content_type(), 'image/png', 'get thumb - content type' );
$browser->http_get($medium);
is( $browser->resp_code(), 200, 'get medium - 200' );
is( $browser->resp_content_type(), 'image/png', 'get medium - content type' );


/**********************
 * Create a logo
 */
$rs = $api->update("organization/$uuid", array('logo' => $jpg_file));
is( $rs['code'], AIRAPI::OKAY, 'set logo - okay' );
ok( isset($rs['radix']['Logo']), 'set logo - isset' );
is( $rs['radix']['Logo']['img_file_name'], 'org-banner.jpg', 'set logo - filename' );

$logo_orig = $rs['radix']['Logo']['original'];
$browser->http_get($logo_orig);
is( $browser->resp_code(), 200, 'get original - 200' );
is( $browser->resp_content_type(), 'image/png', 'get original - content type' );
ok( $logo_orig != $original, 'set logo - original differs from banner' );


sleep(1);


/**********************
 * Update banner and logo
 */
$rs = $api->update("organization/$uuid", array('banner' => $gif_file, 'logo' => $gif_file));
is( $rs['code'], AIRAPI::OKAY, 'update both - okay' );
ok( isset($rs['radix']['Banner']), 'update both - isset banner' );
ok( isset($rs['radix']['Logo']), 'update both - isset logo' );
is( $rs['radix']['Banner']['img_file_name'], 'org-banner.gif', 'update both - banner filename' );
is( $rs['radix']['Logo']['img_file_name'], 'org-banner.gif', 'update both - logo filename' );

$up_original = $rs['radix']['Banner']['original'];
isnt( $up_original, $original, 'update both - banner timestamp changed' );
$up_logo_orig = $rs['radix']['Logo']['original'];
isnt( $up_logo_orig, $logo_orig, 'update both - logo timestamp changed' );

$thing2 = $browser->http_get($up_original);
is( $browser->resp_code(), 200, 'get updated original - 200' );
is( $browser->resp_content_type(), 'image/png', 'get updated original - content type' );
ok( $thing1 != $thing2, 'binary files differ' );


/**********************
 * Delete logo
 */
$rs = $api->update("organization/$uuid", array('logo' => null));
is( $rs['code'], AIRAPI::OKAY, 'unset logo - okay' );

ok( array_key_exists('Logo', $rs['radix']), 'unset logo - Logo set' );
is( $rs['radix']['Logo'], null, 'unset logo - Logo null' );

ok( isset($rs['radix']['Banner']), 'unset logo - isset banner' );
is( $rs['radix']['Banner']['img_file_name'], 'org-banner.gif', 'unset logo - banner filename' );

$browser->http_get($up_logo_orig);
is( $browser->resp_code(), 404, 'get original - logo 404' );
$browser->http_get($original);
is( $browser->resp_code(), 200, 'get original - banner 200' );
