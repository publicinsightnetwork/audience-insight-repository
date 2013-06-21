<?php
/**************************************************************************
 *
 *   Copyright 2010 American Public Media Group
 *
 *   This file is part of AIR2.
 *
 *   AIR2 is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   AIR2 is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
 *
 *************************************************************************/

require_once 'Encoding.php';

/*****************************************************
 * AIR 2.x
 *
 * AIR2 Utility functions. These are in global scope.
 *
 */


/**
 * Default length is 12.
 *
 * @param int     $len (optional)
 * @return string $uuid
 */
function air2_generate_uuid($len=12) {
    $max = mt_getrandmax();
    // generate 32 chars at a time, since most of the time we just need 12
    $t_val = sprintf('%04x%04x%04x%04x%04x%04x%04x%04x',
        mt_rand( 0, $max ),
        mt_rand( 0, $max ),
        mt_rand( 0, $max ),
        mt_rand( 0, $max ),
        mt_rand( 0, $max ),
        mt_rand( 0, $max ),
        mt_rand( 0, $max ),
        mt_rand( 0, $max )
    );
    while (strlen($t_val) < $len) {
        $t_val .= air2_generate_uuid();  // add 12 more chars
    }
    return substr( $t_val, 0, $len );
}


/**
 * Create a "constant" uuid string from any string
 *
 * @param string  $str
 * @param int     $len (optional)
 * @return string
 */
function air2_str_to_uuid($str, $len=12) {
    $uuid = substr(md5($str), 0, $len);
    return $uuid;
}


/**
 *
 *
 * @param int     $time (optional)
 * @return string date
 */
function air2_date($time=null) {
    return date(AIR2_DTIM_FORMAT, $time == null ? time() : $time);
}


/**
 * Validate an email address.
 * Provide email address (raw input)
 * Returns true if the email address has the email
 * address format and the domain exists.
 *
 * from http://www.linuxjournal.com/article/9585?page=0,3
 *
 * @param unknown $email
 * @return unknown
 */
function air2_valid_email($email) {
    $isValid = true;
    $atIndex = strrpos($email, "@");
    if (is_bool($atIndex) && !$atIndex) {
        $isValid = false;
    }
    else {
        $domain = substr($email, $atIndex+1);
        $local = substr($email, 0, $atIndex);
        $localLen = strlen($local);
        $domainLen = strlen($domain);
        if ($localLen < 1 || $localLen > 64) {
            // local part length exceeded
            $isValid = false;
        }
        elseif ($domainLen < 1 || $domainLen > 255) {
            // domain part length exceeded
            $isValid = false;
        }
        elseif ($local[0] == '.' || $local[$localLen-1] == '.') {
            // local part starts or ends with '.'
            $isValid = false;
        }
        elseif (preg_match('/\\.\\./', $local)) {
            // local part has two consecutive dots
            $isValid = false;
        }
        elseif (!preg_match('/^[A-Za-z0-9\\-\\.]+$/', $domain)) {
            // character not valid in domain part
            $isValid = false;
        }
        elseif (preg_match('/\\.\\./', $domain)) {
            // domain part has two consecutive dots
            $isValid = false;
        }
        elseif
        (!preg_match('/^(\\\\.|[A-Za-z0-9!#%&`_=\\/$\'*+?^{}|~.-])+$/',
                str_replace("\\\\", "", $local))) {
            // character not valid in local part unless
            // local part is quoted
            if (!preg_match('/^"(\\\\"|[^"])+"$/',
                    str_replace("\\\\", "", $local))) {
                $isValid = false;
            }
        }

        // skip the DNS check
        /*
        if ($isValid && !(checkdnsrr($domain, "MX") ||
                u21aacheckdnsrr($domain, "A"))) {
            // domain not found in DNS
            $isValid = false;
        }
        */
    }
    return $isValid;
}


/**
 * Returns true if $url looks valid.
 *
 * @param string  $url
 * @return boolean
 */
