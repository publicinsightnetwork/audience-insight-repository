#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Alter the src_response_set table change the default for srs_type from 
 * "I" to "F".
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(3);

// initial check
$default = null;
$rs = $conn->fetchAll('describe src_response_set');
foreach ($rs as $flddef) {
    if ($flddef['Field'] == 'srs_type') {
        $default = $flddef['Default'];
    }
}

// change
if ($default != 'F') {
    $alt = "set default 'F'";
    $conn->execute("alter table src_response_set alter srs_type $alt");
    pass("updated default");
}
else {
    pass("default already set");
}

// double check
$default = -1;
$rs = $conn->fetchAll('describe src_response_set');
foreach ($rs as $flddef) {
    if ($flddef['Field'] == 'srs_type') {
        $default = $flddef['Default'];
    }
}
is( $default, 'F', 'default is F' );

// also check tank_response_set
$default = null;
$rs = $conn->fetchAll('describe tank_response_set');
foreach ($rs as $flddef) {
    if ($flddef['Field'] == 'srs_type') {
        $default = $flddef['Default'];
    }
}

// change
if ($default != 'F') {
    $alt = "set default 'F'";
    $conn->execute("alter table tank_response_set alter srs_type $alt");
    pass("updated tank_response_set default");
}
else {
    pass("default tank_response_set already set");
}
