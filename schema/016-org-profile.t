#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * Org profile-ish changes for #9576 #9577 #9578
 *
 * @package default
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(12);


/**********************
 * 1) Create org_uri table
 */
$rs = $conn->fetchColumn('show tables', array(), 0);
if (in_array('org_uri', $rs)) {
    pass('table org_uri exists');
}
else {
    $doc_tbl = Doctrine::getTable('OrgUri');
    $doc_tbl->export();
    pass('created table org_uri');
}


/**********************
 * 2) Add org columns
 */
$add_columns = array(
    'org_summary'  => 'varchar(255) null',
    'org_desc'     => 'text null',
    'org_welcome_msg' => 'text null',
    'org_city'     => 'varchar(128) null',
    'org_state'    => 'char(2) null',
    'org_site_uri' => 'varchar(255) null',
    'org_address'  => 'varchar(255) null',
    'org_zip'      => 'varchar(32) null',
    'org_email'    => 'varchar(255) null',
);


/**
 *
 *
 * @param unknown $tbl
 * @param unknown $name
 * @return unknown
 */
function has_column($tbl, $name) {
    global $conn; $rs = $conn->fetchAll("describe $tbl");
    foreach ($rs as $flddef) { if ($flddef['Field'] == $name) return $flddef; }
    return false;
}


foreach ($add_columns as $name => $def) {
    if (has_column('organization', $name)) {
        pass("organization.$name already exists");
    }
    else {
        $conn->execute("alter table organization add column $name $def");
        pass("added organization.$name");
    }
}


/**********************
 * 3) Verify image exists
 */
$rs = $conn->fetchColumn('show tables', array(), 0);
if (in_array('image', $rs)) {
    pass("table image exists");
}
else {
    $doc_tbl = Doctrine::getTable('Image');
    $doc_tbl->export();
    pass("created table image");
}


/**********************
 * 4) Convert existing logo images
 */
$rs = $conn->fetchAll("select * from organization where org_logo_uri is not null");
if (count($rs)) {
    $success = 0;
    $bad_url = 0;
    $failed = 0;

    $base = '/tmp/air_schema_016';
    air2_mkdir($base);

    foreach ($rs as $org) {
        $id  = $org['org_id'];
        $url = $org['org_logo_uri'];

        // download file
        exec("(cd $base && wget $url) &> /dev/null", $out, $ret);
        $path = $base.'/'.basename($url);

        // convert to Image
        if ($ret != 0) {
            diag("nuking bad url on org_id($id) - $url");
            $conn->exec("update organization set org_logo_uri=null where org_id=$id");
            $bad_url++;
        }
        else {
            $o = Doctrine::getTable('Organization')->find($id);
            try {
                if (!$o->Logo || !$o->Logo->exists()) {
                    $o->Logo = new ImageOrgLogo();
                }
                $o->Logo->set_image($path);
                $o->Logo->save();
                $conn->exec("update organization set org_logo_uri=null where org_id=$id");
                $success++;
            }
            catch (Exception $e) {
                diag("error creating logo - ".$e->getMessage());
                $failed++;
            }
        }
    }

    air2_rmdir($base);
    pass("converted $success org_logo_uris to images (failed on $failed, bad urls on $bad_url)");
}
else {
    pass("all images already converted");
}
