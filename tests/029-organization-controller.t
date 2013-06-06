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

// init
AIR2_DBManager::init();
$browser = new AirHttpTest();

$u = new TestUser();
$u->save();
$browser->set_user($u);

// create a test organization to look at
$o = new TestOrganization();
$o->add_users(array($u), 2); //READER
$o->save();
$uuid = $o->org_uuid;

plan(90);

/**********************
 * Validate HTML inline data
 */
$browser->set_content_type(AirHttpTest::$HTML); // set to html
ok( $resp = $browser->http_get("/organization/$uuid"), 'nav to orgpage' );
is( $browser->resp_code(), 200, "orgpage resp code" );

$var = air2_get_json_variable('AIR2.Organization.UUID', $resp);
is( $var, $uuid, 'ORGUUID = $o->org_uuid' );
$var = air2_get_json_variable('AIR2.Organization.URL', $resp);
is( $var, $browser->base_url."organization/$uuid", 'ORGURL set correctly' );

$var = air2_get_json_variable('AIR2.Organization.BASE', $resp);
validate_json($var, 'BASE');
$var = air2_get_json_variable('AIR2.Organization.CHILDDATA', $resp);
validate_json($var, 'CHILDDATA');
$var = air2_get_json_variable('AIR2.Organization.PRJDATA', $resp);
validate_json($var, 'PRJDATA');
$var = air2_get_json_variable('AIR2.Organization.USRDATA', $resp);
validate_json($var, 'USRDATA');
$var = air2_get_json_variable('AIR2.Organization.INQDATA', $resp);
validate_json($var, 'INQDATA');
$var = air2_get_json_variable('AIR2.Organization.ACTVDATA', $resp);
validate_json($var, 'ACTVDATA');


/**********************
 * Validate JSON data
 */
$browser->set_content_type(AirHttpTest::$JSON); // set to json

ok( $resp = $browser->http_get("/organization/$uuid"), 'json nav to org' );
is( $browser->resp_code(), 200, "json org resp code" );
validate_json($resp, 'org');
$json = json_decode($resp, true);
ok( key_exists('parent', $json['radix']), 'org parent set' );

ok( $resp = $browser->http_get("/organization/$uuid/project"), 'json nav to projects' );
is( $browser->resp_code(), 200, "json projects resp code" );
validate_json($resp, 'projects');

ok( $resp = $browser->http_get("/organization/$uuid/user"), 'json nav to users' );
is( $browser->resp_code(), 200, "json users resp code" );
validate_json($resp, 'users');

ok( $resp = $browser->http_get("/organization/$uuid/inquiry"), 'json nav to inquiries' );
is( $browser->resp_code(), 200, "json inquiries resp code" );
validate_json($resp, 'inquiries');

ok( $resp = $browser->http_get("/organization/$uuid/activity"), 'json nav to activity' );
is( $browser->resp_code(), 200, "json activity resp code" );
validate_json($resp, 'activity');

ok( $resp = $browser->http_get("/organization/$uuid/child"), 'json nav to children' );
is( $browser->resp_code(), 200, "json children resp code" );
validate_json($resp, 'children');


/**********************
 * Test the "query_may_write" vs "role" GET params
 */
$o2 = new TestOrganization();
$o2->add_users(array($u), 3); //WRITER
$o2->save();
$o3 = new TestOrganization();
$o3->add_users(array($u),  4); //MANAGER
$o3->save();
$o4 = new TestOrganization();
$o4->add_users(array($u), 3); //WRITER
$o4->save();

$browser->set_content_type(AirHttpTest::$JSON);
ok( $resp = $browser->http_get('/organization'), 'list orgs' );
is( $browser->resp_code(), 200, 'list orgs - resp code' );
ok( $json = json_decode($resp, true), 'list orgs - json decode' );
ok( count($json['radix']) >= 4, 'list orgs - count radix' );
ok( $json['meta']['total'] >= 4, 'list orgs - total' );

// query_may_write
ok( $resp = $browser->http_get('/organization', array('write' => 1)), 'query_may_write' );
is( $browser->resp_code(), 200, 'query_may_write - resp code' );
ok( $json = json_decode($resp, true), 'query_may_write - json decode' );
is( count($json['radix']), 1, 'query_may_write - count radix' );
is( $json['meta']['total'], 1, 'query_may_write - total' );

// role=READER (or better)
ok( $resp = $browser->http_get('/organization', array('role' => 'READER')), 'role=R' );
is( $browser->resp_code(), 200, 'role=R - resp code' );
ok( $json = json_decode($resp, true), 'role=R - json decode' );
is( count($json['radix']), 4, 'role=R - count radix' );
is( $json['meta']['total'], 4, 'role=R - total' );

// role=WRITER (or better)
ok( $resp = $browser->http_get('/organization', array('role' => 'writer')), 'role=W' );
is( $browser->resp_code(), 200, 'role=W - resp code' );
ok( $json = json_decode($resp, true), 'role=W - json decode' );
is( count($json['radix']), 3, 'role=W - count radix' );
is( $json['meta']['total'], 3, 'role=W - total' );

// role=WRITER (or better)
ok( $resp = $browser->http_get('/organization', array('role' => 'M')), 'role=M' );
is( $browser->resp_code(), 200, 'role=M - resp code' );
ok( $json = json_decode($resp, true), 'role=M - json decode' );
is( count($json['radix']), 1, 'role=M - count radix' );
is( $json['meta']['total'], 1, 'role=M - total' );