function air2_valid_url($url) {
    // the internets are full of conflicting advice on how best to do this,
    // but the concensus seems to be that the built-in PHP functions (filter_var, parse_url)
    // are *not* safe.
    // this taken from http://www.devshed.com/c/a/PHP/PHP-URL-Validation-Functions/
    $regex = "((https?|ftp)://)?";
    $regex .= "([a-z0-9+!*(),;?&=$_.-]+(:[a-z0-9+!*(),;?&=$_.-]+)?@)?";
    $regex .= "([a-z0-9-.]*).([a-z]{2,3})";
    $regex .= "(:[0-9]{2,5})?";
    $regex .= "(/([a-z0-9+$_-].?)+)*/?";
    $regex .= "(?[a-z+&$_.-][a-z0-9;:@&%=+/$_.-]*)?";
    $regex .= "(#[a-z_.-][a-z0-9+$_.-]*)?";
    if (preg_match("/^$regex$/", $url)) {
        return true;
    }
    return false;
}


/**
 *
 *
 * @param unknown $model
 */
function air2_model_prevalidate(&$model) {
    $table = $model->getTable();
    $col_defs = $table->getColumns();
    $now = air2_date();
    foreach ($col_defs as $col => $def) {
        if (preg_match('/_uuid$/', $col) && isset($def['unique']) && $def['unique']) {
            if (!isset($model->$col) || !strlen($model->$col)) {
                $model->$col = air2_generate_uuid(12);
            }
        }
        elseif (preg_match('/_cre_dtim$/', $col)) {
            if (!$model->exists() && !strlen($model->$col)) {
                $model->$col = $now;
            }
        }
        elseif (preg_match('/_upd_dtim$/', $col)) {
            $model->$col = $now;
        }
        elseif (preg_match('/_cre_user$/', $col)) {
            if (!$model->exists() && !strlen($model->$col)) {
                if ( defined('AIR2_REMOTE_USER_ID') ) {
                    $model->$col = AIR2_REMOTE_USER_ID;
                }
                else {
                    $model->$col = 1; //sysuser -- TODO: check for shell users
                }
            }
        }
        elseif (preg_match('/_upd_user$/', $col)) {
            if ( defined('AIR2_REMOTE_USER_ID') ) {
                $model->$col = AIR2_REMOTE_USER_ID;
            }
            else {
                $model->$col = 1; //sysuser -- TODO: check for shell users
            }
        }
        elseif ($def['type'] === 'timestamp') {
            // validate the string for non cre/upd timestamps
            if (isset($model->$col) && !is_null($model->$col)) {
                //NOTE: whenever you set a column in Doctrine, it checks that
                //the value has changed.  Since '2010-01-01 01:01:01' is equal
                //to '2010-01-01T01:01:01', we need to NULL it first
                if (strpos($model->$col, 'T') !== false) {
                    $airformat = air2_date(strtotime($model->$col));
                    $model->$col = null;
                    $model->$col = $airformat;
                }
            }
        }
        elseif ($def['type'] === 'date') {
            // validate the string for non cre/upd timestamps
            if (isset($model->$col) && !is_null($model->$col)) {
                //NOTE: whenever you set a column in Doctrine, it checks that
                //the value has changed.  Since '2010-01-01 01:01:01' is equal
                //to '2010-01-01T01:01:01', we need to NULL it first
                if (strpos($model->$col, 'T') !== false) {
                    $airformat = air2_date(strtotime($model->$col));
                    $model->$col = null;
                    $model->$col = $airformat;
                }
            }
        }

        // default values
        if (strlen($table->getDefaultValueOf($col)) && !strlen($model->$col)) {
            $model->$col = $table->getDefaultValueOf($col);
        }

        // lastly, check strings for valid UTF8 chars
        if ($def['type'] === 'string' && !Encoding::is_utf8($model->$col)) {
            $modelname = get_class($model);
            throw new Doctrine_Exception("non-UTF8 string found in $modelname->$col: ".$model->$col);
        }
    }

}


/**
 *
 *
 * @param unknown $colname
 * @param unknown $doctrine_def (optional)
 * @param unknown $mapping      (optional)
 * @return unknown
 */
