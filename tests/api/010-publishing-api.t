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
$tdir = APPPATH.'../tests';
require_once "$tdir/Test.php";
require_once "$tdir/AirHttpTest.php";
require_once "$tdir/models/TestAPIKey.php";

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// we expect at least one public query with responses to exist
$public_query_uuid = 'publicqueryA';

plan(49);

$apiKey = new TestAPIKey();
$apiKey->ak_approved = 1;
$apiKey->save();

$testAPIKey = $apiKey->my_uuid;

// init browser
$browser = new AirHttpTest();
$browser->set_test_user();
$browser->set_content_type(AirHttpTest::$JSON); // set to json

// xml responses
$browser = new AirHttpTest();
$browser->set_user('testuser', array(''=>false));
$browser->set_content_type(AirHttpTest::$XML);

$uri = "/api/public/search.xml?q=query_uuid:$public_query_uuid&a=$testAPIKey";
ok( $xmlResp = $browser->http_get($uri), "GET $uri");
is( $browser->resp_code(), 200, "Successful");
is( $browser->resp_content_type(), 'application/xml; charset=utf-8', "XML");
//diag( $xmlResp );
$respXML = new SimpleXMLElement($xmlResp);
like( $xmlResp, '/<?xml/', "public_responses is xml");


// xml No APIKey
$browser = new AirHttpTest();
$browser->set_user('testuser', array(''=>false));
$browser->set_content_type(AirHttpTest::$XML);

$uri = '/api/public/search.xml';
ok( $xmlResp = $browser->http_get($uri), "GET $uri");
is( $browser->resp_code(), 401, "Error");
is( $browser->resp_content_type(), 'application/xml', "XML");
$respXML = new SimpleXMLElement($xmlResp);
like( $xmlResp, '/<?xml/', "public_responses is xml");
ok( $error = $respXML->error);
is( $error, 'API Key Required', "Check XML error message");
ok( $success = $respXML->success);
is( $success, 'false', 'No Success XML');

// xml Invalid APIKey
$browser = new AirHttpTest();
$browser->set_user('testuser', array(''=>false));
$browser->set_content_type(AirHttpTest::$XML);

$uri = '/api/public/search.xml?q=hi&a=TESTAPIKEY1234567890123456789090';
ok( $xmlResp = $browser->http_get($uri), "GET $uri");
is( $browser->resp_code(), 403, "Error");
is( $browser->resp_content_type(), 'application/xml', "XML");
$respXML = new SimpleXMLElement($xmlResp);
like( $xmlResp, '/<?xml/', "public_responses is xml");
ok( $error = $respXML->error);
is( $error, 'Invalid API Key', "Check XML error message");
ok( $success = $respXML->success);
is( $success, 'false', 'No Success XML');

// xml No parameter
$browser = new AirHttpTest();
$browser->set_user('testuser', array(''=>false));
$browser->set_content_type(AirHttpTest::$XML);

$uri = "/api/public/search.xml?a=$testAPIKey";
ok( $xmlResp = $browser->http_get($uri), "GET $uri");
is( $browser->resp_code(), 400, "Error");
is( $browser->resp_content_type(), 'application/xml', "XML");
$respXML = new SimpleXMLElement($xmlResp);
like( $xmlResp, '/<?xml/', "public_responses is xml");
ok( $error = $respXML->error);
is( $error, '"q" param required', "Check XML error message");
ok( $success = $respXML->success);
is( $success, 'false', 'No Success XML');

//JSON No API Key
$browser = new AirHttpTest();
$browser->set_user('testuser', array(''=>false));
$browser->set_content_type(AirHttpTest::$JSON);
$uri = "/api/public/search.json?q=hi";
ok( $jsonResp = $browser->http_get($uri), "GET $uri");
is( $browser->resp_code(), 401, "Successful");
is( $browser->resp_content_type(), 'application/json', "JSON content type");
ok( $errorRespJSON = json_decode($jsonResp, true), "parse JSON");
ok( $errorRespJSON['error'] = 'API Key Required');

//JSON Wrong API Key
$browser = new AirHttpTest();
$browser->set_user('testuser', array(''=>false));
$browser->set_content_type(AirHttpTest::$JSON);
$uri = "/api/public/search.json?q=hi&a=TESTAPIKEY1234567890123456789090";
ok( $jsonResp = $browser->http_get($uri), "GET $uri");
is( $browser->resp_code(), 403, "Successful");
is( $browser->resp_content_type(), 'application/json', "JSON content type");
ok( $errorRespJSON = json_decode($jsonResp, true), "parse JSON");
ok( $errorRespJSON['error'] = 'Invalid API Key');

// JSON No parameter
$browser = new AirHttpTest();
$browser->set_user('testuser', array(''=>false));
$browser->set_content_type(AirHttpTest::$JSON);

$uri = "/api/public/search.json?a=$testAPIKey";
ok( $jsonResp = $browser->http_get($uri), "GET $uri");
is( $browser->resp_code(), 400, "Error");
is( $browser->resp_content_type(), 'application/json', "JSON");
$errorRespJson = json_decode($jsonResp);
ok( $error = $errorRespJson->error);
is( $error, '"q" param required', "Check JSON error message");

/**************************************************************************/
//                         we expect success
/**************************************************************************/

//JSON With Param
$browser = new AirHttpTest();
$browser->set_user('testuser', array(''=>false));
$browser->set_content_type(AirHttpTest::$JSON);

$uri = "/api/public/search.json?q=query_uuid:$public_query_uuid&a=$testAPIKey&h=0";
ok( $jsonResp = $browser->http_get($uri), "GET $uri");
is( $browser->resp_code(), 200, "Successful");
is( $browser->resp_content_type(), 'application/json; charset=utf-8', "JSON content type");
ok( $respJSON = json_decode($jsonResp, true), "parse JSON");

// we expect a certain format for our JSON response
//diag_dump( $respJSON );
ok( $results = $respJSON['results'], 'get results');
is( count($results), 25, 'got 25 results' );

