#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Add language and region to our "locale" schema, and reload the fixture
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(3);


/**********************
 * 1) locale table changes
 */
$current_cols = array();
$rs = $conn->fetchAll('describe locale');
foreach ($rs as $flddef) {
    $current_cols[$flddef['Field']] = true;
}

// check-and-add
$add_columns = array(
    'loc_lang'      => "varchar(255) null",
    'loc_region'    => 'varchar(255) null',
);
foreach ($add_columns as $name => $def) {
    if (isset($current_cols[$name])) {
        pass("column $name exists");
    }
    else {
        try {
            $conn->execute("alter table locale add column $name $def");
            pass("added column $name");
        }
        catch (Exception $e) {
            fail("error adding column $name");
            diag("$e");
        }
    }
}


/**********************
 * 2) reload fixture
 */
$count = 'select count(*) from locale where loc_lang is not null';
$n = $conn->fetchOne($count, array(), 0);

if ($n > 0) {
    pass("fixture already loaded");
}
else {
    try {
        // THIS IS DANGEROUS ... but should work since loc_id is in the
        // fixture file
        $conn->execute('SET FOREIGN_KEY_CHECKS = 0');
        Doctrine::loadData(APPPATH.'fixtures/base/Locale.yml', false);
        $n = $conn->fetchOne($count, array(), 0);
        if ($n > 0) {
            pass("fixture loaded successfully");
        }
        else {
            fail("failed to load fixture!");
        }
    }
    catch (Exception $e) {
        fail("problem loading fixture!");
        diag("$e");
    }
    $conn->execute('SET FOREIGN_KEY_CHECKS = 1');
}
