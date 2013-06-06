#!/usr/bin/env php
<?php
require_once dirname(__FILE__) . '/../tests/Test.php';
require_once dirname(__FILE__) . '/../app/init.php';

/**
 * User profile-ish changes for #9575 #9577 #9578
 *
 *
 * user columns:
 *   -summary
 *   -description
 *   -publishable_flag (STATUS)
 *   -*virtual* MyPIN profile url
 *
 *
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

plan(14);


/**********************
 * 1) Fix user_uri table
 *
 * We're now using "uuri_type" to store facebook/linkedin/twitter/etc.
 * Convert the existing and temporarily move user photos (type=P) to a
 * type=? until the image asset pipeline is in place.
 */
$map_them = array(
    'Facebook'      => UserUri::$TYPE_FACEBOOK,
    'LinkedIn'      => UserUri::$TYPE_LINKEDIN,
    'Twitter'       => UserUri::$TYPE_TWITTER,
    'Publish2'      => UserUri::$TYPE_OTHER,
    'Personal Site' => UserUri::$TYPE_PERSONAL,
    'Work Site'     => UserUri::$TYPE_WORK,
);

function has_column($tbl, $name) {
    global $conn; $rs = $conn->fetchAll("describe $tbl");
    foreach ($rs as $flddef) { if ($flddef['Field'] == $name) return $flddef; }
    return false;
}

$def = has_column('user_uri', 'uuri_handle');
if ($def['Null'] == 'NO') {
    $conn->execute("alter table user_uri modify uuri_handle varchar(128) null");
    pass("made uuri_handle NULL-able");
}
else {
    pass("uuri_handle already NULL-able");
}

foreach ($map_them as $handle => $type) {
    $set = "set uuri_type='$type', uuri_handle=NULL";
    $whr = "where uuri_type='N' and uuri_handle='$handle'";
    $n   = $conn->exec("update user_uri $set $whr");
    pass("updated $n $handle user_uri");
}

$n = $conn->exec("delete from user_uri where uuri_type='P' and uuri_value=''");
pass("cleaned up $n blank user photos");

$n = $conn->exec("update user_uri set uuri_type='?' where uuri_type='P'");
pass("changed $n user photos to type=? (temporarily)");


/**********************
 * 2) Add user columns
 */
$add_columns = array(
    'user_summary'  => 'varchar(255) null',
    'user_desc'     => 'text null',
);

foreach ($add_columns as $name => $def) {
    if (has_column('user', $name)) {
        pass("user.$name already exists");
    }
    else {
        $conn->execute("alter table user add column $name $def");
        pass("added user.$name");
    }
}


/**********************
 * 2.5) Add user_email_address column
 */
if (has_column('user_email_address', 'uem_signature')) {
    pass("user_email_address.uem_signature already exists");
}
else {
    $conn->execute("alter table user_email_address add column uem_signature text null");
    pass("added user_email_address.uem_signature");
}


/**********************
 * 3) User Avatar image
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
 * 4) Convert existing avatar images
 */
$rs = $conn->fetchAll("select * from user_uri where uuri_type='?'");
if (count($rs)) {
    $success = 0;
    $bad_url = 0;
    $failed = 0;

    $base = '/tmp/air_schema_017';
    air2_mkdir($base);

    foreach ($rs as $uuri) {
        $id  = $uuri['uuri_id'];
        $url = $uuri['uuri_value'];
        $uid = $uuri['uuri_user_id'];

        // download file
        exec("(cd $base && wget $url) &> /dev/null", $out, $ret);
        $path = $base.'/'.basename($url);

        // convert to Image
        if ($ret != 0) {
            diag("nuking bad url on user_id($uid) - $url");
            $conn->exec("delete from user_uri where uuri_id=$id");
            $bad_url++;
        }
        else {
            $u = Doctrine::getTable('User')->find($uid);
            try {
                if (!$u->Avatar || !$u->Avatar->exists()) {
                    $u->Avatar = new ImageUserAvatar();
                }
                $u->Avatar->set_image($path);
                $u->Avatar->save();
                $conn->exec("delete from user_uri where uuri_id=$id");
                $success++;
            }
            catch (Exception $e) {
                diag("error creating avatar - ".$e->getMessage());
                $failed++;
            }
        }
    }

    air2_rmdir($base);
    pass("converted $success user_uri's to images (failed on $failed, bad urls on $bad_url)");
}
else {
    pass("all images already converted");
}
