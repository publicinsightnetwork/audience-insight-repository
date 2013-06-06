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


plan(15);

/**********************
 * Upload a file and check file perms
 */
$resp = upload_file('csv.json', 'csvfile', "$csv_dir/test_valid.csv");
ok( $resp, 'upload valid' );
ok( $json = json_decode($resp, true), 'upload valid - decode' );
ok( isset($json['success']) && $json['success'], 'upload valid - success' );
ok( isset($json['radix']['tank_uuid']), 'upload valid - uuid' );

// get the doctrine record
$uuid = $json['radix']['tank_uuid'];
$rec = Doctrine::getTable('Tank')->findOneBy('tank_uuid', $uuid);
$dir = $rec->get_folder_path();
$path = $rec->get_file_path();

// check the directory
ok( is_dir($dir), 'Directory exists' );
$perm = substr(sprintf('%o', fileperms($dir)), -4);
is( $perm, '0770', 'Directory is group writable' );

// check the uploaded file
ok( is_file($path), 'File exists' );
$perm = substr(sprintf('%o', fileperms($path)), -4);
is( $perm, '0770', 'File is group writable' );

/**********************
 * re-upload the file
 */
$resp = upload_file("csv/$uuid.json", 'csvfile', "$csv_dir/test_valid.csv", true);
ok( $resp, 're-upload' );
ok( $json = json_decode($resp, true), 're-upload - decode' );
ok( isset($json['success']) && $json['success'], 're-upload - success' );

// re-check the uploaded file
ok( is_file($path), 're-upload file exists' );
$perm = substr(sprintf('%o', fileperms($path)), -4);
is( $perm, '0770', 're-upload file is group writable' );

/**********************
 * Delete the tank record
 */
$rec->delete();
ok( !file_exists($path), 'file deleted with record' );
ok( !is_dir($dir), 'directory deleted with record' );



?>
