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
require_once 'models/TestProject.php';
require_once 'models/TestOrganization.php';
require_once 'models/TestUser.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$browser = new AirHttpTest();
$browser->set_test_user();

// dummy data
$u = new TestUser();
$u->save();
$o1 = new TestOrganization();
$o1->add_users(array($u), 3);
$o1->save();
$ouuid1 = $o1->org_uuid;
$o2 = new TestOrganization();
$o2->add_users(array($u), 3);
$o2->save();
$ouuid2 = $o2->org_uuid;
$p = new TestProject();
$p->add_orgs(array($o1));
$p->save();
$puuid = $p->prj_uuid;

plan(54);

/**********************
 * Check codes
 */
$browser->set_content_type(AirHttpTest::$HTML);
ok( $resp = $browser->http_get("project/$puuid/organization"), 'GET list html' );
is( $browser->resp_code(), 415, 'GET list html - code' );
ok( $resp = $browser->http_get("project/$puuid/organization/$ouuid1"), 'GET html' );
is( $browser->resp_code(), 415, 'GET html - code' );
ok( $resp = $browser->http_get("project/$puuid/fakerelation"), 'GET fake html' );
is( $browser->resp_code(), 404, 'GET fake html - code' );

$browser->set_content_type(AirHttpTest::$JSON);
ok( $resp = $browser->http_get("project/$puuid/organization"), 'GET list json' );
is( $browser->resp_code(), 200, 'GET list json - code' );
ok( $resp = $browser->http_get("project/$puuid/organization/$ouuid1"), 'GET json' );
is( $browser->resp_code(), 200, 'GET json - code' );
ok( $resp = $browser->http_get("project/$puuid/fakerelation"), 'GET fake json' );
is( $browser->resp_code(), 404, 'GET fake json - code' );


/**********************
 * GET list
 */
ok( $resp = $browser->http_get("project/$puuid/organization"), 'GET list' );
is( $browser->resp_code(), 200, 'GET list - code' );
ok( $json = json_decode($resp, true), 'GET list - decode' );
is( $json['success'], true, 'GET list - success' );
is( count($json['radix']), 1, 'GET list - count' );
is( $json['meta']['total'], 1, 'GET list - total' );
is( $json['radix'][0]['org_uuid'], $ouuid1, 'GET list - uuid1' );
ok( !isset($json['radix'][0]['org_id']), 'GET list - no org_id' );


/**********************
 * POST create
 */
$data = array('org_uuid' => $o2->org_uuid, 'user_uuid' => $u->user_uuid);
ok( $resp = $browser->http_post("project/$puuid/organization", array('radix' => json_encode($data))), 'POST create');
is( $browser->resp_code(), 200, 'POST create - code' );
ok( $json = json_decode($resp, true), 'POST create - decode' );
is( $json['success'], true, 'POST create - success' );
is( $json['radix']['org_uuid'], $ouuid2, 'POST create - org_uuid' );
is( $json['radix']['user_uuid'], $u->user_uuid, 'POST create - user_uuid' );
ok( !isset($json['radix']['org_id']), 'POST create - no org_id' );


/**********************
 * GET one
 */
ok( $resp = $browser->http_get("project/$puuid/organization/$ouuid1"), 'GET one' );
is( $browser->resp_code(), 200, 'GET one - code' );
ok( $json = json_decode($resp, true), 'GET one - decode' );
is( $json['success'], true, 'GET one - success' );
ok( air2_is_assoc_array($json['radix']), 'GET one - is_assoc_array' );
is( $json['radix']['org_uuid'], $ouuid1, 'GET one - uuid1' );
ok( !isset($json['radix']['org_id']), 'GET one - no org_id' );
ok( !isset($json['radix']['org_cre_user']), 'GET one - no cre_user id' );
$old = $json['radix']['ContactUser']['user_uuid'];


/**********************
 * update via PUT
 */
$data = array('user_uuid' => $u->user_uuid);
ok( $resp = $browser->http_put("project/$puuid/organization/$ouuid1", array('radix' => json_encode($data))), 'PUT update' );
is( $browser->resp_code(), 200, 'PUT update - code' );
ok( $json = json_decode($resp, true), 'PUT update - decode' );
is( $json['success'], true, 'PUT update - success' );
is( $json['radix']['ContactUser']['user_uuid'], $u->user_uuid, 'PUT update - user_uuid' );


/**********************
 * DELETE
 */
ok( $resp = $browser->http_get("project/$puuid/organization"), 'pre-DELETE list' );
is( $browser->resp_code(), 200, 'pre-DELETE list - code' );
ok( $json = json_decode($resp, true), 'pre-DELETE list - decode' );
is( $json['success'], true, 'pre-DELETE list - success' );
is( count($json['radix']), 2, 'pre-DELETE list - count' );

ok( $resp = $browser->http_delete("project/$puuid/organization/$ouuid1"), 'DELETE delete' );
is( $browser->resp_code(), 200, 'DELETE delete - code' );
ok( $json = json_decode($resp, true), 'DELETE delete - decode' );
is( $json['success'], true, 'DELETE delete - success' );

ok( $resp = $browser->http_get("project/$puuid/organization"), 'post-DELETE list' );
is( $browser->resp_code(), 200, 'post-DELETE list - code' );
ok( $json = json_decode($resp, true), 'post-DELETE list - decode' );
is( $json['success'], true, 'post-DELETE list - success' );
is( count($json['radix']), 1, 'post-DELETE list - count' );