function air2_column_def($colname, $doctrine_def=null, $mapping=null) {
    $coldef = array('name' => $colname);

    if ($doctrine_def) {
        if ($doctrine_def['type'] === 'timestamp') {
            $coldef['type'] = 'date';
            $coldef['dateFormat'] = AIR2_DTIM_FORMAT;
        }
        elseif ($doctrine_def['type'] === 'date') {
            $coldef['type'] = 'date';
            $coldef['dateFormat'] = AIR2_DATE_FORMAT;
        }
        elseif ($doctrine_def['type'] === 'float') {
            $coldef['type'] = 'float';
        }
        elseif ($doctrine_def['type'] === 'integer') {
            $coldef['type'] = 'int';
        }
        elseif ($doctrine_def['type'] === 'string') {
            $coldef['type'] = 'string';
            $coldef['length'] = $doctrine_def['length'];
        }
        elseif ($doctrine_def['type'] === 'boolean') {
            $coldef['type'] = 'boolean';
        }
    }
    else {
        $coldef['type'] = 'array';
    }

    if ($mapping) {
        $coldef['name'] = str_replace('.', ':', $mapping).':'.$colname;
        $coldef['mapping'] = "$mapping.$colname";
    }

    return $coldef;
}


/**
 *
 *
 * @param unknown $array
 * @return unknown
 */
function air2_is_assoc_array($array) {
    if (!is_array($array) || empty($array))
        return false;

    $keys = array_keys($array);
    return array_keys($keys) !== $keys;
}


/**
 * Unset array of data based on AIR2 column name conventions
 *
 * @param associative-array $radix
 * @param array   $whitelist
 */
function air2_clean_radix(&$radix, $whitelist=array()) {
    foreach ($radix as $key => &$val) {
        if (is_array($val)) {
            // recursively clean subobjects
            air2_clean_radix($val, $whitelist);
        }
        else {
            // skip whitelist
            if (in_array($key, $whitelist)) continue;

            // unset cre/upd user id's, passwords, and PK/FK id's
            if ( preg_match('/_cre_user$/', $key) ||
                preg_match('/_upd_user$/', $key) ||
                preg_match('/_password$/', $key) ||
                preg_match('/_id$/', $key) ) {
                unset($radix[$key]);
            }
        }
    }
}


/**
 * Unset array metadata based on AIR2 column name conventions
 *
 * @param indexed-array $fields
 * @param boolean $keep_id (optional) keep the primary key in metadata
 */
function air2_clean_fields(&$fields, $keep_id=false) {
    $len = count($fields);
    for ($i=0; $i<$len; $i++) {
        $name = $fields[$i]['name'];

        if ( !($keep_id && strstr($name, '_') == '_id') ) {
            // unset cre/upd user id's, passwords, and PK/FK id's
            if ( preg_match('/_cre_user$/', $name) ||
                preg_match('/_upd_user$/', $name) ||
                preg_match('/_password$/', $name) ||
                preg_match('/_id$/', $name) ) {
                unset($fields[$i]);
            }
        }
    }
    $fields = array_values($fields);
}



/**
 *
 *
 * @param unknown $model_name
 * @return unknown
 */
function air2_get_model_uuid_col($model_name) {
    $table = Doctrine::getTable($model_name);
    $rec = $table->getRecordInstance();

    // check for a custom uuid query for this model
    if ( method_exists($rec, 'get_uuid_col') ) {
        return $rec->get_uuid_col();
    }

    // look for a column ending in uuid
    $cols = $table->getColumnNames();
    foreach ($cols as $colname) {
        if (preg_match('/^[a-z]+_uuid$/', $colname)) {
            return $colname;
        }
    }

    // UUID not found --- try the PK
    $ids = $table->getIdentifierColumnNames();
    if (count($ids) != 1) {
        return false;
        //echo "Unable to find UUID/ID Column for model $model_name<br/>\n";
        //echo "Try setting a 'get_uuid_col' method in your controller<br/>\n";
        //exit(0);// TODO: exception!
    }
    return $ids[0];
}


/**
 *
 *
 * @param unknown $q      (reference)
 * @param unknown $tbl
 * @param unknown $alias
 * @param unknown $search
 * @param unknown $useOr
 */
