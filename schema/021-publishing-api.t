#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Schema changes related to query templates (for querybuilder)
 *
 * @package default
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(19);


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


/**********************
 * Add inq_public_flag
 */
$current_cols = array();
$rs = $conn->fetchAll('describe inquiry');
foreach ($rs as $flddef) {
    $current_cols[$flddef['Field']] = true;
}

// check-and-add
$add_columns = array(
    'inq_public_flag'  => 'tinyint(1) not null default 0',
);
foreach ($add_columns as $name => $def) {
    if (isset($current_cols[$name])) {
        pass("column $name exists");
    }
    else {
        try {
            $conn->execute("alter table inquiry add column $name $def");
            pass("added column $name");
        }
        catch (Exception $e) {
            fail("error adding column $name");
            diag("$e");
        }
    }
}

/**********************
 * Add sr_public_flag
 */
$current_cols = array();
$rs = $conn->fetchAll('describe src_response');
foreach ($rs as $flddef) {
    $current_cols[$flddef['Field']] = true;
}

// check-and-add
$add_columns = array(
    'sr_public_flag'  => 'tinyint(1) not null default 0',
);
foreach ($add_columns as $name => $def) {
    if (isset($current_cols[$name])) {
        pass("column $name exists");
    }
    else {
        try {
            $conn->execute("alter table src_response add column $name $def");
            pass("added column $name");
        }
        catch (Exception $e) {
            fail("error adding column $name");
            diag("$e");
        }
    }
}

/*****************************
 * Add sr_public_flag to tank
 */

$current_cols = array();
$rs = $conn->fetchAll('describe tank_response');
foreach ($rs as $flddef) {
    $current_cols[$flddef['Field']] = true;
}

// check-and-add
$add_columns = array(
    'sr_public_flag'  => 'tinyint(1) not null default 0',
);
foreach ($add_columns as $name => $def) {
    if (isset($current_cols[$name])) {
        pass("column $name exists");
    }
    else {
        try {
            $conn->execute("alter table tank_response add column $name $def");
            pass("added column $name");
        }
        catch (Exception $e) {
            fail("error adding column $name");
            diag("$e");
        }
    }
}


// Create table, if necessary.
$tables = $conn->fetchAll('show tables');
$tables = just_vals($tables);

if (!in_array('api_key', $tables)) {
    //diag('Table does not exist, creating .... ');

    try {
        $result = $conn->execute(
            'create table api_key(' .
            '   ak_id integer not null primary key auto_increment' .
            ')'
        );

        pass("api_key table created");
    }
    catch (Exception $ex) {
        fail('Table creation');
        //diag('Error creating table: ' . $ex->getMessage());
    }
}
else {
    pass("api_key table exists");
}

is(
    add_col($conn, 'api_key', 'ak_key', ' varchar(32) not null'),
    true,
    'Column ak_key.'
);

is(
    add_col($conn, 'api_key', 'ak_approved', ' boolean default false'),
    true,
    'Column ak_approved.'
);

is(
    add_col($conn, 'api_key', 'ak_email', ' varchar(255) not null'),
    true,
    'Column ak_email.'
);

is(
    add_col($conn, 'api_key', 'ak_contact', ' varchar(255) not null'),
    true,
    'Column ak_contact.'
);

is(
    add_col($conn, 'api_key', 'ak_cre_dtim', ' datetime not null'),
    true,
    'Column ak_cre_dtim.'
);

is(
    add_col($conn, 'api_key', 'ak_upd_dtim', ' datetime not null'),
    true,
    'Column ak_upd_dtim.'
);

if (!in_array('api_stat', $tables)) {
    //diag('Table does not exist, creating .... ');

    try {
        $result = $conn->execute(
            'create table api_stat(' .
            '   as_id integer not null primary key auto_increment' .
            ')'
        );

        pass("api_stat table created");
        //diag('Table created.');
    }
    catch (Exception $ex) {
        fail('Table creation');
    }
}
else {
    pass("api_stat table exists");
}

ok(
    add_col($conn, 'api_stat', 'as_ak_id', ' integer not null'),
    'Column as_ak_id.'
);

ok (
    add_FK($conn, 'api_stat', 'api_stat_api_key_fk',
        'foreign key(`as_ak_id`) references `api_key`(`ak_id`) on delete cascade'),
    'FK as_ak_id'
);

ok(
    add_col($conn, 'api_stat', 'as_ip_addr', ' varchar(16) not null'),
    'Column as_ip_addr.'
);

ok(
    add_col($conn, 'api_stat', 'as_cre_dtim', ' datetime not null'),
    'Column as_cre_dtim.'
);

ok(
    add_index($conn, 'src_response', 'sr_public_flag_idx', 'sr_public_flag'),
    "alter table src_response add index sr_public_flag_idx (sr_public_flag)"
);

ok(
    add_index($conn, 'question', 'ques_public_flag_idx', 'ques_public_flag'),
    "alter table question add index ques_public_flag_idx (ques_public_flag)"
);

ok(
    add_index($conn, 'src_response_set', 'srs_public_flag_idx', 'srs_public_flag'),
    "alter table src_response_set add index srs_public_flag_idx (srs_public_flag)"
);

ok(
    add_index($conn, 'inquiry', 'inq_public_flag_idx', 'inq_public_flag'),
    "alter table inquiry add index inq_public_flag_idx (inq_public_flag)"
);
