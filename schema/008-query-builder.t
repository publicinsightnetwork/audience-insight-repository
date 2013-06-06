#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Schema changes related to query templates (for querybuilder)
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(14);


/**********************
 * 1) profile_map table
 */
$has_tbl = false;
$rs = $conn->fetchColumn('show tables', array(), 0);
foreach ($rs as $tname) {
    if ($tname == 'profile_map') {
        $has_tbl = true;
    }
}

// create profile_map
if (!$has_tbl) {
    $doc_tbl = Doctrine::getTable('ProfileMap');
    $doc_tbl->export();
    pass( 'profile_map created' );
}
else {
    pass( 'profile_map exists' );
}

// check for fixture
$num = $conn->fetchOne('select count(*) from profile_map', array(), 0);
if ($num < 1) {
    $fixture = APPPATH."/fixtures/base/ProfileMap.yml";
    Doctrine::loadData($fixture);

    // re-check
    $num = $conn->fetchOne('select count(*) from profile_map', array(), 0);
    ok( $num > 0, 'profile_map fixture loaded' );
}
else {
    pass( 'profile_map already populated' );
}


/**********************
 * 2) question table changes
 */
$current_cols = array();
$rs = $conn->fetchAll('describe question');
foreach ($rs as $flddef) {
    $current_cols[$flddef['Field']] = true;
}

// check-and-add
$add_columns = array(
    'ques_pmap_id'      => "integer null",
    'ques_locks'        => 'varchar(255) null',
    'ques_public_flag'  => 'tinyint(1) not null default 0',
    'ques_resp_type'    => "char(1) not null default 'S'",
    'ques_resp_opts'    => 'varchar(255) null',
    'ques_template'     => 'varchar(40)',
);
foreach ($add_columns as $name => $def) {
    if (isset($current_cols[$name])) {
        pass("column $name exists");
    }
    else {
        try {
            $conn->execute("alter table question add column $name $def");
            pass("added column $name");
        }
        catch (Exception $e) {
            fail("error adding column $name");
            diag("$e");
        }
    }
}


/**********************
 * 4) inquiry table changes
 */
$current_cols = array();
$rs = $conn->fetchAll('describe inquiry');
foreach ($rs as $flddef) {
    $current_cols[$flddef['Field']] = true;
}

// check-and-add
$add_columns = array(
    'inq_stale_flag'   => "tinyint(1) not null default 1",
    'inq_tpl_opts'     => "varchar(255) null",
    'inq_deadline_msg' => "text null",
    'inq_confirm_msg'  => "text null",
    'inq_cache_user'   => "integer null",
    'inq_cache_dtim'   => "datetime null",
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