function air2_add_query_search(&$q, $tbl, $alias, $search, $useOr=null) {
    if (method_exists($tbl, 'add_search_str')) {
        call_user_func(array($tbl, 'add_search_str'), $q, $alias, $search, $useOr);
    }
}


/**
 * Turn an array into a comma separated string of values.  The array can either
 * be a list of items, or a list of arrays containing a 'id' and 'type'.  In
 * the latter case, you can optionally specify a filter to apply against the
 * list.
 *
 * @param array   $arr    (reference) an array of items to stringify
 * @param string  $filter (optional) the value to filter with (defaults to no filtering)
 * @param string  $fcol   (optional) the name of the column to filter (defaults to 'type')
 * @param string  $idcol  (optional) the name of the id column (defaults to 'uuid')
 * @return string comma separated values
 */
function air2_array_to_string(&$arr, $filter=null, $fcol='type', $idcol='uuid') {
    $str = "";
    foreach ($arr as $item) {
        if (is_array($item)) {
            if (!$filter || $item[$fcol] == $filter) {
                if (strlen($str) > 0) $str .= ",";
                $str .= "'".$item[$idcol]."'";
            }
        }
        else {
            //no filter applied
            if (strlen($str) > 0) $str .= ",";
            $str .= "'".$item."'";
        }
    }
    return $str;
}


/**
 * Search a document (string) for an inline javascript variable.  This assumes
 * that javascript variables are 1-per-line.  Returns the json_decode'd variable
 * if it is found, otherwise returns -1.  (WARNING: this '-1' flag is used
 * because often globals have the values 'null', 'false', and '0'.  If you have
 * a js variable with the value '-1', this function will return ambiguous
 * results)
 *
 * @param string  $var_name
 * @param string  $document
 * @return mixed
 */
function air2_get_json_variable($var_name, $document) {
    //get the line with the variable on it
    $found = preg_match("/".$var_name."[\s]*= .+/", $document, $line);
    if (!$found) return -1;

    // remove the variable name and any ending ";"
    $str = preg_replace("/^[\s]*".$var_name."[\s]*=[\s]*/", '', $line[0]);
    $str = preg_replace("/;$/", '', $str);

    // removing starting/ending quotes
    $str = preg_replace("/^[\'\"]|[\'\"]$/", '', $str);

    // special case ... if java "null", return string 'JSNULL' (is this useful?)
    if (strtolower($str) == 'null') {
        return 'JSNULL';
    }

    $json = json_decode($str, true);
    return is_null($json) ? $str : $json;
}


/**
 * Sort a mixed array of associative arrays.  $flds must be an array of strings
 * describing the sort field names found in $unsorted.  Each item in $unsorted
 * should contain only one of the $flds keys.
 *
 * @param array   $unsorted
 * @param array   $flds
 * @param int     $order    (optional) SORT_ASC|SORT_DESC
 * @return array the sorted items
 */
function air2_complex_sort($unsorted, $flds, $order=SORT_ASC) {
    if (count($unsorted) < 1 || count($flds) < 1) return $unsorted;
    $sorted = array();
    $desc = ($order == SORT_DESC);


    /**
     * Helper function to get value from array
     *
     * @param assoc-array $item
     * @param array   $flds
     * @return mixed
     */
    function get_sort_val($item, $flds) {
        foreach ($flds as $f) {
            if (isset($item[$f])) return $item[$f];
        }
        return null; //not found!
    }


    // insert each unsorted into sorted
    foreach ($unsorted as $item) {
        $mine = get_sort_val($item, $flds);

        $done = false;
        $total = count($sorted);
        for ($i=0; $i<$total && !$done; $i++) {
            $yours = get_sort_val($sorted[$i], $flds);
            if (!$desc && $mine < $yours) {
                array_splice($sorted, $i, 0, array($item));
                $done = true;
            }
            elseif ($desc && $mine >= $yours) {
                array_splice($sorted, $i, 0, array($item));
                $done = true;
            }
        }

        if (!$done) $sorted[] = $item; // just push it!

    }
    return $sorted;
}


