<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
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

require_once 'lib/extensions/DOCframe_Resource.php';
require_once 'AIRAPI_Fields.php';

/**
 * Doctrine-adapting layer for AIR2 resources
 *
 * @author rcavis
 * @package default
 */
abstract class AIRAPI_Resource extends DOCframe_Resource {

    /**
     *
     *
     * @var User the authz user record
     */
    protected $user;

    // paging/sorting
    protected $limit_param   = 'limit';
    protected $limit_default = 10;
    protected $offset_param   = 'offset';
    protected $offset_default = 0;
    protected $sort_param     = 'sort';
    protected $sort_default   = false;
    protected $sort_valids    = array();

    // universal search/authz params
    protected $search_param = 'q';
    protected $authz_read_param = 'read';
    protected $authz_write_param = 'write';
    protected $authz_manage_param = 'manage';
    protected $authz_untotal; //track unauthz_total

    // optionally update parent upd_dtim on save
    protected $update_parent_stamps = false;

    // the identifier field
    protected $ident = false;

    // if set (as array of string fieldnames), will be a whitelist of
    // keys to return in the radix
    protected $fields = false;
    protected $_fields = false; //cleaned version


    /**
     * Get the authz User accessing a resource
     *
     * @throws Rframe_Exception
     * @param Rframe_Parser $parser
     * @param array   $path
     * @param array   $inits
     */
    public function __construct($parser, $path=array(), $inits=array()) {
        if (!isset($inits['user'])) {
            throw new Exception('No authz-user specified!');
        }
        if (!is_a($inits['user'], 'User') || !$inits['user']->user_id) {
            throw new Exception('Invalid authz-user');
        }
        $this->user = $inits['user'];

        // for backwards-compatibility, make sure REMOTE_USER constant is set
        if (!defined('AIR2_REMOTE_USER_ID')) {
            define('AIR2_REMOTE_USER_ID', $this->user->user_id);
        }
        parent::__construct($parser, $path, $inits);

        // subclasses MUST define an $ident and a $authz_model
        if (!$this->ident) {
            throw new Exception('No identifier defined');
        }

        // add universal search/authz args
        if (in_array('query', $this->ALLOWED)) {
            $this->QUERY_ARGS[] = $this->search_param;
            $this->QUERY_ARGS[] = $this->authz_read_param;
            $this->QUERY_ARGS[] = $this->authz_write_param;
            $this->QUERY_ARGS[] = $this->authz_manage_param;
        }

        // reset fields
        $this->reset_fields();
    }


    /**
     * Re-initialize all field metadata from $this->fields
     */
    protected function reset_fields() {
        AIRAPI_Fields::replace_defaults($this->fields);
        if ($this->fields) {
            $this->_fields = array();
            $this->_init_fields($this->fields, $this->_fields);
        }
    }


    /**
     * Recursively change $field def into an assoc-array
     *
     * @param array   $src
     * @param unknown $dest (reference)
     */
    private function _init_fields($src, &$dest) {
        foreach ($src as $idx => $val) {
            if (is_int($idx) && is_string($val)) {
                $dest[$val] = 1;
            }
            elseif (is_string($idx) && is_array($val)) {
                $dest[$idx] = array();
                $this->_init_fields($val, $dest[$idx]); //recurse
            }
            else {
                throw new Exception("Bad field def ($idx - $val)");
            }
        }
    }


    /**
     * Restrict fields to those defined in $fields
     *
     * @param Doctrine_Record $record
     * @return unknown
     */
    protected function format_radix(Doctrine_Record $record) {
        $radix = parent::format_radix($record);
        if ($this->fields) {
            $radix = $this->_clean($radix, $this->_fields);
        }
        return $radix;
    }


    /**
     * Recursively clean fields
     *
     * @param array   $data
     * @param array   $fields
     * @return array
     */
    protected function _clean($data, $fields) {
        if (!is_array($data)) {
            return $data;
        }
        $cleaned = array();

        // if not assoc-array, call clean on each item
        if (!$this->is_assoc_array($data)) {
            foreach ($data as $idx => $rowdata) {
                $cleaned[] = $this->_clean($rowdata, $fields);
            }
        }
        else {
            foreach ($fields as $idx => $keep) {
                $cleaned[$idx] = isset($data[$idx]) ? $data[$idx] : null;
                if (is_array($keep)) {
                    $cleaned[$idx] = $this->_clean($cleaned[$idx], $keep);
                }

                // magically include image urls
                if ($idx == 'img_uuid') {
                    $uuid = isset($data['img_uuid']) ? $data['img_uuid'] : null;
                    $type = isset($data['img_ref_type']) ? $data['img_ref_type'] : null;
                    $dtim = isset($data['img_dtim']) ? $data['img_dtim'] : null;
                    if ($uuid && $type && $dtim) {
                        $img = Image::get_images($type, $uuid, true, $dtim);
                        foreach ($img as $size => $url) {
                            $cleaned[$size] = $url;
                        }
                    }
                }
            }
        }
        return $cleaned;
    }


