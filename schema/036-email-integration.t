#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Schema changes related to email integration.
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(4);


/**********************
 * 1) create new tables
 */
$new_tbls = array(
    'user_signature' => array('model' => 'UserSignature', 'exists' => false),
    'email'          => array('model' => 'Email',         'exists' => false),
    'email_inquiry'  => array('model' => 'EmailInquiry',  'exists' => false),
);

$tbls = $conn->fetchColumn('show tables', array(), 0);
foreach ($tbls as $tname) {
    if (isset($new_tbls[$tname])) {
        $new_tbls[$tname]['exists'] = true;
    }
}

// export models to database
foreach ($new_tbls as $name => $def) {
    if ($def['exists']) {
        pass( "$name exists" );
    }
    else {
        $doc_tbl = Doctrine::getTable($def['model']);
        $doc_tbl->export();
        pass( "$name created" );
    }
}


/**********************
 * 2) alter src_export tabl
 */
$add_columns = array(
    'se_email_id'  => "integer null",
);

function has_column($tbl, $name) {
    global $conn; $rs = $conn->fetchAll("describe $tbl");
    foreach ($rs as $flddef) { if ($flddef['Field'] == $name) return $flddef; }
    return false;
}

foreach ($add_columns as $name => $def) {
    if (has_column('src_export', $name)) {
        pass("src_export.$name already exists");
    }
    else {
        $conn->execute("alter table src_export add column $name $def");
        pass("added src_export.$name");
    }
}
