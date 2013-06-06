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
/*
 * Script to check the encoding/decoding of ApacheAuthTkt
 *
 */

//plan('no plan');
plan(10);

require_once 'Apache_AuthTkt.php';

$airuser_path = APPPATH.'/libraries/AirUser.php';
//diag('including AirUser class');
require_once $airuser_path;

// some data to work with
$usrname = 'username01';
$usrid = 99989;
$data = array(
    1000 => ACTION_ORG_READ | ACTION_ORG_UPDATE,
    2000 => ACTION_ORG_READ,
    3000 => AIR2_AUTHZ_ROLE_R,
);
$json_data = json_encode($data);
$ts = time();
$ip = '192.168.1.2';

$myauth = new Apache_AuthTkt(array(
        'conf' => AIR2_AUTH_TKT_CONFIG_FILE
    )
);
$apache_tkt = $myauth->create_ticket(array(
        'user' => $usrname,
        'data' => $json_data,
        'ts'   => $ts,
        'ip'   => $ip
    )
);
$apache_info = $myauth->validate_ticket($apache_tkt, $ip);

ok($apache_info, 'apache tkt validate');
if ($apache_info) {
    is($apache_info['ts'], $ts, 'apache decrypt timestamp');
    is($apache_info['uid'], $usrname, 'apache decrypt username');
    is_deeply((array)json_decode($apache_info['data'], true), $data,
        'apache decrypt authz array');
}

/******************************************************************************/

$myuser = new AirUser();
$myuser->set_authz($data);
$tmp = $myuser->get_tkt($usrname, $usrid);
foreach ($tmp as $ckname => $ckval) {
    $_COOKIE[$ckname] = $ckval;
    //diag($ckname . '=' . $ckval);
}
unset($myuser);
error_reporting(E_ERROR); //suppress "headers-already-sent" warning
$myuser2 = new AirUser();


ok($myuser2->has_valid_tkt(), 'AirUser tkt creation');
if ($myuser2->has_valid_tkt()) {
    is_deeply($myuser2->get_authz(), $data, 'AirUser decrypt authz array');
}

// authz check
$user2_authz = $myuser2->get_authz();
ok( $user2_authz['1000'] & ACTION_ORG_READ, "user is reader for organization1");
ok( $user2_authz['1000'] & ACTION_ORG_UPDATE, "user is writer for organization1");
ok( $user2_authz['2000'] & ACTION_ORG_READ, "user is reader for organization2");
ok( $user2_authz['3000'] & ACTION_ORG_READ, "user is reader for organization3");


?>
