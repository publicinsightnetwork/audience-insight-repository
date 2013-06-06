#!/usr/bin/env php
<?php
require_once realpath(dirname(__FILE__).'/../app/init.php');
require_once 'AIR2_DBManager.php';
AIR2_DBManager::init();

/**
 * tank-def.php
 *
 * This utility will parse a bunch of doctrine models to get the doctrine
 * column definition for the 'tank' table.
 */

$tank_columns = array(
/* source */
    'src_id',
    'src_uuid',
    'src_username',
    'src_first_name',
    'src_last_name',
    'src_middle_initial',
    'src_pre_name',
    'src_post_name',
    'src_status',
    'src_channel',
/* src_alias */
    'sa_name',
    'sa_first_name',
    'sa_last_name',
    'sa_post_name',
/* src_mail_address */
    'smadd_primary_flag',
    'smadd_context',
    'smadd_line_1',
    'smadd_line_2',
    'smadd_city',
    'smadd_state',
    'smadd_cntry',
    'smadd_zip',
    'smadd_lat',
    'smadd_long',
/* src_phone_number */
    'sph_primary_flag',
    'sph_country',
    'sph_number',
    'sph_ext',
/* src_email */
    'sem_primary_flag',
    'sem_context',
    'sem_email',
    'sem_effective_date',
    'sem_expire_date',
/* src_uri */
    'suri_primary_flag',
    'suri_context',
    'suri_type',
    'suri_value',
    'suri_handle',
    'suri_feed',
/* src_org */
    'so_home_flag',
    'org_uuid',
    'org_name',
/* src_annotation */
    'srcan_type',
    'srcan_value',
/* src_credential */
    'sc_type',
    'sc_seq',
    'sc_effective_date',
    'sc_value',
    'sc_basis',
    'sc_comment',
    'sc_uri',
    'sc_public_flag',
    'sc_expire_date',
    'sc_conf_level',
/* src_fact */
    'sf_src_value',
    'sf_fact_id',
    'fact_identifier',
/* src_specialty */
    'ss_conf_level',
    'ss_value',
    'ss_basis',
    'ss_comment',
    'ss_uri',
    'ss_public_flag',
    'spec_abbrev',
/* src_activity */
    'sact_desc',
    'sact_notes',
    'actm_id',
    'actm_name',
);


/**********************
 * Helper function to find a table by column name
 */
$last_tbl_cache;
function find_table_with_column($colname) {
    // check the last table looked at
    global $last_tbl_cache;
    if ($last_tbl_cache && $last_tbl_cache->hasColumn($colname)) {
        return $last_tbl_cache;
    }

    // search all the models
    $models = Doctrine::getLoadedModelFiles();
    foreach ($models as $name => $loc) {
        if ($name != 'TankSource') {
            $t = Doctrine::getTable($name);
            if ($t->hasColumn($colname)) {
                $last_tbl_cache = $t;
                return $t;
            }
        }
    }
    throw new Exception("Unable to find table with column '$colname'");
}

/**********************
 * Helper function to string-ify a column def
 */
function create_col_def($name, $type, $length, $opts=array(), $indent=0) {
    $indent = str_pad('', $indent, ' ');

    // line 1
    $str = "$indent\$this->hasColumn('$name', '$type', ";
    $str .= is_null($length) ? 'null' : $length;
    $str .= ", array(\n";

    // line 2+
    foreach ($opts as $key => $val) {
        $str .= "$indent        '$key' => ";
        $str .= is_bool($val) ? ($val ? 'true' : 'false') : $val;
        $str .= ",\n";
    }

    // last line
    $str .= "$indent    ));\n";

    return $str;
}


/**********************
 * create column defs
 */
$indent = 8;
$coldef_str = '';
foreach ($tank_columns as $col) {
    $t = find_table_with_column($col);
    $d = $t->getColumnDefinition($col);

    // get column options
    $opts = array();
    $ignore_keys = array('primary', 'autoincrement', 'type', 'length', 'notnull', 'unique');
    foreach ($d as $key => $val) {
        if (!in_array($key, $ignore_keys)) $opts[$key] = $val;
    }

    $coldef_str .= create_col_def($col, $d['type'], $d['length'], $opts, $indent);
}

echo $coldef_str;


?>
