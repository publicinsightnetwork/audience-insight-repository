#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Create user_srs table
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(5);

$n = $conn->fetchOne('select count(*) from preference_type where pt_identifier is not null;', array(), 0);

if ($n > 0) {
    pass("pt_identifier already populated");
    # And to make sure a lack of symmetry doesn't break this test:
    pass("pt_identifier already populated");
    pass("pt_identifier already populated");
    pass("pt_identifier already populated");
    pass("pt_identifier already populated");
}
else {
    $q    = "select pt_id, pt_name from preference_type where pt_status = 'A'";
    $rs   = $conn->fetchAll($q);

    $n = 0;
    $flds = "(pt_identifier)";
    foreach ($rs as $row) {
        $identifier = $row['pt_name'];
        $pt_id = $row['pt_id'];
        $identifier = strToLower($identifier);
        $identifier = str_replace(" ", "_", $identifier);
        $ins  = "update preference_type set pt_identifier = '$identifier' where pt_id=$pt_id;";
        pass($conn->exec($ins));
        $n += 1;
    }
    pass("populated $n performance_type");
}
