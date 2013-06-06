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

// init
AIR2_DBManager::init();
$browser = new AirHttpTest();
$browser->set_test_user();
$browser->set_content_type(AirHttpTest::$JSON);

// create some test users to look at
$u1 = new TestUser();
$u1->save();
$u2 = new TestUser();
$u2->save();
$u3 = new TestUser();
$u3->save();

// get uuid's
$id1 = $u1->user_uuid;
$id2 = $u2->user_uuid;
$id3 = $u3->user_uuid;

// set some sortable usernames
$u1->user_username = 'Aaaaa';
$u1->save();
$u2->user_username = 'Bbbbb';
$u2->save();
$u3->user_username = 'Ccccc';
$u3->save();

// manually update the CreUser/UpdUsers, to avoid preValidate
$conn = AIR2_DBManager::get_master_connection();
$q = 'UPDATE user SET user_upd_user = ? WHERE user_id = ?';
$conn->execute($q, array($u2->user_id, $u1->user_id));
$conn->execute($q, array($u3->user_id, $u2->user_id));
$conn->execute($q, array($u1->user_id, $u3->user_id));

// helper function to check order
function check_order($get_params, $i0, $i1, $i2, $test_name) {
    global $browser;

    // add get params to the "type=T" (test types)
    ok( $resp = $browser->http_get("/user?type=T&$get_params"), "$test_name - get" );
    is( $browser->resp_code(), 200, "$test_name - resp code" );
    ok( $json = json_decode($resp, true), "$test_name - json" );

    // check radix
    $radix = isset($json['radix']) ? $json['radix'] : null;
    is( count($radix), 3, "$test_name - radix count" );
    $str1 = "$i0 $i1 $i2";
    $c = 'user_uuid';
    $str2 = $radix[0][$c] . ' ' . $radix[1][$c] . ' ' . $radix[2][$c];
    is( $str2, $str1, "$test_name - order" );
}


plan(40);
/**********************
 * Test sorting on first table
 */
check_order('sort=user_username ASC', $id1, $id2, $id3, 'username ASC');
check_order('sort=user_username', $id1, $id2, $id3, 'username default is ASC');
check_order('sort=user_username desc', $id3, $id2, $id1, 'username DESC');
check_order('sort=user_username%20DESC', $id3, $id2, $id1, 'username DESC alternate');

/**********************
 * Try sorting on the UpdUser
 */
check_order('sort=upd_username asc', $id3, $id1, $id2, 'upduser ASC' );
check_order('sort=upd_username desc', $id2, $id1, $id3, 'upduser DESC' );
$str = urlencode('user_type asc, upd_username asc' );
check_order("sort=$str", $id3, $id1, $id2, 'upduser multisort ASC' );
$str = urlencode('user_username ASC, upd_username ASC' );
check_order("sort=$str", $id1, $id2, $id3, 'upduser overriden by username' );


?>
