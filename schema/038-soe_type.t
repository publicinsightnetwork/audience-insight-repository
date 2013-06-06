#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Schema changes related to email integration.
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(2);

/**********************
 * 1) add src_org_email.soe_type
 */
function has_column($tbl, $name) {
    global $conn; $rs = $conn->fetchAll("describe $tbl");
    foreach ($rs as $flddef) { if ($flddef['Field'] == $name) return $flddef; }
    return false;
}
if (has_column('src_org_email', 'soe_type')) {
    pass("src_org_email.soe_type already exists");
}
else {
    $conn->execute("alter table src_org_email add column soe_type char(1) NOT NULL default 'L'");
    pass("added src_org_email.soe_type");
}

/**********************
 * 2) add soe_type to the unique index
 */
function index_name($tbl, $column, $unique=true) {
    global $conn;
    $u = $unique ? 'false' : 'true';
    $rs = $conn->fetchRow("show indexes from $tbl where Column_name='$column' and Non_unique=$u");
    return $rs ? $rs['Key_name'] : false;
}
if (index_name('src_org_email', 'soe_type')) {
    pass("soe_type already in index");
}
else {
    $idx = index_name('src_org_email', 'soe_org_id');
    if ($idx) {
        $conn->execute("alter table src_org_email drop index $idx");
    }
    $conn->execute("alter table src_org_email add unique index $idx (soe_sem_id,soe_org_id,soe_type)");

    // re-check
    if (index_name('src_org_email', 'soe_type')) {
        pass("Added unique index $idx");
    }
    else {
        fail("Unable to re-add index $idx");
    }
}
