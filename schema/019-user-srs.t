#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Create user_srs table
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(2);


/**********************
 * 1) create user_srs table
 */
$has_tbl = false;
$rs = $conn->fetchColumn('show tables', array(), 0);
foreach ($rs as $tname) {
    if ($tname == 'user_srs') $has_tbl = true;
}

if (!$has_tbl) {
    $doc_tbl = Doctrine::getTable('UserSrs');
    $doc_tbl->export();
    pass( 'user_srs created' );
}
else {
    pass( 'user_srs exists' );
}


/**********************
 * 2) convert existing user_visit data
 */
$n = $conn->fetchOne('select count(*) from user_srs', array(), 0);

if ($n > 0) {
    pass("user_srs already converted");
}
else {
    $q    = "select distinct uv_user_id, uv_xid from user_visit where " .
            "uv_ref_type='R' and uv_xid in (select srs_id from src_response_set)";
    $rs   = $conn->fetchAll($q);
    $flds = '(usrs_user_id, usrs_srs_id, usrs_read_flag, usrs_favorite_flag)';
    $ins  = "insert ignore into user_srs $flds values (?, ?, true, false)";

    $n = 0;
    foreach ($rs as $row) {
        $n += $conn->exec($ins, array($row['uv_user_id'], $row['uv_xid']));
    }
    pass("converted $n user_srs");
}
