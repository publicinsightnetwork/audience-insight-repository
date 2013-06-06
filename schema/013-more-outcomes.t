#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * More outcome schema changes!
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

plan(30);


/**********************
 * 1) add columns
 */
$add_these = array(
    array('outcome', 'out_internal_headline', 'varchar(255) null'),
    array('outcome', 'out_internal_teaser',   'text null'),
    array('outcome', 'out_show',              'varchar(255) null'),
    array('outcome', 'out_survey',            'text null'),
    array('outcome', 'out_org_id',            'int(11) not null'),
    array('src_outcome', 'sout_type',  'char(1) not null default "I"'),
    array('src_outcome', 'sout_notes', 'text null'),
    array('prj_outcome', 'pout_type',  'char(1) not null default "I"'),
    array('prj_outcome', 'pout_notes', 'text null'),
    array('inq_outcome', 'iout_type',  'char(1) not null default "I"'),
    array('inq_outcome', 'iout_notes', 'text null'),
);

foreach ($add_these as $row) {
    $tbl = $row[0];
    $col = $row[1];
    $def = $row[2];
    if (!has_column($tbl, $col)) {
        $conn->execute("alter table $tbl add column $col $def");
        if ($col == 'out_org_id') {
            $conn->execute("update outcome set out_org_id=1"); //sane default
        }
        pass("added $tbl.$col");
    }
    else {
        pass("$tbl.$col already exists");
    }
    ok( has_column($tbl, $col), "has $tbl.$col" );
}

/**********************
 * 2) make outcome headline/teaser/dtim NOT NULL
 */
$headline_notnull = null;
$teaser_notnull = null;
$dtim_notnull = null;
$rs = $conn->fetchAll('describe outcome');
foreach ($rs as $flddef) {
    if ($flddef['Field'] == 'out_headline') $headline_notnull = ($flddef['Null'] == 'NO');
    if ($flddef['Field'] == 'out_teaser') $teaser_notnull = ($flddef['Null'] == 'NO');
    if ($flddef['Field'] == 'out_dtim') $dtim_notnull = ($flddef['Null'] == 'NO');
}

if (!$headline_notnull) {
    $conn->execute("alter table outcome modify out_headline varchar(255) not null");
    pass("made out_headline NOT NULL");
}
else {
    pass("out_healine already NOT NULL");
}
if (!$teaser_notnull) {
    $conn->execute("alter table outcome modify out_teaser text not null");
    pass("made out_teaser NOT NULL");
}
else {
    pass("out_teaser already NOT NULL");
}
if (!$dtim_notnull) {
    $conn->execute("alter table outcome modify out_dtim text not null");
    pass("made out_dtim NOT NULL");
}
else {
    pass("out_dtim already NOT NULL");
}

// double check
$headline_notnull = null;
$teaser_notnull = null;
$dtim_notnull = null;
$rs = $conn->fetchAll('describe outcome');
foreach ($rs as $flddef) {
    if ($flddef['Field'] == 'out_headline') $headline_notnull = ($flddef['Null'] == 'NO');
    if ($flddef['Field'] == 'out_teaser') $teaser_notnull = ($flddef['Null'] == 'NO');
    if ($flddef['Field'] == 'out_dtim') $dtim_notnull = ($flddef['Null'] == 'NO');
}
ok($headline_notnull, "out_headline NOT NULL");
ok($teaser_notnull, "out_teaser NOT NULL");
ok($dtim_notnull, "out_dtim NOT NULL");


/**********************
 * 3) Update any deprecated outcome.out_types
 */
$conn->execute("update outcome set out_type='S' where out_type='P'");
pass("changed deprecated out_type(P) to S");


/**********************
 * 4) cascade constraint on out_org_id
 */
$key = 'outcome_out_org_id_organization_org_id';
$rs = array_pop(array_pop($conn->fetchAll("show create table outcome")));
$rs = explode("\n", $rs);
$rs = preg_grep("/constraint.+$key/i", $rs);
$match = count($rs) ? array_pop($rs) : false;

if ($match && preg_match("/cascade/i", $match)) {
    pass("constraint $key okay");
}
elseif ($match) {
    $conn->execute("alter table outcome drop foreign key $key");
    $conn->execute("alter table outcome add constraint $key foreign key " .
        "(out_org_id) references organization(org_id) on delete cascade");
    pass("added cascading key for $key");
}
else {
    $conn->execute("alter table outcome add constraint $key foreign key " .
        "(out_org_id) references organization(org_id) on delete cascade");
    pass("added out_org_id constraint");
}

