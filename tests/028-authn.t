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

plan(16);

define('MY_TEST_PASS', 'fooBar123.');

// create a test user
AIR2_DBManager::init();
$user = new TestUser();
$user->user_encrypted_password = MY_TEST_PASS;
$user->save();

// html auth
$browser = new AirHttpTest();

if (AIR2_PIN_SSO_TRUST) {

    // can't test PIN SSO with local account
    for ($i=0; $i<16; $i++) {
        pass("can't test PIN SSO with local account");
    }


}
else {
    ok( $resp = $browser->http_get("/"), "get /");
    like( $resp, '/Login/', "GET redirects to login page");
    //diag_dump( $resp );

    ok( $resp = $browser->http_post("/login", array(
                'username' => $user->user_username,
                'password' => MY_TEST_PASS
            )), "login with http");

    unlike( $resp, '/Login/', "login via http post");


    // json auth
    ok( $resp = $browser->http_post("/login.json", array(
                'username' => $user->user_username,
                'password' => MY_TEST_PASS
            )), "login with http");

    unlike( $resp, '/Login/', "login via http post");
    ok( $json_resp = json_decode($resp), "json_decode response");
    ok( $json_resp->air2_tkt, "got air2_tkt");

    // intentional failure
    ok( $resp = $browser->http_post("/login.json", array(
                'username' => $user->user_username,
                'password' => 'noway',
            )), "login with http");

    unlike( $resp, '/Login/', "login via http post");
    ok( $json_resp = json_decode($resp), "json_decode response");
    is( $json_resp->success, false, "got success==false");

    // repeat, with XML
    ok( $resp = $browser->http_post("/login.xml", array(
                'username' => $user->user_username,
                'password' => MY_TEST_PASS
            )), "login with http");

    like($resp, '/<success>true</', "xml response");

    // intentional failure
    ok( $resp = $browser->http_post("/login.xml", array(
                'username' => $user->user_username,
                'password' => 'noway',
            )), "login with http");

    like($resp, '/<success>false</', "xml response");
}
