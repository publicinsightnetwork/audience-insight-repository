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

$o = new TestOrganization();
$o->add_users(array($u));
$o->save();

$api = new AIRAPI($u);

$csv_dir = dirname(__FILE__).'/examples';
$jpg_file = "$csv_dir/org-banner.jpg";
$gif_file = "$csv_dir/org-banner.gif";


plan(55);

/**********************
 * 1) Check initial data
 */
is( !$o->Banner, null, 'init - banner null' );

try {
    $o->Banner->img_file_name = 'TEST';
    fail('init - direct setting throws exception');
}
catch (Exception $e) {
    pass('init - direct setting throws exception');
}

try {
    $o->Banner->save();
    fail('init - null banner saving fails');
}
catch (Exception $e) {
    pass('init - null banner saving fails');
}


/**********************
 * 2) Set as jpg
 */
$o->Banner->set_image($jpg_file);
ok( $o->Banner->img_dtim, 'jpg - dtim not null' );
is( $o->Banner->get_image(), null, 'jpg - image initially null' );
$o->save();

// mock base url, so we can get timestamped assets
function base_url() { return "http://blah.com/"; }
$av = $o->Banner->get_image(true);

ok( $av, 'jpg - image not null' );
ok( $o->Banner->img_dtim, 'jpg - dtim not null' );

ok( $av['original'], 'jpg - original is set' );
ok( $av['medium'], 'jpg - medium is set' );
ok( $av['thumb'], 'jpg - thumb is set' );
like( $av['original'], '/banner\.png/', 'jpg - original is png' );
like( $av['original'], '/\?[0-9]+$/', 'jpg - original timestamped' );
like( $av['original'], "/\/{$o->Banner->img_uuid}\//", 'jpg - path has img_uuid' );

// check actual filesystem
$dir = Image::get_directory($o->Banner->img_ref_type, $o->Banner->img_uuid);
$ban = $o->Banner->get_image();
ok( is_dir($dir), 'jpg - dir exists' );
ok( is_file($ban['original']), 'jpg - file exists' );
ok( is_file($ban['medium']), 'jpg - medium exists' );
ok( is_file($ban['thumb']), 'jpg - thumb exists' );

$sz_normal = getimagesize($ban['original']);
$sz_medium = getimagesize($ban['medium']);
$sz_thumb = getimagesize($ban['thumb']);

// we know the initial/expected sizes - 2991 × 958
is( $sz_normal[0], 2991, 'jpg - normal - width' );
is( $sz_normal[1], 958, 'jpg - normal - height' );
is( $sz_normal[2], IMAGETYPE_PNG, 'jpg - normal - type' );
is( $sz_medium[0], 500, 'jpg - medium - width' );
is( $sz_medium[1], 160, 'jpg - medium - height' );
is( $sz_medium[2], IMAGETYPE_PNG, 'jpg - medium - type' );
is( $sz_thumb[0], 150, 'jpg - thumb - width' );
is( $sz_thumb[1], 150, 'jpg - thumb - height' );
is( $sz_thumb[2], IMAGETYPE_PNG, 'jpg - thumb - type' );


/**********************
 * 3) Set as gif
 */
sleep(1);
$old_dtim = $o->Banner->img_dtim;
is( $o->Banner->img_file_name, 'org-banner.jpg', 'gif - file not yet changed' );
$o->Banner->set_image($gif_file);
$o->save();
is( $o->Banner->img_file_name, 'org-banner.gif', 'gif - file changed!' );
ok( $o->Banner->img_dtim > $old_dtim, 'gif - dtim changed' );

$ban = $o->Banner->get_image(true);
ok( $ban['original'], 'gif - original is set' );
ok( $ban['medium'], 'gif - medium is set' );
ok( $ban['thumb'], 'gif - thumb is set' );
like( $ban['original'], '/banner\.png/', 'gif - original is png' );
like( $ban['original'], '/\?[0-9]+$/', 'gif - original timestamped' );
like( $ban['original'], "/\/{$o->Banner->img_uuid}\//", 'gif - path has img_uuid' );

// check actual filesystem
$ban = $o->Banner->get_image();
ok( is_dir($dir), 'gif - dir exists' );
ok( is_file($ban['original']), 'gif - file exists' );
ok( is_file($ban['medium']), 'gif - medium exists' );
ok( is_file($ban['thumb']), 'gif - thumb exists' );

$sz_normal = getimagesize($ban['original']);
$sz_medium = getimagesize($ban['medium']);
$sz_thumb = getimagesize($ban['thumb']);

// we know the initial/expected sizes 553 × 172
is( $sz_normal[0], 553, 'gif - normal - width' );
is( $sz_normal[1], 172, 'gif - normal - height' );
is( $sz_normal[2], IMAGETYPE_PNG, 'gif - normal - type' );
is( $sz_medium[0], 500, 'gif - medium - width' );
is( $sz_medium[1], 156, 'gif - medium - height' );
is( $sz_medium[2], IMAGETYPE_PNG, 'gif - medium - type' );
is( $sz_thumb[0], 150, 'gif - thumb - width' );
is( $sz_thumb[1], 150, 'gif - thumb - height' );
is( $sz_thumb[2], IMAGETYPE_PNG, 'gif - thumb - type' );


/**********************
 * 4) Delete banner
 */
$o->Banner->delete();
ok( !$o->Banner->exists(), 'delete - banner gone' );
ok( !is_dir($dir), 'delete - dir gone' );
ok( !is_file($ban['original']), 'delete - file gone' );


/**********************
 * 5) Banner deleted on org delete
 */
$o->clearRelated();
$o->Banner->set_image($gif_file);
$o->save();

$dir = Image::get_directory($o->Banner->img_ref_type, $o->Banner->img_uuid);
$ban = $o->Banner->get_image();

ok( is_dir($dir), 'delete hook - dir exists' );
ok( is_file($ban['original']), 'delete hook - file exists' );

$o->delete();

ok( !is_dir($dir), 'delete hook - dir gone' );
ok( !is_file($ban['original']), 'delete hook - file gone' );
