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
require_once 'models/TestOrganization.php';
require_once 'models/TestUser.php';

// helper to cleanup Users we create (which are NOT TestUsers)
class UserCleanup {
    public $uuid;
    function  __construct($uuid) {
        $this->uuid = $uuid;
    }
    function  __destruct() {
        if ($this->uuid) {
            $u = AIR2_Record::find('User', $this->uuid);
            if ($u) {
                $u->delete();
            }
        }
    }
}

// helpers to get POST data
function get_user_post($org_uuid=null) {
    $em = air2_generate_uuid()."@test.com";
    $data = array(
        'user_username' => $em,
        'user_first_name' => 'Test',
        'user_last_name' => 'McTesterson',
        'uem_address' => $em,
    );
    if ($org_uuid) $data['org_uuid'] = $org_uuid;
    return array('radix' => json_encode($data));
}
function get_uo_post($org_uuid=null, $ar_id=2) {
    $data = array('uo_ar_id' => $ar_id);
    if ($org_uuid) $data['org_uuid'] = $org_uuid;
    return array('radix' => json_encode($data));
}
function get_ou_post($user_uuid=null, $ar_id=2) {
    $data = array('uo_ar_id' => $ar_id);
    if ($user_uuid) $data['user_uuid'] = $user_uuid;
    return array('radix' => json_encode($data));
}

// init
AIR2_DBManager::init();
$browser = new AirHttpTest();
$browser->set_test_user();
$browser->set_content_type(AirHttpTest::$JSON);

// org with 1 space
$o = new TestOrganization();
$o->org_max_users = 1;
$o->save();

// org with unlimited space
$o2 = new TestOrganization();
$o2->org_max_users = -1; //unlimited
$o2->save();

plan(46);

/**********************
 * Create a new User with no Orgs
 */
$data = get_user_post();
ok( $resp = $browser->http_post("/user", $data), 'NoOrg - POST' );
is( $browser->resp_code(), 200, 'NoOrg - resp code' );
ok( $json = json_decode($resp, true), 'NoOrg - json decode' );
ok( $json['success'], 'NoOrg - success' );
$uuid = isset($json['radix']) ? $json['radix']['user_uuid'] : null;
$clean1 = new UserCleanup($uuid);

/**********************
 * Create a new User in the Test Org
 */
$data = get_user_post($o->org_uuid);
ok( $resp = $browser->http_post("/user", $data), '1-Org - POST' );
is( $browser->resp_code(), 200, '1-Org - resp code' );
ok( $json = json_decode($resp, true), '1-Org - json decode' );
ok( $json['success'], '1-Org - success' );
$uuid = isset($json['radix']) ? $json['radix']['user_uuid'] : null;
$clean2 = new UserCleanup($uuid);
$u = AIR2_Record::find('User', $uuid);
is( count($u->UserOrg), 1, '1-Org - count');

/**********************
 * Attempt to create a second user (fails)
 */
$data = get_user_post($o->org_uuid);
ok( $resp = $browser->http_post("/user", $data), '2-Org - POST' );
is( $browser->resp_code(), 400, '2-Org - resp code' );
ok( $json = json_decode($resp, true), '2-Org - json decode' );
ok( !$json['success'], '2-Org - failure' );
ok( isset($json['message']), '2-Org - message' );

// delete first user and retry
unset($clean2);
ok( $resp = $browser->http_post("/user", $data), '2-Org retry - POST' );
is( $browser->resp_code(), 200, '2-Org retry - resp code' );
ok( $json = json_decode($resp, true), '2-Org retry - json decode' );
ok( $json['success'], '2-Org retry - success' );
$uuid = isset($json['radix']) ? $json['radix']['user_uuid'] : null;
$clean3 = new UserCleanup($uuid);
$u = AIR2_Record::find('User', $uuid);
is( count($u->UserOrg), 1, '2-Org retry - count');

/**********************
 * Change existing role through User controller
 */
$uoid = $u->UserOrg[0]->uo_uuid;
$data = array('radix' => json_encode(array('uo_ar_id' => 3)));
ok( $resp = $browser->http_put("/user/$uuid/organization/$uoid", $data), 'User/Org up - PUT' );
is( $browser->resp_code(), 200, 'User/Org up - resp code' );
ok( $json = json_decode($resp, true), 'User/Org up - json decode' );
ok( $json['success'], 'User/Org up - success' );
is( $json['radix']['uo_ar_id'], 3, 'User/Org up - ar_id' );

/**********************
 * Assign existing user through User controller
 */
$testuser = new TestUser();
$testuser->save();
$id = $testuser->user_uuid;
$data = get_uo_post($o->org_uuid);

ok( $resp = $browser->http_post("/user/$id/organization", $data), 'User/Org - POST' );
is( $browser->resp_code(), 400, 'User/Org - resp code' );
ok( $json = json_decode($resp, true), 'User/Org - json decode' );
ok( !$json['success'], 'User/Org - failure' );
ok( isset($json['message']), 'User/Org - message' );
is( $testuser->UserOrg->count(), 0, 'User/Org - count');

// assign to unlimited org
$data = get_uo_post($o2->org_uuid);
ok( $resp = $browser->http_post("/user/$id/organization", $data), 'User/Org un - POST' );
is( $browser->resp_code(), 200, 'User/Org un - resp code' );
ok( $json = json_decode($resp, true), 'User/Org un - json decode' );
ok( $json['success'], 'User/Org un - success' );
$testuser->clearRelated('UserOrg');
is( $testuser->UserOrg->count(), 1, 'User/Org un - count');

/**********************
 * Assign existing user through Organization controller
 */
$id = $o->org_uuid;
$data = get_ou_post($testuser->user_uuid);

ok( $resp = $browser->http_post("/organization/$id/user", $data), 'Org/User - POST' );
is( $browser->resp_code(), 400, 'Org/User - resp code' );
ok( $json = json_decode($resp, true), 'Org/User - json decode' );
ok( !$json['success'], 'Org/User - failure' );
ok( isset($json['message']), 'Org/User - message' );

$o->org_max_users++;
$o->save();
ok( $resp = $browser->http_post("/organization/$id/user", $data), 'Org/User retry - POST' );
is( $browser->resp_code(), 200, 'Org/User retry - resp code' );
ok( $json = json_decode($resp, true), 'Org/User retry - json decode' );
ok( $json['success'], 'Org/User retry - success' );

// check ending count
is( UserOrg::get_user_count($o->org_id), 2, 'Ending $o user count' );
is( UserOrg::get_user_count($o2->org_id), 1, 'Ending $o2 user count' );
