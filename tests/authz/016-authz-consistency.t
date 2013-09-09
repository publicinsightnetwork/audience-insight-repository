#!/usr/bin/env php

<?php
require_once 'app/init.php';
require_once APPPATH.'../tests/Test.php';
require_once APPPATH.'../tests/AirHttpTest.php';
require_once APPPATH.'../tests/AirTestUtils.php';
require_once APPPATH.'../tests/models/TestUser.php';
require_once APPPATH.'../tests/models/TestOrganization.php';
require_once APPPATH.'/libraries/AirUser.php';
require_once 'phperl/callperl.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

$testUser = new TestUser();
$testUser->save();

$o = new TestOrganization();
$o->add_users(array($testUser), 3);
$o->save();

$authz = $testUser->get_authz();
$packed = null;
foreach ($authz as $id => $mask) {
    // mask is a 64-bit unsigned int - split it!
    $half1 = $mask >> 32;
    $half2 = $mask & 0xFFFFFFFF;
    $packed .= pack("nNN", $id, $half1, $half2);
}
$encoded = base64_encode($packed);

$opts = array();
$userID = $testUser->user_id;
$perlAuthz = CallPerl::exec('AIR2::User->get_authz', $userID, $opts);
$packedPerlAuthz = CallPerl::exec('AIR2::Utils::pack_authz', $perlAuthz, $opts);

#Not sure about this...
$packedPerlAuthz = trim($packedPerlAuthz);

is($encoded, $packedPerlAuthz, 'Authz are equal');