    /**
     * Custom formatting
     *
     * @param mixed   $mixed
     * @param string  $method
     * @param string  $uuid   (optional)
     * @param array   $extra  (optional)
     * @return array $response
     */
    protected function format($mixed, $method, $uuid=null, $extra=array()) {
        $extra['identifier'] = $this->ident;
        $resp = parent::format($mixed, $method, $uuid, $extra);

        // add authz for single-record fetch
        if ($method == 'fetch' && is_a($mixed, 'Doctrine_Record')) {
            $mixed->clearRelated(); //query may have mucked this up
            $resp['authz'] = array(
                'may_read'   => $mixed->user_may_read($this->user),
                'may_write'  => $mixed->user_may_write($this->user),
                'may_manage' => $mixed->user_may_manage($this->user),
            );
        }

        // add unauthz-total for queries
        if ($method == 'query' && $this->authz_untotal > -1) {
            $resp['meta']['unauthz_total'] = $this->authz_untotal;
        }

        // add field defs
        if ($this->fields) {
            $resp['meta']['fields'] = $this->fields;
        }
        return $resp;
    }


    /**
     * Apply updates/authz to create a new resource
     *
     * @param array   $data
     * @return unknown
     */
    protected function rec_create($data) {
        $rec = $this->air_create($data);

        // updates
        foreach ($data as $key => $val) {
            if ($rec->getTable()->hasColumn($key)) {
                $rec->$key = $val;
            }
        }

        // authz
        $this->check_authz($rec, 'write');

        // save
        $this->air_save($rec);
        return $rec[$this->ident];
    }


    /**
     * Apply authz for querying resource
     *
     * @throws Rframe_Exception
     * @param array   $args
     * @return Doctrine_Query $q
     */
    protected function rec_query($args) {
        $this->authz_untotal = -1; //reset
        $q = $this->air_query($args);

        // apply searching/authz
        if ($q && is_a($q, 'Doctrine_Query')) {
            $a = $q->getRootAlias();
            $t = $q->getRoot()->getClassnameToReturn();

            // search
            $sp = $this->search_param;
            if (isset($args[$sp]) && strlen($args[$sp]) > 0) {
                $this->apply_search($q, $args[$sp], $t, $a);
            }

            // get unauthz total (before applying)
            $this->authz_untotal = $q->count();

            // authz (defaults to read)
            $m = 'query_may_read';
            if (isset($args[$this->authz_write_param])) {
                $m = 'query_may_write';
            }
            if (isset($args[$this->authz_manage_param])) {
                $m = 'query_may_manage';
            }
            call_user_func(array($t, $m), $q, $this->user, $a);
        }
        return $q;
    }


    /**
     * Apply a search-string to a resource
     *
     * @param Doctrine_query $q
     * @param string  $str
     * @param string  $root_tbl   (optional)
     * @param string  $root_alias (optional)
     */
    protected function apply_search($q, $str, $root_tbl=null, $root_alias=null) {
        if (method_exists($root_tbl, 'add_search_str')) {
            call_user_func(array($root_tbl, 'add_search_str'), $q, $root_alias, $str);
        }
    }


    /**
     * Apply authz for fetching resource
     *
     * @throws Rframe_Exceptions
     * @param string  $uuid
     * @param boolean $minimal (optional)
     * @return Doctrine_Record $record
     */
    protected function rec_fetch($uuid, $minimal=false) {
        $rec = $this->air_fetch($uuid, $minimal);
        if (!$rec || !$rec->exists()) {
            $cls = get_class($rec);
            throw new Rframe_Exception(Rframe::BAD_IDENT, "$cls '$uuid' not found");
        }

        // authz
        $this->check_authz($rec, 'read');
        return $rec;
    }


    /**
     * Apply updates/authz to update a resource
     *
     * @throws Rframe_Exceptions
     * @param Doctrine_Record $rec
     * @param array   $data
     */
    protected function rec_update(Doctrine_Record $rec, $data) {
        //prevent table cache from goofing things up.
        $rec->getTable()->clear();

        $ret = $this->air_update($rec, $data);
        if ($ret && is_a($ret, 'Doctrine_Record')) $rec = $ret;

        // updates
        foreach ($data as $key => $val) {
            if ($rec->getTable()->hasColumn($key)) {
                $rec->$key = $val;
            }
        }

        // authz
        $this->check_authz($rec, 'write');
        $this->air_save($rec);
    }


