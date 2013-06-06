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
require_once APPPATH.'/../tests/Test.php';
require_once APPPATH.'/../tests/AirHttpTest.php';

// init
AIR2_DBManager::init();
$browser = new AirHttpTest();
$browser->set_test_user();
$browser->set_content_type(AirHttpTest::$JSON);
$csv_dir = dirname(__FILE__).'/csv';

// helper function for POSTing a file
function upload_file($url, $fld_name, $file, $put=false) {
    global $browser;

    $session = curl_init($browser->base_url.$url);
    curl_setopt($session, CURLOPT_HEADER, false);
    curl_setopt($session, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($session, CURLOPT_POST, true);

    // tunnel put method
    $params = array($fld_name => "@$file");
    if ($put) {
        $params['x-tunneled-method'] = 'PUT';
    }

    curl_setopt($session, CURLOPT_POSTFIELDS, $params);
    foreach ($browser->cookies as $nm => $ck) {
        curl_setopt($session, CURLOPT_COOKIE, "$nm=$ck");
    }
    curl_setopt($session, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($session, CURLOPT_SSL_VERIFYHOST, false);

    return curl_exec($session);
}


plan(75);
$test_uuids = array();

/**********************
 * Creating
 */
// invalid file (non-csv)
$img_path = AIR2_DOCROOT.'/css/img/icons/address-book-blue.png';
$resp = upload_file('csv.json', 'csvfile', $img_path);
ok( $resp, 'bad type' );
ok( $json = json_decode($resp, true), 'bad type - decode' );
is( $json['success'], false, 'bad type - unsuccess' );
ok( !isset($json['radix']), 'bad type - no radix' );
like( $json['message'], '/must have the extension/i', 'bad type - message' );

// upload the wrong fieldname
$resp = upload_file('csv.json', 'fake', "$csv_dir/test_valid.csv");
ok( $resp, 'wrong field' );
ok( $json = json_decode($resp, true), 'wrong field - decode' );
is( $json['success'], false, 'wrong field - unsuccess' );
ok( !isset($json['radix']), 'wrong field - no radix' );
like( $json['message'], '/disallowed create data/i', 'wrong field - message' );

// upload no file
ok( $resp = $browser->http_post("csv"), 'no file' );
is( $browser->resp_code(), 400, 'no file - response code' );
ok( $json = json_decode($resp, true), 'no file - decode' );
is( $json['success'], false, 'no file - unsuccess' );
ok( !isset($json['radix']), 'no file - no radix' );
like( $json['message'], '/missing required field/i', 'no file - message' );

// upload valid csv
$resp = upload_file('csv.json', 'csvfile', "$csv_dir/test_header.csv");
ok( $resp, 'valid' );
ok( $json = json_decode($resp, true), 'valid - decode' );
is( $json['success'], true, 'valid - success' );
ok( isset($json['radix']), 'valid - radix' );
is( $json['radix']['tank_name'], 'test_header.csv', 'valid - name' );
is( $json['radix']['tank_status'], Tank::$STATUS_CSV_NEW, 'valid - status' );
$meta = json_decode($json['radix']['tank_meta'], true);
is( $meta['valid_file'], true, 'valid - file' );
is( $meta['valid_header'], true, 'valid - header' );
ok( isset($meta['file_size']), 'valid - filesize' );
$uuid1 = $json['radix']['tank_uuid'];
$test_uuids[] = $uuid1;

// upload invalid csv
$resp = upload_file('csv.json', 'csvfile', "$csv_dir/test_valid.csv");
ok( $resp, 'invalid' );
ok( $json = json_decode($resp, true), 'invalid - decode' );
is( $json['success'], true, 'invalid - success' );
ok( isset($json['radix']), 'invalid - radix' );
$meta = json_decode($json['radix']['tank_meta'], true);
is( $meta['valid_file'], true, 'invalid - file' );
is( $meta['valid_header'], false, 'invalid - header' );
$uuid2 = $json['radix']['tank_uuid'];
$test_uuids[] = $uuid2;


/**********************
 * Updating
 */
// try to POST an update
$resp = upload_file("csv/$uuid1.json", 'csvfile', "$csv_dir/test_invalid_1.csv");
ok( $resp, 'POST update' );
ok( $json = json_decode($resp, true), 'POST update - decode' );
is( $json['success'], false, 'POST update - unsuccess' );
like( $json['message'], '/invalid path for create/i', 'POST update - message' );

// re-upload different filename
$resp = upload_file("csv/$uuid1.json", 'csvfile', "$csv_dir/test_invalid_1.csv", true);
ok( $resp, 'different file' );
ok( $json = json_decode($resp, true), 'different file - decode' );
is( $json['success'], false, 'different file - unsuccess' );
like( $json['message'], '/you must upload the original file/i', 'different file - message' );

// re-upload same filename
$tank = AIR2_Record::find('Tank', $uuid1);
$tank->set_meta_field('valid_header', false); // should change back
$tank->save();
$resp = upload_file("csv/$uuid1.json", 'csvfile', "$csv_dir/test_header.csv", true);
ok( $resp, 'same file' );
ok( $json = json_decode($resp, true), 'same file - decode' );
is( $json['success'], true, 'same file - success' );
$meta = json_decode($json['radix']['tank_meta'], true);
is( $meta['valid_file'], true, 'same file - file' );
is( $meta['valid_header'], true, 'same file - header' );


/**********************
 * Preview
 */
// preview the valid file
ok( $resp = $browser->http_get("csv/$uuid1/preview"), 'preview valid' );
ok( $json = json_decode($resp, true), 'preview valid - decode' );
is( $json['success'], true, 'preview valid - success' );
is( count($json['radix']), 3, 'preview valid - count(radix)' );
$one = $json['radix'][0];
ok( isset($one['Username']), 'preview valid - radix Username' );
ok( isset($one['First Name']), 'preview valid - radix First' );
ok( isset($one['Last Name']), 'preview valid - radix Last' );
ok( isset($one['City']), 'preview valid - radix City' );
is( $json['meta']['total'], 6, 'preview valid -total' );
is( count($json['meta']['invalid_headers']), 0, 'preview valid - invalid_headers' );

// change limit
ok( $resp = $browser->http_get("csv/$uuid1/preview?limit=4"), 'preview limit' );
ok( $json = json_decode($resp, true), 'preview limit - decode' );
is( $json['success'], true, 'preview limit - success' );
is( count($json['radix']), 4, 'preview limit - count(radix)' );
is( $json['meta']['total'], 6, 'preview limit -total' );

// preview the invalid file
ok( $resp = $browser->http_get("csv/$uuid2/preview"), 'preview invalid' );
ok( $json = json_decode($resp, true), 'preview invalid - decode' );
is( $json['success'], true, 'preview invalid - success' );
is( count($json['radix']), 3, 'preview invalid - count(radix)' );
is( $json['meta']['total'], 8, 'preview invalid -total' );

// update the delimiter and try again
$radix = json_encode(array('csv_delim' => ';'));
ok( $resp = $browser->http_put("csv/$uuid2", array('radix' => $radix)), 'update delim' );
is( $browser->resp_code(), 200, 'update delim - resp code' );
ok( $json = json_decode($resp, true), 'update delim - decode' );
$meta = json_decode($json['radix']['tank_meta'], true);
is( $meta['csv_delim'], ';', 'update delim - delim' );
is( $meta['csv_encl'], '"', 'update delim - encl' );

// re-preview the invalid file
ok( $resp = $browser->http_get("csv/$uuid2/preview"), 're-preview invalid' );
ok( $json = json_decode($resp, true), 're-preview invalid - decode' );
is( $json['success'], true, 're-preview invalid - success' );
is( count($json['radix']), 3, 're-preview invalid - count(radix)' );
is( $json['meta']['total'], 3, 're-preview invalid -total' );
is( count($json['meta']['invalid_headers']), 3, 're-preview invalid - invalid_headers' );


/**********************
 * Cleanup
 */
$q = Doctrine_Query::create()->from('Tank')->whereIn('tank_uuid', $test_uuids);
$to_delete = $q->execute();
foreach ($to_delete as $rec) {
    $rec->delete();
}
