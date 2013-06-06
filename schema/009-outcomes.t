#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Schema changes related to outcomes.  This replaces the old "project_outcome"
 * with 4 new tables - outcome, prj_outcome, src_outcome and inq_outcome.
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(6);


/**********************
 * 1) create new tables
 */
$new_tbls = array(
    'outcome'     => array('model' => 'Outcome',    'exists' => false),
    'prj_outcome' => array('model' => 'PrjOutcome', 'exists' => false),
    'inq_outcome' => array('model' => 'InqOutcome', 'exists' => false),
    'src_outcome' => array('model' => 'SrcOutcome', 'exists' => false),
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
 * 2) convert existing project_outcome recs to outcome+prj_outcome
 */
$tbl_exists = false;
foreach ($tbls as $tname) {
    if ($tname == 'project_outcome') {
        $tbl_exists = true;
        break;
    }
}

$out_count = $conn->fetchOne('select count(*) from outcome', array(), 0);
$data_converted = $out_count > 0 ? true : false;

// test state
if (!$tbl_exists) {
    pass( 'project_outcomes presumably already converted' );
    pass( 'project_outcome already dropped' );
}
elseif ($data_converted) {
    pass( 'project_outcome not dropped, but data converted... how odd' );
    $conn->execute('drop table project_outcome');
    pass( 'project_outcome dropped' );
}
else {
    // convert data
    $rs = $conn->fetchAll('select * from project_outcome');
    foreach ($rs as $row) {
        $out = new Outcome();
        $out->out_headline = $row['prjo_headline'];
        $out->out_url = $row['prjo_link'];
        $out->out_teaser = $row['prjo_teaser'];
        $out->out_dtim = $row['prjo_dtim'];
        $out->out_cre_user = $row['prjo_cre_user'];
        $out->out_upd_user = $row['prjo_upd_user'];
        $out->out_cre_dtim = $row['prjo_cre_dtim'];
        $out->out_upd_dtim = $row['prjo_upd_dtim'];
        $out->PrjOutcome[0]->pout_prj_id = $row['prjo_prj_id'];
        $out->PrjOutcome[0]->pout_cre_user = $row['prjo_cre_user'];
        $out->PrjOutcome[0]->pout_upd_user = $row['prjo_upd_user'];
        $out->PrjOutcome[0]->pout_cre_dtim = $row['prjo_cre_dtim'];
        $out->PrjOutcome[0]->pout_upd_dtim = $row['prjo_upd_dtim'];
        $out->save();
    }
    pass( 'project_outcomes converted' );

    // drop table
    $conn->execute('drop table project_outcome');
    pass( 'project_outcome dropped' );
}
