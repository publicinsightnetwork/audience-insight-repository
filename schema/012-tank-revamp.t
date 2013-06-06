#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Tank changes for 2.1.2
 *
 * -add tank_errors
 * -add tank_xuuid
 * -add tsrc_created_flag
 * -yank tank alias fields
 * -alter tank_status/tsrc_status to match new theme
 * -allow null tank_activity.tact_dtim
 *
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// helper to check for a field
function has_column($table, $name) {
    global $conn;
    $rs = $conn->fetchAll("describe $table");
    foreach ($rs as $flddef) {
        if ($flddef['Field'] == $name) return $flddef;
    }
    return false;
}

plan(24);


/**********************
 * 1) add some columns
 */
$add_these = array(
    array('tank', 'tank_errors', 'text null'),
    array('tank', 'tank_xuuid', 'varchar(255) null'),
    array('tank_source', 'tsrc_created_flag', "tinyint(1) not null default '0'"),  
);

foreach ($add_these as $row) {
    $tbl = $row[0];
    $col = $row[1];
    $def = $row[2];
    if (!has_column($tbl, $col)) {
        $conn->execute("alter table $tbl add column $col $def");
        pass("added $tbl.$col");
    }
    else {
        pass("$tbl.$col already exists");
    }
    ok( has_column($tbl, $col), "has $tbl.$col" );
}


/**********************
 * 2) drop some columns
 */
$drop_them = array(
    array('tank_source', 'sa_name'),
    array('tank_source', 'sa_first_name'),
    array('tank_source', 'sa_last_name'),
    array('tank_source', 'sa_post_name'),
);

foreach ($drop_them as $row) {
    $tbl = $row[0];
    $col = $row[1];
    if (has_column($tbl, $col)) {
        $conn->exec("alter table $tbl drop column $col");
        pass("dropped $tbl.$col");
    }
    else {
        pass("$tbl.$col already dropped");
    }
    ok( !has_column($tbl, $col), "doesn't have $tbl.$col");
}


/**********************
 * 3) fix existing src_alias, so only one field is non-null
 */
$count = 'select count(*) from src_alias where sa_first_name is not null and sa_last_name is not null';
$n = $conn->fetchOne($count, array(), 0);

if ($n == 0) {
    pass("no multi-alias rows found");
}
else {
    $q = Doctrine_Query::create()->from('SrcAlias');
    $q->addWhere('sa_first_name is not null');
    $q->addWhere('sa_last_name is not null');
    $rs = $q->execute();
    foreach ($rs as $sa) {
        // create another src_alias
        $dup_sa = new SrcAlias();
        $dup_sa->sa_src_id = $sa->sa_src_id;
        $dup_sa->sa_last_name = $sa->sa_last_name;
        $dup_sa->sa_cre_user = $sa->sa_cre_user;
        $dup_sa->sa_cre_dtim = $sa->sa_cre_dtim;
        $dup_sa->sa_upd_user = $sa->sa_upd_user;
        $dup_sa->sa_upd_dtim = $sa->sa_upd_dtim;
        $dup_sa->save();

        // unset last_name on existing
        $sa->sa_last_name = null;
        $sa->save();
    }

    $n = $conn->fetchOne($count, array(), 0);
    if ($n == 0) {
        pass("fixed multi-alias rows");
    }
    else {
        fail("failed to fix multi-alias rows");
    }
}


/**********************
 * 4) convert tank_status to the new ones
 */
$convert = array(
    'N' => Tank::$STATUS_CSV_NEW,//new-csv
    'I' => Tank::$STATUS_LOCKED, //csv import in-progress
    'S' => Tank::$STATUS_READY,  //csv imported
    'F' => Tank::$STATUS_CSV_NEW,//csv import failed
    'D' => Tank::$STATUS_LOCKED, //discrim in-progress
    'T' => Tank::$STATUS_READY,  //discrim complete
);

foreach ($convert as $oldstat => $newstat) {
    $n = $conn->exec("update tank set tank_status = '$newstat' where tank_status = '$oldstat'");
    if ($n > 0) {
        pass("updated $n old tank_status($oldstat) to $newstat");
    }
    else {
        pass("all old tank_status($oldstat) already converted");
    }
}

/**********************
 * 5) convert SOME of the tank_status(E) to C (conflicts now different from errors)
 */
$err = Tank::$STATUS_TSRC_ERRORS;
$con = Tank::$STATUS_TSRC_CONFLICTS;
$tserr = TankSource::$STATUS_ERROR;

$tanks_with_errors = "select distinct tsrc_tank_id from tank_source where tsrc_status = '$tserr'";
$where = "tank_status = '$err' and tank_id not in ($tanks_with_errors)";
$n = $conn->exec("update tank set tank_status = '$con' where $where");

pass("updated $n tanks from error to conflict status");


/**********************
 * 6) allow NULL tact_dtim, so that form responses don't look like they all
 *    came in at the same time.
 */
$def = has_column('tank_activity', 'tact_dtim');
if (strtolower($def['Null']) == 'yes') {
    pass("tank_activity.tact_dtim allows null");
}
else {
    $conn->exec("alter table tank_activity modify tact_dtim datetime null");
    pass("modified tact_dtim - allow null");
}

$def = has_column('tank_activity', 'tact_dtim');
is(strtolower($def['Null']), 'yes', 'recheck tact_dtim - allow nulls');
