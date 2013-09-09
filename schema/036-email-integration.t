#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Schema changes related to email integration.
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(9);


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

/**********************
 * 3) cascade constraints that i forgot
 *    - user_signature
 *    - email_inquiry
 */
$keys = array(
    array(
        'key'    => 'user_signature_usig_user_id_user_user_id',
        'table'  => 'user_signature',
        'create' => '(usig_user_id) references user(user_id) on delete cascade',
    ),
    array(
        'key'    => 'email_inquiry_einq_inq_id_inquiry_inq_id',
        'table'  => 'email_inquiry',
        'create' => '(einq_inq_id) REFERENCES inquiry(inq_id) on delete cascade',
    ),
    array(
        'key'    => 'email_inquiry_einq_email_id_email_email_id',
        'table'  => 'email_inquiry',
        'create' => '(einq_email_id) REFERENCES email(email_id) on delete cascade',
    ),
);

foreach ($keys as $def) {
    $key  = $def['key'];
    $tbl  = $def['table'];
    $stmt = $def['create'];
    $rs = array_pop(array_pop($conn->fetchAll("show create table $tbl")));
    $rs = explode("\n", $rs);
    $rs = preg_grep("/constraint.+$key/i", $rs);
    $match = count($rs) ? array_pop($rs) : false;

    if ($match && preg_match("/cascade/i", $match)) {
        pass("constraint $key okay");
    }
    else {
        if ($match) {
            $conn->execute("alter table $tbl drop foreign key $key");
        }
        $conn->execute("alter table $tbl add constraint $key foreign key $stmt");
        pass("added cascading key for $key");
    }
}

/**********************
 * 4) email schedule timestamp that I forgot
 */
$name = 'email_schedule_dtim';
$def  = 'datetime default NULL';
if (has_column('email', $name)) {
    pass("email.$name already exists");
}
else {
    $conn->execute("alter table email add column $name $def");
    pass("added email.$name");
}

/**********************
 * 5) add email_report column
 */
$name = 'email_report';
$def  = 'text default NULL';
if (has_column('email', $name)) {
    pass("email.$name already exists");
}
else {
    $conn->execute("alter table email add column $name $def");
    pass("added email.$name");
}
