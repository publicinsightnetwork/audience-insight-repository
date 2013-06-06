#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Schema changes to src_response_set to add geo caching columns.
 *
 * @package default
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(6);

/**
 * Add a col if it doesn't exist.
 *
 * @author sgilbertson
 * @param Doctrine_Connection $db         Database connection.
 * @param string  $table      Table name.
 * @param string  $col        Column name.
 * @param string  $definition SQL definition of column.
 * @return boolean  True if already exists or creation succeeded. False if error in creation.
 * */
function add_col($db, $table, $col, $definition) {
    $cols = $db->fetchAll("describe $table");
    $cols = just_vals($cols);

    if (in_array($col, $cols)) {
        return true;
    }
    else {
        try {
            $db->execute("alter table $table add column $col $definition");
            return true;
        }
        catch (Exception $ex) {
            return false;
        }
    }
}


/**
 * Reduce a query result to just the values for whatever was selected, numerically indexed.
 *
 * Utility function.
 *
 * @author sgilbertson
 * @param unknown $result
 * @return array
 * */
function just_vals($result) {
    $out = array();

    foreach ($result as $i => $row) {
        $row = array_values($row);
        $out []= $row[0];
    }

    return $out;
}


/**
 *
 *
 * @param unknown $db
 * @param unknown $table
 * @param unknown $constraint_name
 * @param unknown $def
 * @return unknown
 */
function add_FK($db, $table, $constraint_name, $def) {
    $table_def = $db->fetchAll("show create table $table");
    $table_def = $table_def[0]['Create Table'];

    if (preg_match("/$constraint_name/", $table_def)) {
        return true;
    }

    try {
        $db->execute("alter table $table add constraint $constraint_name $def");
        return true;
    }

    catch (Exception $ex) {
        diag("Failed to add constraint: " . $ex->getMessage());
        return false;
    }
}


/**
 *
 *
 * @param unknown $db
 * @param unknown $table
 * @param unknown $idx_name
 * @param unknown $column
 * @return unknown
 */
function add_index($db, $table, $idx_name, $column) {
    $table_def = $db->fetchAll("show create table $table");
    $table_def = $table_def[0]['Create Table'];

    if (preg_match("/$idx_name/", $table_def)) {
        return true;
    }

    try {
        $db->execute("alter table $table add index $idx_name ($column)");
        return true;
    }

    catch (Exception $ex) {
        diag("Failed to add index: " . $ex->getMessage());
        return false;
    }

}

$current_cols = array();
$rs = $conn->fetchAll('describe src_response_set');
foreach ($rs as $flddef) {
    $current_cols[$flddef['Field']] = true;
}

// check-and-add
$add_columns = array(
    'srs_city'  => 'varchar(128)',
    'srs_state'  => 'char(2)',
    'srs_country'  => 'char(2)',
    'srs_county'  => 'varchar(128)',
    'srs_lat'  => 'float',
    'srs_long'  => 'float',
);
foreach ($add_columns as $name => $def) {
    if (isset($current_cols[$name])) {
        pass("column $name exists");
    }
    else {
        try {
            $conn->execute("alter table src_response_set add column $name $def");
            pass("added column $name");
        }
        catch (Exception $e) {
            fail("error adding column $name");
            diag("$e");
        }
    }
}
