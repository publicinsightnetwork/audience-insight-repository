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
$browser->set_content_type(AirHttpTest::$JSON);


/**********************
 * Setup test data
 */
$u = new TestUser();
$u->save();

$api = new AIRAPI($u);

$csv_dir = dirname(__FILE__).'/examples';
$png_file = "$csv_dir/user.png";
$jpg_file = "$csv_dir/user.jpg";


plan(55);

/**********************
 * 1) Check initial data
 */
is( !$u->Avatar, null, 'init - avatar null' );

try {
    $u->Avatar->img_file_name = 'TEST';
    fail('init - direct setting throws exception');
}
catch (Exception $e) {
    pass('init - direct setting throws exception');
}

try {
    $u->Avatar->save();
    fail('init - null avatar saving fails');
}
catch (Exception $e) {
    pass('init - null avatar saving fails');
}


/**********************
 * 2) Set as png
 */
$u->Avatar->set_image($png_file);
ok( $u->Avatar->img_dtim, 'png - dtim not null' );
is( $u->Avatar->get_image(), null, 'png - image initially null' );
$u->save();

// mock base url, so we can get timestamped assets
function base_url() { return "http://blah.com/"; }
$av = $u->Avatar->get_image(true);

ok( $av, 'png - image not null' );
ok( $u->Avatar->img_dtim, 'png - dtim not null' );

ok( $av['original'], 'png - original is set' );
ok( $av['medium'], 'png - medium is set' );
ok( $av['thumb'], 'png - thumb is set' );
like( $av['original'], '/avatar\.png/', 'png - original is png' );
like( $av['original'], '/\?[0-9]+$/', 'png - original timestamped' );
like( $av['original'], "/\/{$u->Avatar->img_uuid}\//", 'png - path has img_uuid' );

// check actual filesystem
$dir = Image::get_directory($u->Avatar->img_ref_type, $u->Avatar->img_uuid);
$av = $u->Avatar->get_image();
ok( is_dir($dir), 'png - dir exists' );
ok( is_file($av['original']), 'png - file exists' );
ok( is_file($av['medium']), 'png - medium exists' );
ok( is_file($av['thumb']), 'png - thumb exists' );

$sz_normal = getimagesize($av['original']);
$sz_medium = getimagesize($av['medium']);
$sz_thumb = getimagesize($av['thumb']);

// we know the initial/expected sizes
is( $sz_normal[0], 512, 'png - normal - width' );
is( $sz_normal[1], 512, 'png - normal - height' );
is( $sz_normal[2], IMAGETYPE_PNG, 'png - normal - type' );
is( $sz_medium[0], 300, 'png - medium - width' );
is( $sz_medium[1], 300, 'png - medium - height' );
is( $sz_medium[2], IMAGETYPE_PNG, 'png - medium - type' );
is( $sz_thumb[0], 100, 'png - thumb - width' );
is( $sz_thumb[1], 100, 'png - thumb - height' );
is( $sz_thumb[2], IMAGETYPE_PNG, 'png - thumb - type' );


/**********************
 * 3) Set as oblong jpeg
 */
sleep(1);
$old_dtim = $u->Avatar->img_dtim;
is( $u->Avatar->img_file_name, 'user.png', 'jpeg - file not yet changed' );
$u->Avatar->set_image($jpg_file);
$u->save();
is( $u->Avatar->img_file_name, 'user.jpg', 'jpeg - file changed!' );
ok( $u->Avatar->img_dtim > $old_dtim, 'jpeg - dtim changed' );

$av = $u->Avatar->get_image(true);
ok( $av['original'], 'jpeg - original is set' );
ok( $av['medium'], 'jpeg - medium is set' );
ok( $av['thumb'], 'jpeg - thumb is set' );
like( $av['original'], '/avatar\.png/', 'jpeg - original is png' );
like( $av['original'], '/\?[0-9]+$/', 'jpeg - original timestamped' );
like( $av['original'], "/\/{$u->Avatar->img_uuid}\//", 'jpeg - path has img_uuid' );

// check actual filesystem
$av = $u->Avatar->get_image();
ok( is_dir($dir), 'jpeg - dir exists' );
ok( is_file($av['original']), 'png - file exists' );
ok( is_file($av['medium']), 'png - medium exists' );
ok( is_file($av['thumb']), 'png - thumb exists' );

$sz_normal = getimagesize($av['original']);
$sz_medium = getimagesize($av['medium']);
$sz_thumb = getimagesize($av['thumb']);

// we know the initial/expected sizes
is( $sz_normal[0], 351, 'jpeg - normal - width' );
is( $sz_normal[1], 468, 'jpeg - normal - height' );
is( $sz_normal[2], IMAGETYPE_PNG, 'jpeg - normal - type' );
is( $sz_medium[0], 300, 'jpeg - medium - width' );
is( $sz_medium[1], 300, 'jpeg - medium - height' );
is( $sz_medium[2], IMAGETYPE_PNG, 'jpeg - medium - type' );
is( $sz_thumb[0], 100, 'jpeg - thumb - width' );
is( $sz_thumb[1], 100, 'jpeg - thumb - height' );
is( $sz_thumb[2], IMAGETYPE_PNG, 'jpeg - thumb - type' );


/**********************
 * 4) Delete avatar
 */
$u->Avatar->delete();
ok( !$u->Avatar->exists(), 'delete - avatar gone' );
ok( !is_dir($dir), 'delete - dir gone' );
ok( !is_file($av['original']), 'delete - file gone' );


/**********************
 * 5) Avatar deleted on user delete
 */
$u->clearRelated();
$u->Avatar->set_image($jpg_file);
$u->save();

$dir = Image::get_directory($u->Avatar->img_ref_type, $u->Avatar->img_uuid);
$av = $u->Avatar->get_image();

ok( is_dir($dir), 'delete hook - dir exists' );
ok( is_file($av['original']), 'delete hook - file exists' );

$u->delete();

ok( !is_dir($dir), 'delete hook - dir gone' );
ok( !is_file($av['original']), 'delete hook - file gone' );
