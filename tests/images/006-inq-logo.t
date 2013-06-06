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


plan(55);

/**********************
 * 1) Check initial data
 */
is( !$o->Logo, null, 'init - logo null' );

try {
    $o->Logo->img_file_name = 'TEST';
    fail('init - direct setting throws exception');
}
catch (Exception $e) {
    pass('init - direct setting throws exception');
}

try {
    $o->Logo->save();
    fail('init - null logo saving fails');
}
catch (Exception $e) {
    pass('init - null logo saving fails');
}


/**********************
 * 2) Set as jpg
 */
$o->Logo->set_image($jpg_file);
ok( $o->Logo->img_dtim, 'jpg - dtim not null' );
is( $o->Logo->get_image(), null, 'jpg - image initially null' );
$o->save();

// mock base url, so we can get timestamped assets
function base_url() { return "http://blah.com/"; }
$av = $o->Logo->get_image(true);

ok( $av, 'jpg - image not null' );
ok( $o->Logo->img_dtim, 'jpg - dtim not null' );

ok( $av['original'], 'jpg - original is set' );
ok( $av['medium'], 'jpg - medium is set' );
ok( $av['thumb'], 'jpg - thumb is set' );
like( $av['original'], '/logo\.png/', 'jpg - original is png' );
like( $av['original'], '/\?[0-9]+$/', 'jpg - original timestamped' );
like( $av['original'], "/\/{$o->Logo->img_uuid}\//", 'jpg - path has img_uuid' );

// check actual filesystem
$dir = Image::get_directory($o->Logo->img_ref_type, $o->Logo->img_uuid);
$log = $o->Logo->get_image();
ok( is_dir($dir), 'jpg - dir exists' );
ok( is_file($log['original']), 'jpg - file exists' );
ok( is_file($log['medium']), 'jpg - medium exists' );
ok( is_file($log['thumb']), 'jpg - thumb exists' );

$sz_normal = getimagesize($log['original']);
$sz_medium = getimagesize($log['medium']);
$sz_thumb = getimagesize($log['thumb']);

// we know the initial/expected sizes - 2991x958
is( $sz_normal[0], 2991, 'jpg - normal - width' );
is( $sz_normal[1], 958, 'jpg - normal - height' );
is( $sz_normal[2], IMAGETYPE_PNG, 'jpg - normal - type' );
is( $sz_medium[0], 200, 'jpg - medium - width' );
is( $sz_medium[1], 64,  'jpg - medium - height' );
is( $sz_medium[2], IMAGETYPE_PNG, 'jpg - medium - type' );
is( $sz_thumb[0], 50, 'jpg - thumb - width' );
is( $sz_thumb[1], 16, 'jpg - thumb - height' );
is( $sz_thumb[2], IMAGETYPE_PNG, 'jpg - thumb - type' );


/**********************
 * 3) Set as gif
 */
sleep(1);
$old_dtim = $o->Logo->img_dtim;
is( $o->Logo->img_file_name, 'org-banner.jpg', 'gif - file not yet changed' );
$o->Logo->set_image($gif_file);
$o->save();
is( $o->Logo->img_file_name, 'org-banner.gif', 'gif - file changed!' );
ok( $o->Logo->img_dtim > $old_dtim, 'gif - dtim changed' );

$log = $o->Logo->get_image(true);
ok( $log['original'], 'gif - original is set' );
ok( $log['medium'], 'gif - medium is set' );
ok( $log['thumb'], 'gif - thumb is set' );
like( $log['original'], '/logo\.png/', 'gif - original is png' );
like( $log['original'], '/\?[0-9]+$/', 'gif - original timestamped' );
like( $log['original'], "/\/{$o->Logo->img_uuid}\//", 'gif - path has img_uuid' );

// check actual filesystem
$log = $o->Logo->get_image();
ok( is_dir($dir), 'gif - dir exists' );
ok( is_file($log['original']), 'gif - file exists' );
ok( is_file($log['medium']), 'gif - medium exists' );
ok( is_file($log['thumb']), 'gif - thumb exists' );

$sz_normal = getimagesize($log['original']);
$sz_medium = getimagesize($log['medium']);
$sz_thumb = getimagesize($log['thumb']);

// we know the initial/expected sizes 553x172
is( $sz_normal[0], 553, 'gif - normal - width' );
is( $sz_normal[1], 172, 'gif - normal - height' );
is( $sz_normal[2], IMAGETYPE_PNG, 'gif - normal - type' );
is( $sz_medium[0], 200, 'gif - medium - width' );
is( $sz_medium[1], 62, 'gif - medium - height' );
is( $sz_medium[2], IMAGETYPE_PNG, 'gif - medium - type' );
is( $sz_thumb[0], 50, 'gif - thumb - width' );
is( $sz_thumb[1], 16, 'gif - thumb - height' );
is( $sz_thumb[2], IMAGETYPE_PNG, 'gif - thumb - type' );


/**********************
 * 4) Delete logo
 */
$o->Logo->delete();
ok( !$o->Logo->exists(), 'delete - logo gone' );
ok( !is_dir($dir), 'delete - dir gone' );
ok( !is_file($log['original']), 'delete - file gone' );


/**********************
 * 5) Logo deleted on org delete
 */
$o->clearRelated();
$o->Logo->set_image($gif_file);
$o->save();

$dir = Image::get_directory($o->Logo->img_ref_type, $o->Logo->img_uuid);
$log = $o->Logo->get_image();

ok( is_dir($dir), 'delete hook - dir exists' );
ok( is_file($log['original']), 'delete hook - file exists' );

$o->delete();

ok( !is_dir($dir), 'delete hook - dir gone' );
ok( !is_file($log['original']), 'delete hook - file gone' );
