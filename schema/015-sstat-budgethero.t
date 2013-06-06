#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Add some stuff to src_stat to allow easy lookups of budget-hero
 * related sources.
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(2);

/**********************
 * Add columns
 */
$current_cols = array();
$rs = $conn->fetchAll('describe src_stat');
foreach ($rs as $flddef) {
    $current_cols[$flddef['Field']] = true;
}

// check-and-add
$add_columns = array(
    'sstat_bh_play_dtim'   => "datetime null",
    'sstat_bh_signup_dtim' => "datetime null",
);
foreach ($add_columns as $name => $def) {
    if (isset($current_cols[$name])) {
        pass("column $name exists");
    }
    else {
        try {
            $conn->execute("alter table src_stat add column $name $def");
            pass("added column $name");
        }
        catch (Exception $e) {
            fail("error adding column $name");
            diag("$e");
        }
    }
}
