#!/usr/bin/env php
<?php

require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';


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


AIR2_DBManager::init();
$db_metadata = AIR2_DBManager::$master;
$db = AIR2_DBManager::get_master_connection();

$hostname = $db_metadata['hostname'];
$dbname = $db_metadata['dbname'];
//diag(" > Creating or updating user_visit table on $hostname::$dbname .... ");

plan(7);

// Create table, if necessary.
$tables = $db->fetchAll('show tables');
// $tables = array_map('just_table_name', $tables);
$tables = just_vals($tables);

if (!in_array('user_visit', $tables)) {
    //diag('Table does not exist, creating .... ');

    try {
        $result = $db->execute(
            'create table user_visit(' .
            '   uv_id integer not null primary key auto_increment' .
            ') engine = InnoDB'
        );

        pass();
        //diag('Table created.');
    }
    catch (Exception $ex) {
        fail('Table creation');
        //diag('Error creating table: ' . $ex->getMessage());
    }
}
else {
    //diag('Table exists.');
    pass();
}

// Add columns. Do this individually so we can support upgrading.
//diag('Checking/creating columns .... ');

// Tie to user.
is(
    add_col($db, 'user_visit', 'uv_user_id', 'int(11) not null'),
    true,
    'Column uv_user_id.'
);

// Xid/reference type (table).
is(
    add_col($db, 'user_visit', 'uv_ref_type', 'varchar(1) collate utf8_unicode_ci not null'),
    true,
    'Column uv_ref_type.'
);

// Xid.
is(
    add_col($db, 'user_visit', 'uv_xid', 'int(11) not null'),
    true,
    'Column uv_xid.'
);

// IP address of user.
is(
    add_col($db, 'user_visit', 'uv_ip', 'int(10) unsigned not null'),
    true,
    'Column uv_ip.'
);

// Creation user.
is (
    add_col($db, 'user_visit', 'uv_cre_user', 'int(11) not null'),
    true,
    'Column uv_cre_user.'
);

// Creation time.
is(
    add_col($db, 'user_visit', 'uv_cre_dtim', 'datetime not null'),
    true,
    'Column uv_cre_dtim.'
);

//diag('Done.');
