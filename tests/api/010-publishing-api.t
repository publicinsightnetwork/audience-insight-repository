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

$uri = "/api/public/search.xml?q=hi&a=$testAPIKey";
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

$uri = "/api/public/search.json?q=responseset:8c3764ae8ac4&a=$testAPIKey&h=0";
ok( $jsonResp = $browser->http_get($uri), "GET $uri");
is( $browser->resp_code(), 200, "Successful");
is( $browser->resp_content_type(), 'application/json; charset=utf-8', "JSON content type");
ok( $respJSON = json_decode($jsonResp, true), "parse JSON");

// we expect a certain format for our JSON response
//diag_dump( $respJSON );
ok( $results = $respJSON['results'], 'get results');

//diag_dump( $respJSON );

$found_result = false;

$librarius_srs = AIR2_Record::find('SrcResponseSet', '8c3764ae8ac4');
$srs_last_mod = $librarius_srs->srs_date;
$srs_mtime    = strtotime($librarius_srs->srs_upd_dtim);
$srs_last_mod = preg_replace('/-/', '', $srs_last_mod);
$srs_last_mod = preg_replace('/\ .*$/', '', $srs_last_mod);

foreach ($librarius_srs->SrcResponse as $sr) {
    //diag(sprintf("%s %s => %s", $sr->Question->ques_uuid, $sr->Question->ques_value, $sr->sr_orig_value));
}

// we expect to find this result, but this test is somewhat brittle
// because this is live data from a librarius result.
// We give a hint below in the fail() message that the failure
// might be spurious because the environment is beyond this test's
// control.
// TODO create a test-specific index
$expected_result = array(

    // dezi fields
    'uri'               => '8c3764ae8ac4',
    'title'             => '8c3764ae8ac4',
    'summary'           => '',
    'mtime'             => $srs_mtime,
    'lastmod'           => $srs_last_mod,

    // official fields from API spec
    'src_first_name'    => 'Farrukh',
    'src_last_name'     => 'S',
    'primary_lat'       => '',
    'primary_long'      => '',
    'primary_country'   => '',
    'primary_city'      => 'Gleason',
    'primary_state'     => 'WI',
    'primary_county'    => '',
    'primary_zip'       => '',
    'query_title'       => 'Why are you at the library today -- in person or online?',
    'query_uuid'        => 'b6f315470887',
    'srs_date'          => $librarius_srs->srs_cre_dtim,
    'srs_ts'            => $srs_last_mod,
    'srs_upd_dtim'      => $librarius_srs->srs_upd_dtim,

    // array of questions keyed by ques_uuid
    'questions'         => array(
        'f2c1da7d3772' => array(
            'seq'   => '2',
            'type'  => 'A',
            'value' => 'What brings you to the library today?',
        ),
        'b22a5a56df6e'  => array(
            'seq'   => '3',
            'type'  => 'R',
            'value' => "Please pick one category that best describes what you&#39;re doing at the library today.",
        ),
        '67b3761fe188'  => array(
            'seq'   => '1',
            'type'  => 'T',
            'value' => 'What library are you visiting? (library name, city, state)', 
        ),
        'fc93b011394b'  => array(
            'seq'   => '5',
            'type'  => 'R',
            'value' => 'How are you accessing the library today?',
        ),
        '2631db581afd'  => array(
            'seq'   => '10',
            'type'  => 'A',
            'value' => 'Please share some details or a story that would help us understand your answer -- and the role that libraries play in your life or the life of your community.',
        ),
        'ad3ac1809eab'  => array(
            'seq'   => '14',
            'type'  => 'T',
            'value' => "If it weren&#39;t for the library, I would not...",
        ),
    ),

    // array of responses keyed by ques_uuid
    'responses' => array(
        'f2c1da7d3772'  => "I&#39;m Farrukh",
        'b22a5a56df6e'  => 'research and homework',
        '67b3761fe188'  => 'H, Gleason, WI 54435, USA',
        'fc93b011394b'  => "I&#39;m here in person.",
        '2631db581afd'  => 'Without library people like me are blind in the field of research. Libraries provide us great help in achieving our goals.',
        'ad3ac1809eab'  => '',
    ),
);

// predictable key order
foreach ($results as $r) {
    if ($r['uri'] == '8c3764ae8ac4') {
        $expected_result['score'] = $r['score'];
        //diag_dump($r);
        //diag_dump($expected_result);
        ksortTree($expected_result);
        ksortTree($r);
        is_deeply( $r, $expected_result, "got expected result format");
        $found_result = true;
    }
}
if (!$found_result) {
    fail("Found result -- does the public_responses index contain real Librarius query data?");
}


/**
 *
 *
 * @param unknown $array (reference)
 * @return unknown
 */
function ksortTree( &$array ) {
    if (!is_array($array)) {
        return false;
    }

    ksort($array);
    foreach ($array as $k=>$v) {
        ksortTree($array[$k]);
    }
    return true;
}
