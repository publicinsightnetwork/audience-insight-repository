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
$u = new TestUser();
$u->save();
$api = new AIRAPI($u);


/**********************
 * Setup test data
 */
$u2 = new TestUser();
$u2->save();

$o1 = new TestOrganization();
$o1->add_users(array($u, $u2), AdminRole::READER);
$o1->save();
$o2 = new TestOrganization();
$o2->add_users(array($u2), AdminRole::READER);
$o2->save();

$b1 = new TestBin();
$b1->bin_name = 'AAAAAA TestBin';
$b1->bin_user_id = $u->user_id;
$b1->bin_type = 'T';
$b1->save();
$b1u = $b1->bin_uuid;
$b2 = new TestBin();
$b2->bin_name = 'BBBBBB TestBin';
$b2->bin_user_id = $u2->user_id;
$b2->bin_shared_flag  = true;
$b2->bin_type = 'T';
$b2->save();
$b2u = $b2->bin_uuid;
$b3 = new TestBin();
$b3->bin_name = 'CCCCCC TestBin';
$b3->bin_user_id = $u2->user_id;
$b3->bin_type = 'T';
$b3->save();
$b3u = $b3->bin_uuid;
$b4 = new TestBin();
$b4->bin_name = 'DDDDDD TestBin';
$b4->bin_user_id = $u->user_id;
$b4->bin_type = 'T';
$b4->save();
$b4u = $b4->bin_uuid;

function get_bin_uuids($radix) {
    $res = array();
    foreach ($radix as $bin) $res[] = $bin['bin_uuid'];
    return $res;
}

function check_order($bins, $radix) {
    $idx = 0;
    foreach ($radix as $uuid) {
        if (isset($bins[$idx]) && $uuid == $bins[$idx]) {
            $idx++;
        }
    }
    return ($idx == count($bins));
}


plan(37);

/**********************
 * list bins, in normal order
 */
$rs = $api->query('bin', array('type' => 'T'));
$data = get_bin_uuids($rs['radix']);

is( $rs['code'], AIRAPI::OKAY, 'list - okay' );
ok(  in_array($b1u, $data), 'list - b1 present' );
ok(  in_array($b2u, $data), 'list - b2 present' );
ok( !in_array($b3u, $data), 'list - b3 not present' );
ok(  in_array($b4u, $data), 'list - b4 present' );
ok( check_order(array($b1u, $b2u, $b4u), $data), 'list - order' );


/**********************
 * list owned bins, in normal order
 */
$rs = $api->query('bin', array('owner' => 1, 'type' => 'T'));
$data = get_bin_uuids($rs['radix']);

is( $rs['code'], AIRAPI::OKAY, 'list self - okay' );
ok( count($data) == 2, 'list self - count' );
ok(  in_array($b1u, $data), 'list self - b1 present' );
ok( !in_array($b2u, $data), 'list self - b2 not present' );
ok( !in_array($b3u, $data), 'list self - b3 not present' );
ok(  in_array($b4u, $data), 'list self - b4 present' );
ok( check_order(array($b1u, $b4u), $data), 'list self - order' );


/**********************
 * Order by bin_upd_dtim
 */
$upd_dtim = 'update bin set bin_upd_dtim = ? where bin_id = ?';
$conn->exec($upd_dtim, array(air2_date(strtotime('2015-10-12')), $b2->bin_id));
$conn->exec($upd_dtim, array(air2_date(strtotime('2014-10-12')), $b4->bin_id));

$rs = $api->query('bin', array('type' => 'T'));
$data = get_bin_uuids($rs['radix']);

is( $rs['code'], AIRAPI::OKAY, 'sort default - okay' );
ok( check_order(array($b2u, $b4u, $b1u), $data), 'sort default - order' );

$rs = $api->query('bin', array('sort' => 'bin_upd_dtim desc', 'type' => 'T'));
$data = get_bin_uuids($rs['radix']);

is( $rs['code'], AIRAPI::OKAY, 'sort last use - okay' );
ok( check_order(array($b2u, $b4u, $b1u), $data), 'sort last use - order' );

$rs = $api->query('bin', array('sort' => 'bin_upd_dtim asc', 'type' => 'T'));
$data = get_bin_uuids($rs['radix']);

is( $rs['code'], AIRAPI::OKAY, 'sort last ASC - okay' );
ok( check_order(array($b1u, $b4u, $b2u), $data), 'sort last ASC - order' );


/**********************
 * Order by bin_name
 */
$rs = $api->query('bin', array('sort' => 'bin_name ASC', 'type' => 'T'));
$data = get_bin_uuids($rs['radix']);

is( $rs['code'], AIRAPI::OKAY, 'sort name - okay' );
ok( check_order(array($b1u, $b2u, $b4u), $data), 'sort name - order' );

$rs = $api->query('bin', array('sort' => 'bin_name DESC', 'type' => 'T'));
$data = get_bin_uuids($rs['radix']);

is( $rs['code'], AIRAPI::OKAY, 'sort name DESC - okay' );
ok( check_order(array($b4u, $b2u, $b1u), $data), 'sort name DESC - order' );


/**********************
 * Order by src_count
 */
$s = new TestSource();
$s->save();
$b2->BinSource[]->bsrc_src_id = $s->src_id;
$b2->save();

$rs = $api->query('bin', array('sort' => 'src_count DESC', 'type' => 'T'));
$data = get_bin_uuids($rs['radix']);

is( $rs['code'], AIRAPI::OKAY, 'sort count - okay' );
ok( check_order(array($b2u, $b4u), $data), 'sort count - order' );

$rs = $api->query('bin', array('sort' => 'src_count asc', 'type' => 'T'));
$data = get_bin_uuids($rs['radix']);

is( $rs['code'], AIRAPI::OKAY, 'sort count ASC - okay' );
ok( check_order(array($b4u, $b2u), $data), 'sort count ASC - order' );


/**********************
 * Order by user_first_name
 */
$u->user_first_name = 'AAAA';
$u->save();
$u2->user_first_name = 'ZZZZ';
$u2->save();

$rs = $api->query('bin', array('sort' => 'user_first_name ASC', 'type' => 'T'));
$data = get_bin_uuids($rs['radix']);

is( $rs['code'], AIRAPI::OKAY, 'sort user - okay' );
ok( check_order(array($b4u, $b2u), $data), 'sort user - order' );

$rs = $api->query('bin', array('sort' => 'user_first_name DESC', 'type' => 'T'));
$data = get_bin_uuids($rs['radix']);

is( $rs['code'], AIRAPI::OKAY, 'sort user DESC - okay' );
ok( check_order(array($b2u, $b4u), $data), 'sort user DESC - order' );


/**********************
 * search by bin_name
 */
$rs = $api->query('bin', array('q' => $b1->bin_name, 'type' => 'T'));
$data = get_bin_uuids($rs['radix']);

is( $rs['code'], AIRAPI::OKAY, 'sort name - okay' );
ok( count($data) >= 1, 'search name - count' );
ok(  in_array($b1u, $data), 'search name - b1 present' );
ok( !in_array($b2u, $data), 'search name - b2 not present' );
ok( !in_array($b3u, $data), 'search name - b3 not present' );
ok( !in_array($b4u, $data), 'search name - b4 not present' );
