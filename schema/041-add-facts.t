#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Add decline_to_state to gender in fact_value table
 *
 * @package default
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(1);

$education_fact_1 = 'Other professional certification';

$result = $conn->fetchOne('select count(*) from fact_value where fv_fact_id = 3 AND fv_value="$education_fact_1"', array(), 0);

if ($result > 0) {
    pass("$education_fact_1 already added to education");
}
else {
    $flds = '(fv_fact_id, fv_seq, fv_value, fv_status)';
    $ins  = "insert ignore into fact_value $flds values (3, 20, '$education_fact_1', 'A')";

    $n = 0;
    $n += $conn->exec($ins);

    pass("added $n fact_values");
}
