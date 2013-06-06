#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Remove userstamp fields from tank_response_set and tank_response
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(8);

/**********************
 * 1) tank_response_set
 */
$dropthem = array(
    'srs_cre_user' => false,
    'srs_upd_user' => false,
    'srs_cre_dtim' => false,
    'srs_upd_dtim' => false,
);
$rs = $conn->fetchAll('describe tank_response_set');
foreach ($rs as $flddef) {
    if (array_key_exists($flddef['Field'], $dropthem)) {
        $dropthem[$flddef['Field']] = true;
    }
}

foreach ($dropthem as $fld => $exists) {
    if ($exists) {
        $conn->exec("alter table tank_response_set drop column $fld");
        pass("dropped $fld");
    }
    else {
        pass("$fld already dropped");
    }
}

/**********************
 * 2) tank_response
 */
$dropthem = array(
    'sr_cre_user' => false,
    'sr_upd_user' => false,
    'sr_cre_dtim' => false,
    'sr_upd_dtim' => false,
);
$rs = $conn->fetchAll('describe tank_response');
foreach ($rs as $flddef) {
    if (array_key_exists($flddef['Field'], $dropthem)) {
        $dropthem[$flddef['Field']] = true;
    }
}

foreach ($dropthem as $fld => $exists) {
    if ($exists) {
        $conn->exec("alter table tank_response drop column $fld");
        pass("dropped $fld");
    }
    else {
        pass("$fld already dropped");
    }
}
