#!/usr/bin/env php
<?php

require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';


/**
 * Add a col if it doesn't exist.
 *
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


AIR2_DBManager::init();
$db_metadata = AIR2_DBManager::$master;
$db = AIR2_DBManager::get_master_connection();

$hostname = $db_metadata['hostname'];
$dbname = $db_metadata['dbname'];
//diag(" > Creating or updating user_visit table on $hostname::$dbname .... ");

plan(12);

// Create table, if necessary.
$tables = $db->fetchAll('show tables');
// $tables = array_map('just_table_name', $tables);
$tables = just_vals($tables);

if (!in_array('inquiry_user', $tables)) {
    //diag('Table does not exist, creating .... ');

    try {
        $result = $db->execute(
            'create table inquiry_user(' .
            '   iu_id integer not null primary key auto_increment' .
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

// Tie to activity.
is(
    add_col($db, 'inquiry_user', 'iu_type', 'char(1) not null default "W"'),
    true,
    'Column iu_type'
);

is( add_col($db, 'inquiry_user', 'iu_status', 'char(1) not null default "A"'),
    true,
    'column iu_status'
);

is(
    add_col($db, 'inquiry_user', 'iu_inq_id', 'int(11) not null'),
    true,
    'Column iu_inq_id.'
);

// user xref
is(
    add_col($db, 'inquiry_user', 'iu_user_id', 'int(11)'),
    true,
    'Column iu_user_id.'
);

// Creation user.
is (
    add_col($db, 'inquiry_user', 'iu_cre_user', 'int(11) not null'),
    true,
    'Column iu_cre_user.'
);

// Creation time.
is(
    add_col($db, 'inquiry_user', 'iu_cre_dtim', 'datetime not null'),
    true,
    'Column iu_cre_dtim.'
);

// update user.
is (
    add_col($db, 'inquiry_user', 'iu_upd_user', 'int(11) not null'),
    true,
    'Column iu_upd_user.'
);

// update time.
is(
    add_col($db, 'inquiry_user', 'iu_upd_dtim', 'datetime not null'),
    true,
    'Column iu_upd_dtim.'
);

ok (
    add_FK($db, 'inquiry_user', 'inquiry_user_inq_fk',
        'foreign key(`iu_inq_id`) references `inquiry`(`inq_id`) on delete cascade'),
    'FK inquiry_user_inq_fk'
);

ok (
    add_FK($db, 'inquiry_user', 'inquiry_user_user_fk',
        'foreign key(`iu_user_id`) references `user`(`user_id`) on delete cascade'),
    'FK inquiry_user_user_fk'
);

// inq_id + user_id + type == unique
ok(
    add_index($db, 'inquiry_user', 'inquiry_user_idx', 'iu_inq_id,iu_user_id,iu_type'),
    "alter table inquiry_user add unique index inquiry_user_idx (iu_inq_id,iu_user_id,iu_type)"
);

