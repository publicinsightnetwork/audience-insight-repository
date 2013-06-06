#!/usr/bin/env php
<?php
require_once realpath(dirname(__FILE__).'/../app/init.php');
require_once 'AIR2_DBManager.php';

/**
 * create-tbl.php
 *
 * This utility lets you create single tables from doctrine models.
 *
 * @package default
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_connection();
$q = new Doctrine_RawSql($conn);
$q->select('*')
->from('image i')
->where("img_ref_type = 'L'")
->addComponent('i', 'ImageOrgLogo i');

$logos = $q->execute();

foreach ($logos as $logo) {

    if (!$logo->get_path_to_orig_asset()) {
        continue;
    }
    printf("org %s logo %s\n", $logo->Organization->org_name, $logo->get_path_to_orig_asset());
    
    // must copy to temp path because make_sizes() will unlink all the orig files
    $tmp_path = "/tmp/".$logo->img_file_name;
    copy($logo->get_path_to_orig_asset(), $tmp_path);
    
    $logo->set_image($tmp_path);
    $logo->make_sizes();
}
