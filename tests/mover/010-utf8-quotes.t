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
require_once APPPATH.'/../tests/models/TestProject.php';
require_once APPPATH.'/../tests/models/TestOrganization.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_connection();
$browser = new AirHttpTest();
$browser->set_content_type(AirHttpTest::$JSON);
$browser->set_test_user();
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


plan(19);

/**********************
 * Upload a CSV file with all sorts o' crazy-quotes
 */
$resp = upload_file('csv.json', 'csvfile', "$csv_dir/test_quotes_utf8.csv");
ok( $resp, 'upload valid' );
ok( $json = json_decode($resp, true), 'upload valid - decode' );
ok( isset($json['success']) && $json['success'], 'upload valid - success' );
$uuid = $json['radix']['tank_uuid'];


/**********************
 * check file for non-utf8
 */
$str = file("$csv_dir/test_quotes_utf8.csv");
ok( !Encoding::is_utf8($str[1]), 'test file contains non-utf8' );

$fin = fopen("$csv_dir/test_quotes_utf8.csv", 'r');
$obj = fgetcsv($fin, null);
$obj2 = fgetcsv($fin, null);

$str_invalid = sprintf("neat %ccurly quotes", 145);
is( $obj2[5], $str_invalid, 'fifth column is invalid string' );
ok( !Encoding::is_utf8($obj2[5]), 'fifth column is non-UTF8' );


/**********************
 * Set meta
 */
$rec = AIR2_Record::find('Tank', $uuid);
$o = new TestOrganization();
$o->save();
$p = new TestProject();
$p->save();
$data = array(
    'org_uuid' => $o->org_uuid,
    'prj_uuid' => $p->prj_uuid,
    'evdesc'   => '1234',
    'evdtim'   => air2_date(),
    'evtype'   => 'E',
    'evdir'    => 'I',
);
ok( $resp = $browser->http_put("csv/$uuid", array('radix' => json_encode($data))), 'set meta' );
is( $browser->resp_code(), 200, 'set meta - response code' );
ok( $json = json_decode($resp, true), 'set meta - decode' );
is( $json['success'], true, 'set meta - success' );


/**********************
 * Submit the file
 */
$radix = json_encode(array('nojob' => 1));
ok( $resp = $browser->http_post("csv/$uuid/submit", array('radix' => $radix)), 'submit' );
is( $browser->resp_code(), 200, 'submit - 200' );
ok( $json = json_decode($resp, true), 'submit - decode' );
ok( $json['success'], 'submit - success' );


/**********************
 * check the tank_source table
 */
$rs = $conn->fetchAll('select * from tank_source where tsrc_tank_id = ?', array($rec->tank_id));

$first = $rs[0]['src_first_name'];
$last = $rs[0]['src_last_name'];
$pre = $rs[0]['src_pre_name'];
$post = $rs[0]['src_post_name'];

ok( Encoding::is_utf8($first), 'first is utf8' );
ok( Encoding::is_utf8($last), 'last is utf8' );
ok( Encoding::is_utf8($pre), 'pre is utf8' );
ok( Encoding::is_utf8($post), 'post is utf8' );

// check our non-utf8 string
isnt( $post, $str_invalid, 'post name changed to utf8' );

// cleanup
$rec->delete();
