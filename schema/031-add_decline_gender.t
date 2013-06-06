#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Add decline_to_state to gender in fact_value table
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(1);

$result = $conn->fetchOne('select count(*) from fact_value where fv_fact_id = 1 AND fv_value="Decline to state"', array(), 0);

if ($result > 0) {
	pass("Decline to state already added to gender");
}
else {
	$flds = '(fv_fact_id, fv_seq, fv_value, fv_status)';
	$ins  = "insert ignore into fact_value $flds values (1, 10, 'Decline to state', 'A')";

	$n = 0;
	$n += $conn->exec($ins);

	pass("added $n fact_values");
}