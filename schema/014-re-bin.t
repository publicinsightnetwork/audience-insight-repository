#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Bin (batch) redesign
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(13);


/**********************
 * 1) Create new tables
 */
$rs = $conn->fetchColumn('show tables', array(), 0);
$new_tables = array(
    'bin'                  => 'Bin',
    'bin_source'           => 'BinSource',
    'bin_src_response_set' => 'BinSrcResponseSet',
);
foreach ($new_tables as $tbl => $model) {
    if (in_array($tbl, $rs)) {
        pass("table $tbl exists");
    }
    else {
        $doc_tbl = Doctrine::getTable($model);
        try {
            $doc_tbl->export();
        }
        catch (Doctrine_Connection_Mysql_Exception $e) {
            // for some reason, mysql needs these back-ticked
            if ($tbl == 'bin_source' && preg_match("/bin_source_bsrc_bin_id_bin_bin_id/", "$e")) {
                $conn->exec("ALTER TABLE bin_source ADD CONSTRAINT bin_source_bsrc_bin_id_bin_bin_id "
                    ."FOREIGN KEY (bsrc_bin_id) REFERENCES `bin`(bin_id) ON DELETE CASCADE");
            }
            elseif ($tbl == 'bin_src_response_set' && preg_match("/bin_src_response_set_bsrs_bin_id_bin_bin_id/", "$e")) {
                $conn->exec("ALTER TABLE bin_src_response_set ADD CONSTRAINT bin_src_response_set_bsrs_bin_id_bin_bin_id "
                    ."FOREIGN KEY (bsrs_bin_id) REFERENCES `bin`(bin_id) ON DELETE CASCADE");
            }
            else {
                throw $e;
            }
        }
        pass("created table $tbl");
    }
}

// deprecated tables
$has_batch = in_array('batch', $rs);
$has_batch_item = in_array('batch_item', $rs);
$has_batch_related = in_array('batch_related', $rs);
$has_project_batch = in_array('project_batch', $rs);
function count_tbl($tbl) {
    global $conn;
    return $conn->fetchOne("select count(*) from $tbl", array(), 0);
}


/**********************
 * 2) convert batch to bin
 */
$flds = array(
    'bin_uuid'        => 'batch_uuid',
    'bin_user_id'     => 'batch_user_id',
    'bin_name'        => 'batch_name',
    'bin_desc'        => 'batch_desc',
    'bin_status'      => 'batch_status',
    'bin_shared_flag' => 'batch_shared_flag',
    'bin_cre_user'    => 'batch_cre_user',
    'bin_upd_user'    => 'batch_upd_user',
    'bin_cre_dtim'    => 'batch_cre_dtim',
    'bin_upd_dtim'    => 'batch_upd_dtim',
);
$ins_flds = implode(',', array_keys($flds));
$sel_flds = implode(',', array_values($flds));
$where = "where batch_type='S'";

if ($has_batch && count_tbl('bin') < 1000) {
    $ins = "insert into bin ($ins_flds) select $sel_flds from batch $where";
    $n = $conn->exec($ins);
    pass("converted $n batches to bins");
}
else {
    pass("batch table already converted");
}


/**********************
 * 3) convert batch_item to bin_source
 */
$batch_uuid = '(select batch_uuid from batch where batch_id=bitem_batch_id)';
$bin_id = "(select bin_id from bin where bin_uuid=$batch_uuid)";
$flds = array(
    'bsrc_bin_id' => $bin_id,
    'bsrc_src_id' => 'bitem_xid',
    'bsrc_notes'  => 'bitem_notes',
);
$ins_flds = implode(',', array_keys($flds));
$sel_flds = implode(',', array_values($flds));
$where = "where bitem_type='S'";

if ($has_batch_item && count_tbl('bin_source') < 100000) {
    $ins = "insert into bin_source ($ins_flds) select $sel_flds from batch_item $where";
    $n = $conn->exec($ins);
    pass("converted $n batch_items to bin_sources");
}
else {
    pass("batch_item table already converted");
}


/**********************
 * 3.5) prune orphans from batch tables
 */
if ($has_batch_item) {
    $n = $conn->exec("delete from batch_item where bitem_xid not in (select src_id from source)");
    pass("pruned $n orphaned batch_items");
}
else {
    pass("nothing to prune");
}
if ($has_batch_related) {
    $n = $conn->exec("delete from batch_related where brel_xid not in (select srs_id from src_response_set)");
    pass("pruned $n orphaned batch_relateds");
}
else {
    pass("nothing to prune");
}


/**********************
 * 4) convert batch_related to bin_src_response_set
 */
$batch_id = 'select bitem_batch_id from batch_item where bitem_id=brel_bitem_id';
$batch_uuid = "(select batch_uuid from batch where batch_id=($batch_id))";
$bin_id = "(select bin_id from bin where bin_uuid=$batch_uuid)";
$src_id = "(select srs_src_id from src_response_set where srs_id=brel_xid)";
$inq_id = "(select srs_inq_id from src_response_set where srs_id=brel_xid)";
$flds = array(
    'bsrs_srs_id' => 'brel_xid',
    'bsrs_bin_id' => $bin_id,
    'bsrs_src_id' => $src_id,
    'bsrs_inq_id' => $inq_id,
);
$ins_flds = implode(',', array_keys($flds));
$sel_flds = implode(',', array_values($flds));
$where = "where brel_type='S'";

if ($has_batch_related && count_tbl('bin_src_response_set') < 1000) {
    $ins = "insert into bin_src_response_set ($ins_flds) select $sel_flds from batch_related $where";
    $n = $conn->exec($ins);
    pass("converted $n batch_relateds to bin_src_response_sets");
}
else {
    pass("batch_related table already converted");
}


/**********************
 * 5) convert src_export xid's
 */
$num = $conn->fetchOne("select count(*) from src_export where se_ref_type='B'", array(), 0);
if ($num > 0) {
    $uuid = "select batch_uuid from batch where batch_id=se.se_xid";
    $bin_id = "select bin_id from bin where bin_uuid=($uuid)";
    $where = "where se_ref_type='B'";
    $upd = "update src_export se set se_ref_type='I', se_xid=($bin_id) $where";
    $n = $conn->exec($upd);
    pass("converted $n src_exports xid's from batch to bin");
}
else {
    pass("src_exports already converted");
}


/**********************
 * 6) nuke the old tables
 */
if ($has_project_batch) {
    $conn->exec('drop table project_batch');
    pass('dropped table project_batch');
}
else {
    pass('project_batch already dropped');
}
if ($has_batch_related) {
    $conn->exec('drop table batch_related');
    pass('dropped table batch_related');
}
else {
    pass('batch_related already dropped');
}
if ($has_batch_item) {
    $conn->exec('drop table batch_item');
    pass('dropped table batch_item');
}
else {
    pass('batch_item already dropped');
}
if ($has_batch) {
    $conn->exec('drop table batch');
    pass('dropped table batch');
}
else {
    pass('batch already dropped');
}
