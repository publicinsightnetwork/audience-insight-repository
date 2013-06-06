#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';


AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(1);

/**********************
 * 1) create new tables
 */
$new_tbls = array(
    'out_annotation'     => array('model' => 'OutAnnotation',    'exists' => false),
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