/**
 * Test to see if an image url is valid, and redirect to it.  If invalid, either
 * redirect to a default image url or show a 404.
 *
 * @param string|null $try_url
 * @param string  $default_url (optional)
 */
function air2_proxy_image($try_url, $default_url=null) {
    // check for a valid url to try
    if (is_string($try_url) && strlen($try_url) > 0) {
        // set up the curl session
        $s = curl_init($try_url);
        curl_setopt($s, CURLOPT_HEADER, true);
        curl_setopt($s, CURLOPT_NOBODY, true);
        curl_setopt($s, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($s, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($s, CURLOPT_SSL_VERIFYHOST, false);
        $res = curl_exec($s);

        // check headers for valid image, and redirect to it
        if (curl_getinfo($s, CURLINFO_HTTP_CODE) == 200) {
            $t = curl_getinfo($s, CURLINFO_CONTENT_TYPE);
            if (strpos($t, 'image') !== false) {
                redirect($try_url);
                exit(0);
            }
        }
    }

    // if we got here, show default url or a 404
    if ($default_url) {
        redirect($default_url);
    }
    else {
        show_404();
    }
}


/**
 * Make a directory with group-writable permissions
 *
 * @param string  $path
 * @return boolean success
 */
function air2_mkdir($path) {
    if (file_exists($path)) return true;

    $old_umask = umask(0002); //group writeable
    if (!mkdir($path, 0770, true)) {
        throw new Exception("Failed to mkdir $path");
    }
    umask($old_umask); //restore
    return true;
}


/**
 * Recursively remove a directory
 *
 * @param string  $dir
 */
function air2_rmdir($dir) {
    if (is_dir($dir)) {
        $scan = glob("$dir/*");
        foreach ($scan as $path) {
            if (is_file($path)) {
                unlink($path);
            }
            else {
                air2_rmdir($path);
            }
        }
        rmdir($dir);
    }
}


/**
 * Recursively scan filesystem for files
 *
 * @param string  $dir_path
 * @param string  $regex    (optional) to filter filenames with
 * @param string  $prepend  (optional)
 * @return array file names
 */
function air2_dirscan($dir_path, $regex='//', $prepend='') {
    if (!is_dir($dir_path)) return false;

    $files = array();
    $dirs = array();
    $scan = scandir($dir_path);

    // add files at this level first
    foreach ($scan as $file) {
        // remove hidden/meta directories
        if (!preg_match('/^\./', $file)) {
            $full = $prepend.$file;
            if (is_dir("$dir_path/$file")) {
                $dirs[$full] = "$dir_path/$file";
            }
            else {
                if (preg_match($regex, $file)) $files[] = $full;
            }
        }
    }

    // now process subdirectories
    foreach ($dirs as $name => $path) {
        $files = array_merge($files, air2_dirscan($path, $regex, $name.'/'));
    }

    return $files;
}


/**
 * Removes an item (or an array of items) from an array.
 *
 * @param mixed   $needle
 * @param array   &$haystack
 * @return array the haystack array
 */
function air2_array_remove($needle, &$haystack) {
    if (is_array($needle)) {
        foreach ($needle as $val) {
            air2_array_remove($val, $haystack);
        }
    }
    else {
        $idx = array_search($needle, $haystack);
        if ($idx !== false) {
            array_splice($haystack, $idx, 1);
        }
    }
    return $haystack;
}


/**
 * Fixes the html include-order of javascript files in AIR2
 *
 * @param array   $orig
 * @return array the sorted array
 */
function air2_fix_js_order($orig) {
    $order = array(
        '/^air2\.js/',
        '/^util\//',
        '/^ui\/panel.js/',
        '/^ui\/dataview.js/',
        '/^ui\/window.js/',
        '/^ui\//',
        '/^inquiry\/builder\/inlineedit.js/',
        '/^inquiry\/builder\/mintext/',
        '//'
    );
    $sorted = array();
    foreach ($order as $re) {
        foreach ($orig as $idx => $name) {
            if (preg_match($re, $name)) {
                $sorted[] = $name;
                unset($orig[$idx]);
            }
        }
    }
    return $sorted;
}


/**
 * Makes a string url-friendly
 *
 * @param string  $str
 * @return string
 */
function air2_urlify($str) {
    // tricky - convert all CamelCase to camel-case
    $str = preg_replace('/([A-Z][a-z])/', '-$1', $str);
    $str = strtolower($str);
    $str = preg_replace("/['\",.!?;:]/", "", $str);
    $str = preg_replace("/<.+?>|&[\S];/", "", $str);
    $str = preg_replace('/\W+/', '-', $str);
    $str = preg_replace('/^-+|-+$/', '', $str);
    $str = preg_replace('/--*/', '-', $str);
    return $str;
}


/**
 * Makes a string file-friendly
 *
 * @param string  $str
 * @return string
 */
function air2_fileify($str) {
    $str = air2_str_clean($str);
    $str = preg_replace(array('/\s/', '/\.[\.]+/', '/[^\w_\.\-]/'), array('_', '.', ''), $str);
    return $str;
}


/**
 * Get a bunch of question marks as a string.
 *
 * @param int|array $num
 * @return string
 */
function air2_sql_param_string($num) {
    if (is_array($num)) {
        $num = count($num);
    }
    $arr = array_fill(0, $num, '?');
    return implode(',', $arr);
}


/**
 * Fix a primary column on a table, making sure that each source only has
 * one primary set.
 *
 * @param AIR2_Record $rec
 * @param boolean $delete
 */
function air2_fix_src_primary($rec, $delete=false) {
    $conn = AIR2_DBManager::get_master_connection();
    $tbl = $rec->getTable()->getTableName();

    // find column names
    $idcol = false;
    $fkcol = false;
    $flagcol = false;
    $updcol = false;
    $cols = $rec->getTable()->getColumnNames();
    foreach ($cols as $col) {
        if (preg_match('/^[a-z]+_id$/', $col)) {
            $idcol = $col;
        }
        elseif (preg_match('/^[a-z]+_src_id$/', $col)) {
            $fkcol = $col;
        }
        elseif (preg_match('/_primary_flag$/', $col) || preg_match('/_home_flag$/', $col)) {
            $flagcol = $col;
        }
        elseif (preg_match('/_upd_dtim$/', $col)) {
            $updcol = $col;
        }
    }

    // sanity!
    if (!$idcol || !$fkcol || !$flagcol || !$updcol) {
        throw new Exception("Missing a column");
    }

    // saved? or deleted?
    if (!$delete) {
        if ($rec[$flagcol]) {
            // unset everyone else
            $q = "update $tbl set $flagcol=0 where $fkcol=? and $idcol!=?";
            $conn->exec($q, array($rec[$fkcol], $rec[$idcol]));
        }
        else {
            // check for existing primary
            $q = "select $idcol, $flagcol from $tbl where $fkcol = ?";
            $rs = $conn->fetchAll($q, array($rec[$fkcol]));
            $has_primary = false;
            foreach ($rs as $row) {
                if ($row[$flagcol]) $has_primary = true;
            }

            // should I or someone else be primary?
            if (!$has_primary && count($rs) == 1) {
                // it's me!
                $q = "update $tbl set $flagcol=1 where $fkcol=? and $idcol=?";
                $conn->exec($q, array($rec[$fkcol], $rec[$idcol]));

                //TODO: better solution? Can't figure out why refresh fails
                if ($rec->exists()) {
                    try {
                        $rec->refresh();
                    }
                    catch (Doctrine_Record_Exception $e) {
                        if ($e->getCode() == 0 && preg_match('/does not exist/i', $e->getMessage())) {
                            // ignore, I guess
                        }
                        else {
                            throw $e; //rethrow
                        }
                    }
                }
            }
            elseif (!$has_primary && count($rs) > 1) {
                // pick most recent that isn't me
                $q = "update $tbl set $flagcol=1 where $fkcol=? and $idcol!=?";

                // find upd_dtim column
                $data = $rec->toArray();
                foreach ($data as $key => $val) {
                    if (preg_match('/upd_dtim$/', $key)) {
                        $q .= " order by $key desc";
                    }
                }
                $conn->exec("$q limit 1", array($rec[$fkcol], $rec[$idcol]));
            }
        }
    }
    else {
        //deleted - pick most recent
        $q = "update $tbl set $flagcol=1 where $fkcol=? and $idcol!=?";

        // find upd_dtim column
        $data = $rec->toArray();
        foreach ($data as $key => $val) {
            if (preg_match('/upd_dtim$/', $key)) {
                $q .= " order by $key desc";
            }
        }
        $conn->exec("$q limit 1", array($rec[$fkcol], $rec[$idcol]));
    }
}


/**
 * Convert any newlines in string to unix format.
 *
 * @param string  $str
 * @return string
 */
function air2_normalize_newlines($str) {
    if (is_null($str)) return $str;

    // convert PC newline (CRLF) to Unix newline (LF)
    $str = preg_replace("/\r\n/", "\n", $str);

    // convert Mac newline (CR) to Unix newline (LF)
    $str = preg_replace("/\r/", "\n", $str);
    return $str;
}


/**
 * Trim, utf8-ify and normalize-newlines for a string.
 *
 * @param string  $str
 * @return string
 */
function air2_str_clean($str) {
    if (is_null($str) || !is_string($str) || strlen($str) == 0) {
        return $str;
    }

    // UTF8-ify
    $str = Encoding::convert_to_utf8($str);

    // normalize newlines
    $str = air2_normalize_newlines($str);

    // trim
    $str = trim($str);
    return $str;
}


/**
 * Get the full URI for a relative path
 *
 * @param string  $path
 * @param array   $query (optional)
 * @return string $uri
 */
function air2_uri_for($path, $query=array()) {
    $base = 'air';

    // try really hard to get the actual base
    if (function_exists('base_url')) {
        $base = base_url();
    }
    elseif (getenv('AIR2_BASE_URL')) {
        $base = getenv('AIR2_BASE_URL');
    }
    elseif (defined('AIR2_BASE_URL')) {
        $base = AIR2_BASE_URL;
    }

    // cleanup and add path
    $base = preg_replace('/\/$/', '', $base);
    $path = preg_replace('/^\//', '', $path);
    $uri = strlen($path) ? "$base/$path" : $base;

    // version all css/js files
    if (preg_match('/\.js$|\.css$/', $uri) && defined('AIR2_SYSTEM_DISP_NAME')) {
        $query['v'] = air2_urlify(AIR2_VERSION);
    }

    // add query variables
    if (count($query)) {
        $uri .= '?' . http_build_query($query);
    }
    return $uri;
}


/**
 * Print a variable
 *
 * @param mixed   $var
 * @return string
 */
function air2_print_var($var) {
    if (is_string($var)) {
        return "'$var'";
    }
    if (is_bool($var)) {
        return $var ? 'true' : 'false';
    }
    if (is_array($var)) {
        return json_encode($var);
    }
    if (is_null($var)) {
        return "null";
    }
    if (is_numeric($var)) {
        return $var;
    }
    throw new Exception("Unable to print variable");
}


/**
 * Add a 'whereIn' or 'whereNotIn' to a Doctrine_Query
 *
 * @param Doctrine_Query $q
 * @param string  $wherein
 * @param string  $column
 */
function air2_query_in(Doctrine_Query $q, $wherein, $column) {
    if (is_string($wherein) && strlen($wherein) && $wherein != '*') {
        $ins = str_split($wherein);
        if ($ins[0] == '!') {
            array_splice($ins, 0, 1);
            if (count($ins) > 0) {
                $q->andWhereNotIn($column, $ins);
            }
        }
        else {
            if (count($ins) > 0) {
                $q->andWhereIn($column, $ins);
            }
        }
    }
}


/**
 * Indicate to the search server that the record for $pk in table $table
 * needs to be re-indexed.
 *
 * @param string  $table
 * @param string  $pk
 * @return unknown
 */
function air2_touch_stale_record($table, $pk) {
    if (!is_numeric($pk)) {
        throw new Exception("pk must be a numeric primary key");
    }

    $stale_types = array(
        'source'            => StaleRecord::$TYPE_SOURCE,
        'src_response_set'  => StaleRecord::$TYPE_RESPONSE,
        'public_response'   => StaleRecord::$TYPE_PUBLIC_RESPONSE,
        'inquiry'           => StaleRecord::$TYPE_INQUIRY,
        'project'           => StaleRecord::$TYPE_PROJECT,
    );

    if (!array_key_exists($table, $stale_types)) {
        throw new Exception("Undefined table for stale records: $table");
    }

    $stale_record = new StaleRecord();
    $stale_record->str_xid = $pk;
    $stale_record->str_type = $stale_types[$table];
    $stale_record->str_upd_dtim = air2_date();
    return $stale_record->replace();
}


/**
 * Tell the search server to re-cache its metadata.
 *
 * @return unknown
 */
function air2_touch_watcher_cache() {
    throw new Exception("watcher should refresh cache itself");
}


/**
 * Returns true if $phone looks like a valid phone number.
 *
 * @param string  $phone
 * @return boolean
 */
function air2_valid_phone_number($phone) {
    if (preg_match('/^[\d\.\ \-\(\)]+$/', $phone)) {
        return true;
    }
    return false;
}


/**
 * Returns true if $code looks like a valid postal code.
 *
 * @param string  $code
 * @return boolean
 */
function air2_valid_postal_code($code) {
    // US style
    if (preg_match('/^\d\d\d\d\d(-\d\d\d\d)?$/', $code)) {
        return true;
    }
    // TODO explicit other styles? or just free form?
    if (preg_match('/^[\w\-\ ]+$/', $code)) {
        return true;
    }
    return false;
}


/**
 * Normalize phone number strings.
 *
 * @param string  $sph_number
 * @return string $formatted_number
 */
function air2_format_phone_number($sph_number) {
    $matches = array();
    if (strlen($sph_number) == 10
        &&
        preg_match('/^(\d\d\d)(\d\d\d)(\d\d\d\d)$/', $sph_number, $matches)
    ) {
        return sprintf("(%s) %s-%s", $matches[1], $matches[2], $matches[3]);
    }
    elseif (strlen($sph_number) == 16 && preg_match('/^(\d\d)(\d\d)(\d)(\d\d\d\d)(\d\d\d\d\d\d)$/', subject, $matches)) {
        return sprintf("%s %s (%s) %s %s", $matches[1], $matches[2], $matches[3], $matches[4], $matches[5]);
    }

    return $sph_number; // return untouched

}


/**
 * Returns a User object for the value of AIR2_REMOTE_USER_ID.
 *
 * @return User $user
 */
function air2_get_remote_user() {
    if (!defined('AIR2_REMOTE_USER_ID')) {
        throw new Exception('AIR2_REMOTE_USER_ID is not defined');
    }
    return Doctrine::getTable('User')->find(AIR2_REMOTE_USER_ID);
}


/**
 * Sorted array of $responses in Querymaker order.
 *
 * @param array   $responses
 * @return array  $sorted_responses
 */
function air2_sort_responses_for_display($responses) {
    if (!is_array($responses)) {
        throw new Exception('responses must be an array');
    }

    // first group
    $grouped = array(
        'contributor'   => array(),
        'public'        => array(),
        'private'       => array(),
    );

    // cull out permission question since it is public only
    // if there are other public questions.
    $perm_question = null;
    foreach ($responses as $sr) {
        $ques_type = strtolower($sr['Question']['ques_type']);
        if ($ques_type == 'z' || $ques_type == 's' || $ques_type == 'y') {
            $grouped['contributor'][] = $sr;
        }
        elseif ($ques_type == 'p') {
            $perm_question = $sr;
        }
        elseif ($sr['Question']['ques_public_flag']) {
            $grouped['public'][] = $sr;
        }
        else {
            $grouped['private'][] = $sr;
        }
    }

    if ($perm_question) {
        if (count($grouped['public'])) {
            $grouped['public'][] = $perm_question;
        }
        else {
            $grouped['private'][] = $perm_question;
        }
    }

    // then flatten
    $sorted = array_merge($grouped['contributor'], $grouped['public'], $grouped['private']);

    return $sorted;

}
