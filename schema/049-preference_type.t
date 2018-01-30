#!/usr/bin/env php
<?php

require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 *
 * @param unknown $db
 * @param unknown $table
 * @param unknown $idx_name
 * @param unknown $sql
 * @return unknown
 */


function add_index($db, $table, $idx_name, $sql) {
    $table_def = $db->fetchAll("show create table $table");
    $table_def = $table_def[0]['Create Table'];

    if (preg_match("/$idx_name/", $table_def)) {
        return true;
    }

    try {
        $db->execute($sql);
        return true;
    }

    catch (Exception $ex) {
        diag("Failed to add index: " . $ex->getMessage());
        return false;
    }

}


AIR2_DBManager::init();
$db_metadata = AIR2_DBManager::$master;
$db = AIR2_DBManager::get_master_connection();

$hostname = $db_metadata['hostname'];
$dbname = $db_metadata['dbname'];
//diag(" > Creating or updating user_visit table on $hostname::$dbname .... ");

plan(1);

ok(
    add_index($db, 'preference_type', 'preference_type_pt_identifier_idx',
        "alter table preference_type add unique index preference_type_pt_identifier_idx (pt_identifier)"
    ),
    "add preference_type_pt_identifier_idx"
);