    /**
     * Calls ->save() on $rec, wrapped in a try/catch,
     * and re-throws any exception as a Rframe_Exception.
     *
     * @param Doctrine_Record  $rec
     */
    public function air_save(Doctrine_Record $rec) {
        try {
            $rec->save();
            $this->update_parent($rec);
        }
        catch (Exception $e) {
            // rethrow as Rframe exception
            //Carper::carp("caught save() exception: $e");
            throw new Rframe_Exception(Rframe::BAD_DATA, $e->getMessage());
        }
    }


    /**
     * Apply authz to delete a resource
     *
     * @throws Rframe_Exceptions
     * @param object  $rec
     */
    protected function rec_delete(Doctrine_Record $rec) {
        $this->air_delete($rec);

        // authz
        $this->check_authz($rec, 'delete');
        $rec->delete();
        $this->update_parent($rec);
    }


    /**
     * Check authorization for a record
     *
     * @throws Rframe_Exceptions
     * @param Doctrine_Record $rec
     * @param string  $authz_type
     */
    protected function check_authz(Doctrine_Record $rec, $authz_type) {
        $method_name = "user_may_$authz_type";
        if (!$rec->$method_name($this->user)) {
            $cls = get_class($rec);
            $msg = "Insufficient $authz_type-authz on $cls";
            throw new Rframe_Exception(Rframe::BAD_AUTHZ, $msg);
        }
    }


    /**
     * Helper function to check a data array for keys, and throw an exception
     * if any are missing.
     *
     * @throws Rframe_Exceptions
     * @param array   $data
     * @param array|string $req
     */
    protected function require_data($data, $req) {
        $req = is_array($req) ? $req : array($req);
        $missing = array();
        foreach ($req as $key) {
            if (!isset($data[$key])) {
                $missing[] = $key;
            }
        }

        // throw an exception
        if (count($missing) > 0) {
            $p = (count($missing) > 1) ? 'fields' : 'field';
            $f = implode(', ', $missing);
            throw new Rframe_Exception(Rframe::BAD_DATA, "Missing required $p ($f)");
        }
    }


    /**
     * Create a record
     *
     * @return Doctrine_Record $rec
     * @param array   $data
     */
    protected function air_create($data) {
        throw new Exception("air_create not implemented!");
    }


    /**
     * Create a query
     *
     * @return Doctrine_Query $q
     * @param array   $args
     */
    protected function air_query($args=array()) {
        throw new Exception("air_query not implemented!");
    }


    /**
     * Fetch a single record
     *
     * @return Doctrine_Record $rec
     * @param string  $uuid
     * @param boolean $minimal (optional)
     */
    protected function air_fetch($uuid, $minimal=false) {
        throw new Exception("air_fetch not implemented!");
    }


    /**
     * Non-standard updates for a record
     *
     * A Doctrine_Record may optionally be returned to alter the callers
     * reference to the record.
     *
     * @param Doctrine_Record $rec
     * @param array   $data
     */
    protected function air_update($rec, $data) {
        //no-op
    }


    /**
     * Non-standard delete procedure for a record
     *
     * @param Doctrine_Record $rec
     */
    protected function air_delete($rec) {
        //no-op
    }


    /**
     * Force master DB
     *
     * @param array   $data
     * @return array $response
     */
    public function create($data) {
        $old = AIR2_DBManager::$FORCE_MASTER_ONLY;
        AIR2_DBManager::$FORCE_MASTER_ONLY = true;

        // run create, then revert setting
        $rs = parent::create($data);
        AIR2_DBManager::$FORCE_MASTER_ONLY = $old;
        return $rs;
    }


    /**
     * Force master DB
     *
     * @param string  $uuid
     * @param array   $data
     * @return array $response
     */
    public function update($uuid, $data) {
        $old = AIR2_DBManager::$FORCE_MASTER_ONLY;
        AIR2_DBManager::$FORCE_MASTER_ONLY = true;

        // run update, then revert setting
        $rs = parent::update($uuid, $data);
        AIR2_DBManager::$FORCE_MASTER_ONLY = $old;
        return $rs;
    }


    /**
     * Optionally update the user/time stamps on the parent record
     *
     * @param Doctrine_Record $rec
     */
    protected function update_parent(Doctrine_Record $rec) {
        if ($this->update_parent_stamps && $this->parent_rec) {
            $user = $this->user->user_id;
            $dtim = air2_date();
            $parentd = $this->parent_rec->toArray();
            foreach ($parentd as $col => $val) {
                if (preg_match('/_upd_user$/', $col)) $this->parent_rec->$col = $user;
                if (preg_match('/_upd_dtim$/', $col)) $this->parent_rec->$col = $dtim;
            }
            $this->parent_rec->save();
        }
    }


}
