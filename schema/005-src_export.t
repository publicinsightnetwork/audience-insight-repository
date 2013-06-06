#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Alter the src_export table to add columns:
 *
 *   se_type        char(1) not null default 'L'
 *   se_notes       text    null
 *   se_xid         int(11) null
 *   se_ref_type    char(1) null
 *   se_status      char(1) not null default 'I'
 *
 * Remove 'unique' constraint on:
 *
 *   se_name
 *
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// helper to check for a column existence
function has_column($name) {
    global $conn;
    $rs = $conn->fetchAll('describe src_export');
    foreach ($rs as $flddef) {
        if ($flddef['Field'] == $name) {
            return $flddef; //found!
        }
    }
    return false;
}

// show profile
$meta = AIR2_DBManager::$master;
$prof = AIR2_DBManager::$master_profile;
$host = $meta['hostname'];
$db   = $meta['dbname'];
//diag(" > Checking table src_export on $prof ($host::$db) .... ");

// columns to add
$add_columns = array(
    'se_type'       => "char(1) not null default 'L'",
    'se_notes'      => 'text null',
    'se_xid'        => 'int(11) null',
    'se_ref_type'   => 'char(1) null',
    'se_status'     => "char(1) not null default 'I'",
);

plan(12);

// add missing
foreach ($add_columns as $name => $def) {
    if (has_column($name)) {
        pass("column '$name' exists");
    }
    else {
        try {
            $conn->execute("alter table src_export add column $name $def");
            pass("added column '$name'");
        }
        catch (Exception $e) {
            fail("error adding column '$name'");
            diag("$e");
        }
    }
}

// check for columns
foreach ($add_columns as $name => $def) {
    if (has_column($name)) {
        pass("has column '$name'");
    }
    else {
        fail("missing column '$name'");
    }
}

// remove unique on se_name
$def = has_column('se_name');
if ($def['Key'] != 'UNI') {
    pass('se_name not unique');
}
else {
    // get the actual index name
    $indexes = $conn->fetchAll('show indexes from src_export');
    $idxname = false;
    foreach ($indexes as $idx) {
        if ($idx['Column_name'] == 'se_name') {
            $idxname = $idx['Key_name'];
            break;
        }
    }

    // fail if no index at this point
    if (!$idxname) {
        fail('Missing unique index on se_name');
    }
    else {
        $conn->execute("alter table src_export drop index $idxname");
        pass('Dropped unique index');
    }
}

// double-check
$def = has_column('se_name');
if ($def['Key'] != 'UNI') {
    pass('se_name not unique');
}
else {
    fail('se_name still unique!');
}


