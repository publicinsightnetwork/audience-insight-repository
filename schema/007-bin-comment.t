#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Add field to 'batch_item' table
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(2);

// table may no longer exist
$rs = $conn->fetchColumn('show tables', array(), 0);
if (!in_array('batch_item', $rs)) {
    pass("batch_item already nuked!");
    pass("batch_item already nuked!");
    exit;
}

// initial check
$has_fld = false;
$rs = $conn->fetchAll('describe batch_item');
foreach ($rs as $flddef) {
    if ($flddef['Field'] == 'bitem_notes') {
        $has_fld = true;
    }
}

// change
if (!$has_fld) {
    $conn->execute("alter table batch_item add column bitem_notes varchar(255) null");
    pass("added bitem_notes");
}
else {
    pass("bitem_notes already exists");
}

// double check
$has_fld = false;
$rs = $conn->fetchAll('describe batch_item');
foreach ($rs as $flddef) {
    if ($flddef['Field'] == 'bitem_notes') {
        $has_fld = true;
    }
}
is( $has_fld, true, 'has notes field' );
