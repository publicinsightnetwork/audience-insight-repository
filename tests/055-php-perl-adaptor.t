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
require_once 'phperl/callperl.php';

// init
AIR2_DBManager::init();
plan(18);


/**********************
 * Dynamic call to random_str
 */
$str = CallPerl::exec('AIR2::Utils->random_str');
ok( $str && is_string($str), 'random_str1 - ok' );
is( strlen($str), 12, 'random_str1 - len' );

$str = CallPerl::exec('AIR2::Utils->random_str', 4);
ok( $str && is_string($str), 'random_str2 - ok' );
is( strlen($str), 4, 'random_str2 - len' );

try {
    $str = CallPerl::exec('AIR2::Utils->random_str', -1);
    fail( 'random_str3 - no exception on bad params' );
}
catch (Exception $e) {
    like( $e->getMessage(), '/positive integer/', 'random_str3 - bad params msg' );
}


/**********************
 * Dynamic call to str_to_uuid
 */
$str = CallPerl::exec('AIR2::Utils->str_to_uuid', 'blahstr');
ok( $str && is_string($str), 'str_to_uuid1 - ok' );
is( strlen($str), 12, 'str_to_uuid1 - len' );
is( $str, air2_str_to_uuid('blahstr'), 'str_to_uuid1 - match' );

$str = CallPerl::exec('AIR2::Utils->str_to_uuid', 'blahstr', 4);
ok( $str && is_string($str), 'str_to_uuid2 - ok' );
is( strlen($str), 4, 'str_to_uuid2 - len' );
is( $str, air2_str_to_uuid('blahstr', 4), 'str_to_uuid2 - match' );


/**********************
 * Static call to get_search_port
 */
$n = CallPerl::exec('AIR2::Config::get_search_port');
ok( $n, 'get_search_port - ok' );
ok( intval($n) !== 0, 'get_search_port - inval' );


/**********************
 * Json returns an integer
 */
$childs = array();
$children = Organization::get_org_children(1);
foreach ($children as $orgid) { $childs[$orgid] = true; };

$res = CallPerl::exec('AIR2::Organization::get_org_children', 1);
ok( $res && is_array($res), 'get_org_children - ok' );
is( count($res), count($children), 'get_org_children - counts' );

$allmatch = true;
$allints = true;
foreach ($res as $orgid) {
    if (!isset($childs[$orgid])) $allmatch = false;
    if (!is_int($orgid)) $allints = false;
}
ok( $allmatch, 'get_org_children - all match' );
ok( $allmatch, 'get_org_children - all ints' );

/************************
 * cause stderr to block
 */

$res = CallPerl::exec('AIR2::Utils::generate_stderr');
//diag_dump( $res );
ok( !strlen($res), "stderr does not block" );

