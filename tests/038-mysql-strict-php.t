#!/usr/bin/env php
<?php

require_once 'Test.php';
require_once 'app/init.php';
require_once 'AIR2_DBManager.php';

plan(2);

ok( AIR2_DBManager::init(), "init db handles");

$conn = AIR2_DBManager::get_master_connection();
$username = '';
$c = 0;
while ($c++ < 500) {
    $username .= 'z';
}

$sql = "insert into source (src_username,src_uuid,src_cre_user,src_cre_dtim) ".
       "values ('$username', 'abcdef123456',1,'2000-01-01 00:00:00')";
try {
    $conn->execute($sql);
    fail("strict mode fails to prevent invalid insert");
} 
catch (Doctrine_Connection_Exception $e) {
    like( "$e", "/Data too long for column 'src_username'/", "insert too long caught by strict mode");
}

