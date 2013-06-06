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
$uuid = $u->user_uuid;

$api = new AIRAPI($u);

$csv_dir = dirname(__FILE__).'/examples';
$png_file = "$csv_dir/user.png";
$jpg_file = "$csv_dir/user.jpg";


plan(28);

/**********************
 * Initial Check
 */
$rs = $api->fetch("user/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'fetch - okay' );
ok( array_key_exists('Avatar', $rs['radix']), 'fetch - Avatar set' );
is( $rs['radix']['Avatar'], null, 'fetch - Avatar null' );


/**********************
 * Create an avatar
 */
$rs = $api->update("user/$uuid", array('avatar' => $png_file));
is( $rs['code'], AIRAPI::OKAY, 'set avatar - okay' );
ok( isset($rs['radix']['Avatar']), 'set avatar - isset' );
is( $rs['radix']['Avatar']['img_file_name'], 'user.png', 'set avatar - filename' );

$original = $rs['radix']['Avatar']['original'];
$thumb    = $rs['radix']['Avatar']['thumb'];
$medium   = $rs['radix']['Avatar']['medium'];
like( $original, '/avatar\.png/', 'set avatar - original' );
like( $thumb, '/avatar_thumb\.png/', 'set avatar - thumb' );
like( $medium, '/avatar_medium\.png/', 'set avatar - medium' );

$thing1 = $browser->http_get($original);
is( $browser->resp_code(), 200, 'get original - 200' );
is( $browser->resp_content_type(), 'image/png', 'get original - content type' );
$browser->http_get($thumb);
is( $browser->resp_code(), 200, 'get thumb - 200' );
is( $browser->resp_content_type(), 'image/png', 'get thumb - content type' );
$browser->http_get($medium);
is( $browser->resp_code(), 200, 'get medium - 200' );
is( $browser->resp_content_type(), 'image/png', 'get medium - content type' );

sleep(1);


/**********************
 * Update avatar
 */
$rs = $api->update("user/$uuid", array('avatar' => $jpg_file));
is( $rs['code'], AIRAPI::OKAY, 'update avatar - okay' );
ok( isset($rs['radix']['Avatar']), 'update avatar - isset' );
is( $rs['radix']['Avatar']['img_file_name'], 'user.jpg', 'update avatar - filename' );

$up_original = $rs['radix']['Avatar']['original'];
isnt( $up_original, $original, 'update avatar - timestamp changed' );

$thing2 = $browser->http_get($up_original);
is( $browser->resp_code(), 200, 'get updated original - 200' );
is( $browser->resp_content_type(), 'image/png', 'get updated original - content type' );
ok( $thing1 != $thing2, 'binary files differ' );


/**********************
 * Delete avatar
 */
$rs = $api->update("user/$uuid", array('avatar' => null));
is( $rs['code'], AIRAPI::OKAY, 'unset avatar - okay' );
ok( array_key_exists('Avatar', $rs['radix']), 'unset avatar - Avatar set' );
is( $rs['radix']['Avatar'], null, 'unset avatar - Avatar null' );

$browser->http_get($original);
is( $browser->resp_code(), 404, 'get original - 404' );
$browser->http_get($thumb);
is( $browser->resp_code(), 404, 'get thumb - 404' );
$browser->http_get($medium);
is( $browser->resp_code(), 404, 'get medium - 404' );
