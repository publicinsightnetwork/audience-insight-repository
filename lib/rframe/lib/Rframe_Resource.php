<?php
/*******************************************************************************
 *
 *  Copyright (c) 2011, Ryan Cavis
 *  All rights reserved.
 *
 *  This file is part of the rframe project <http://code.google.com/p/rframe/>
 *
 *  Rframe is free software: redistribution and use with or without
 *  modification are permitted under the terms of the New/Modified
 *  (3-clause) BSD License.
 *
 *  Rframe is provided as-is, without ANY express or implied warranties.
 *  Implied warranties of merchantability or fitness are disclaimed.  See
 *  the New BSD License for details.  A copy should have been provided with
 *  rframe, and is also at <http://www.opensource.org/licenses/BSD-3-Clause/>
 *
 ******************************************************************************/


/**
 * Abstract class represeting a resource in the API.  Subclasses should
 * implement the API definition variables (as needed), and the abstract methods
 * at the bottom.
 *
 * @version 0.1
 * @author ryancavis
 * @package default
 */
abstract class Rframe_Resource {

    // relationship types (describes relationship to parent)
    const ONE_TO_MANY = 1;
    const ONE_TO_ONE  = 2;
    protected static $REL_TYPE = self::ONE_TO_MANY; //default

    // API definitions
    protected $ALLOWED     = array(/*create, query, fetch, update, delete*/);
    protected $CREATE_DATA = array();
    protected $QUERY_ARGS  = array();
    protected $UPDATE_DATA = array();

    // querying
    protected $query_args_default = array();
    protected $limit_param;
    protected $limit_default;
    protected $offset_param;
    protected $offset_default;
    protected $sort_param;
    protected $sort_default;
    protected $sort_valids = array();

    // fetching with related child resources
    protected $fetch_with_key = 'with';

    // the record representing the immediate parent of this resource
    protected $parent_rec = null;

    // static return values, in case fetching parent fails
    protected $parent_err = null;

    // parser used for routes in this API
    protected $parser;
    protected $path;
    protected $init;


    /**
     * Construct a resource.  The $path should NEVER include an ending UUID...
     * it should always end with the locator for this resource.
     *
     * @throws Rframe_Exception
     * @param Rframe_Parser $parser
     * @param array         $path
     * @param array         $inits
     */
    public function __construct($parser, $path=array(), $inits=array()) {
        $this->parser = $parser;
        $this->path = $path;
        $this->init = $inits;

        // add query data to QUERY_ARGS
        if (in_array('query', $this->ALLOWED)) {
            if ($this->limit_param) {
                $this->QUERY_ARGS[] = $this->limit_param;
            }
            if ($this->offset_param) {
                $this->QUERY_ARGS[] = $this->offset_param;
            }
            if ($this->sort_param && count($this->sort_valids)) {
                $this->QUERY_ARGS[] = $this->sort_param;
            }
        }

        // construct our parent resource
        if (count($path) > 1) {
            array_pop($path);
            $parent = $parser->resource($path);
            $uuid = $parser->uuid($path);
            if (!$parent) {
                $p = implode($parser->delimiter, $path);
                throw new Exception("Error parsing parent ($p)");
            }

            // fetch the parent resource
            try {
                $parent->check_method('fetch', $uuid);
                $this->parent_rec = $parent->rec_fetch($uuid, true);
                $parent->sanity('rec_fetch', $this->parent_rec);
            }
            catch (Rframe_Exception $e) {
                $this->parent_err = $e;
            }
        }
    }


    /**
     * Get the relationship type of this resource.  To accomodate PHP 5.2, you
     * must pass in the name of the class for this to work.
     *
     * @param string $class
     * @return int
     */
    public static function get_rel_type($class) {
        $vars = get_class_vars($class);
        $type = $vars['REL_TYPE'];
        return $type;
    }


    /**
     * Describe this abstract resource.  Returns an array containing valid
     * methods, keys, and child resources.
     *
     * @return array $desc
     */
    public function describe() {
        $route = $this->parser->class_to_route(get_class($this));
        $desc = array(
            'route'    => $route,
            'methods'  => array(
                'create' => false,
                'query'  => false,
                'fetch'  => false,
                'update' => false,
                'delete' => false,
            ),
            'children' => $this->parser->get_children($route),
        );
        if (in_array('create', $this->ALLOWED)) {
            $desc['methods']['create'] = $this->CREATE_DATA;
        }
        if (in_array('query', $this->ALLOWED)) {
            $desc['methods']['query'] = $this->QUERY_ARGS;
            if ($this->sort_param && count($this->sort_valids)) {
                $desc['sorts'] = $this->sort_valids;
            }
        }
        if (in_array('fetch', $this->ALLOWED)) {
            $desc['methods']['fetch'] = true;
        }
        if (in_array('update', $this->ALLOWED)) {
            $desc['methods']['update'] = $this->UPDATE_DATA;
        }
        if (in_array('delete', $this->ALLOWED)) {
            $desc['methods']['delete'] = true;
        }
        return $desc;
    }


    /**
     * Helper function to validate method called.
     *
     * @throws Rframe_Exception
     * @param string  $method
     * @param string  $uuid   (optional)
     */
    protected function check_method($method, $uuid=null) {
        // check for parent exception
        if ($this->parent_err) {
            throw $this->parent_err;
        }

        // method not allowed by API
        if (!in_array($method, $this->ALLOWED)) {
            $msg = ucfirst($method) . ' not allowed on resource';
            throw new Rframe_Exception(Rframe::BAD_METHOD, $msg);
        }

        // path invalid for REST
        $type = self::get_rel_type(get_class($this));
        if ($type == self::ONE_TO_MANY) {
            if ($uuid && ($method == 'create' || $method == 'query')) {
                $msg = "Invalid path for $method: '{$this->path}'";
                throw new Rframe_Exception(Rframe::BAD_PATHMETHOD, $msg);
            }
            if (!$uuid && $method != 'create' && $method != 'query') {
                $msg = "Invalid path for $method: '{$this->path}'";
                throw new Rframe_Exception(Rframe::BAD_PATHMETHOD, $msg);
            }
        }
        elseif ($type == self::ONE_TO_ONE) {
            if ($uuid) {
                throw new Exception("Why did you pass a UUID?");
            }
            if ($method == 'query') {
                throw new Rframe_Exception(Rframe::BAD_METHOD, 'Query not allowed on resource');
            }
        }
    }


    /**
     * Helper function to validate data keys
     *
     * @throws Rframe_Exception
     * @param array   $data
     * @param string  $method
     */
    protected function check_keys($data, $method) {
        $str = ($method == 'query') ? 'args' : 'data';
        $allowed = $this->QUERY_ARGS;
        if ($method == 'create') {
            $allowed = $this->CREATE_DATA;
        }
        elseif ($method == 'update') {
            $allowed = $this->UPDATE_DATA;
        }

        // check data keys
        $disallowed = array();
        foreach ($data as $key => $val) {
            if (!in_array($key, $allowed)) {
                $disallowed[] = $key;
            }
        }
        if (count($disallowed)) {
            $keys = implode(', ', $disallowed);
            $msg = "Disallowed $method $str ($keys)";
            throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
        }
    }


    /**
     * Helper function to remove/return any sort/limit/offset keys from an
     * array of query args.  Also validates any keys.
     *
     * @throws Rframe_Exception
     * @param  array $args
     * @return array $paging_data
     */
    protected function remove_paging_keys(&$args) {
        $paging = array();

        // sort
        if ($this->sort_param) {
            // only apply if set or there's a default sort
            $set = array_key_exists($this->sort_param, $args);
            if ($set || $this->sort_default) {
                $sort = $set ? $args[$this->sort_param] : $this->sort_default;
                unset($args[$this->sort_param]);
                $paging['sort'] = array();

                // must be valid string
                if (!is_string($sort) || strlen($sort) < 1) {
                    throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid sort '$sort'");
                }

                // get parts from string: 'fld1 dir1, fld2 dir2, ...'
                $sorts = explode(',', $sort);
                foreach ($sorts as $single_sort) {
                    $sp = $this->_get_sort($single_sort);
                    $paging['sort'][] = $sp;
                }
            }
        }

        // limit
        if ($this->limit_param) {
            // only apply if set or there's a default limit (> 0)
            $set = array_key_exists($this->limit_param, $args);
            if ($set || $this->limit_default > 0) {
                $lim = $set ? $args[$this->limit_param] : $this->limit_default;
                unset($args[$this->limit_param]);

                // must be valid int
                if (!is_numeric($lim) || $lim < 0 || $lim != round($lim)) {
                    throw new Rframe_Exception(Rframe::BAD_DATA, "Bad limit '$lim'");
                }

                // only apply if it's > 0 (otherwise, NO LIMIT)
                $lim = intval($lim);
                if ($lim > 0) $paging['limit'] = $lim;
            }
        }

        // offset
        if ($this->offset_param) {
            // only apply if set or there's a default limit (> 0)
            $set = array_key_exists($this->offset_param, $args);
            if ($set || $this->offset_default) {
                $off = $set ? $args[$this->offset_param] : $this->offset_default;
                unset($args[$this->offset_param]);

                // must be valid int
                if (!is_numeric($off) || $off < 0 || $off != round($off)) {
                    throw new Rframe_Exception(Rframe::BAD_DATA, "Bad offset '$off'");
                }

                // only apply if it's > 0 (otherwise, NO OFFSET)
                $off = intval($off);
                if ($off > 0) $paging['offset'] = $off;
            }
        }
        return $paging;
    }


    /**
     * Helper function to get sorting field/direction from a string.  Each
     * sort string should have the format "fld dir, fld dir".
     *
     * @param string $str
     * @return array $fld_dir
     */
    protected function _get_sort($str) {
        $parts = explode(' ', trim($str));
        if (count($parts) == 1) $parts[] = 'asc';
        if (count($parts) != 2) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "Bad sort '$str'");
        }
        if (!in_array($parts[0], $this->sort_valids)) {
            $valids = implode(', ', $this->sort_valids);
            $msg = "Bad sort field '$str'. Valid: ($valids)";
            throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
        }
        $parts[1] = strtolower($parts[1]);
        if (!in_array($parts[1], array('asc', 'desc'))) {
            $msg = "Bad sort direction '$str'. Valid: (asc, desc)";
            throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
        }
        return $parts;
    }


    /**
     * Create a new record at this resource.  Returns the formatted result.
     *
     * @param array   $data
     * @return array $response
     */
    public function create($data) {
        try {
            $this->check_method('create');
            $this->check_keys($data, 'create');

            // create
            $uuid = $this->rec_create($data);
            $this->sanity('rec_create', $uuid);

            // re-fetch
            $rec = $this->rec_fetch($uuid);
            $this->sanity('rec_fetch', $rec);

            // success!
            return $this->format($rec, 'create', $uuid);
        }
        catch (Rframe_Exception $e) {
            return $this->format($e, 'create');
        }
    }


    /**
     * Query for existing resources.
     *
     * @param array   $args
     * @return array $response
     */
    public function query($args) {
        try {
            $this->check_method('query');
            $this->check_keys($args, 'query');

            // add any 'default' query args to $args
            foreach ($this->query_args_default as $key => $val) {
                if (!array_key_exists($key, $args)) {
                    $args[$key] = $val;
                }
            }

            // query
            $pg_args = $this->remove_paging_keys($args);
            $recs = $this->rec_query($args);
            $this->sanity('rec_query', $recs);
            $extra = array(
                'total' => $this->rec_query_total($recs),
            );

            // add non-paging keys to metadata
            $extra['query'] = array();
            foreach ($args as $key => $val) {
                $extra['query'][$key] = $val;
            }

            // apply sorting
            if (isset($pg_args['sort'])) {
                $extra['sort'] = $pg_args['sort'];
                foreach ($pg_args['sort'] as &$srt) {
                    $this->rec_query_add_sort($recs, $srt[0], $srt[1]);
                    $srt = $srt[0].' '.$srt[1];
                }
                $extra['sortstr'] = implode(',', $pg_args['sort']);
            }

            // apply limit/offset
            $extra['limit'] = isset($pg_args['limit']) ? $pg_args['limit'] : 0;
            $extra['offset'] = isset($pg_args['offset']) ? $pg_args['offset'] : 0;
            if ($extra['limit'] || $extra['offset']) {
                $this->rec_query_page($recs, $extra['limit'], $extra['offset']);
            }

            // success!
            return $this->format($recs, 'query', null, $extra);
        }
        catch (Rframe_Exception $e) {
            return $this->format($e, 'query');
        }
    }


    /**
     * Fetch a resource without changing anything.
     *
     * @param string  $uuid
     * @param array   $args (optional)
     * @return array $response
     */
    public function fetch($uuid, $args=array()) {
        try {
            $this->check_method('fetch', $uuid);

            // fetch
            $rec = $this->rec_fetch($uuid);
            $this->sanity('rec_fetch', $rec);

            // success!
            return $this->format($rec, 'fetch', $uuid, $args);
        }
        catch (Rframe_Exception $e) {
            return $this->format($e, 'fetch', $uuid);
        }
    }


    /**
     * Update a resource, and then return it.
     *
     * @param string  $uuid
     * @param array   $data
     * @return array $response
     */
    public function update($uuid, $data) {
        try {
            $this->check_method('update', $uuid);
            $this->check_keys($data, 'update');

            // fetch and update
            $rec = $this->rec_fetch($uuid, true);
            $this->sanity('rec_fetch', $rec);
            $upd = $this->rec_update($rec, $data);
            $this->sanity('rec_update', $upd);

            // re-fetch with all data
            $rec = $this->rec_fetch($uuid);
            $this->sanity('rec_fetch', $rec);

            // success!
            return $this->format($rec, 'update', $uuid);
        }
        catch (Rframe_Exception $e) {
            return $this->format($e, 'update', $uuid);
        }
    }


    /**
     * Delete a resource, returning the uuid of the resource.
     *
     * @param string  $uuid
     * @return array $response
     */
    public function delete($uuid) {
        try {
            $this->check_method('delete', $uuid);

            // fetch and delete
            $rec = $this->rec_fetch($uuid, true);
            $this->sanity('rec_fetch', $rec);
            $del = $this->rec_delete($rec);
            $this->sanity('rec_delete', $del);

            // success!
            return $this->format(null, 'delete', $uuid);
        }
        catch (Rframe_Exception $e) {
            return $this->format($e, 'delete', $uuid);
        }
    }


    /**
     * Sanity check values returned from implemented abstract functions, to
     * make sure they work properly.
     *
     * @param string  $method
     * @param mixed   $return
     */
    protected function sanity($method, &$return) {
        if ($method == 'rec_create') {
            if (!is_string($return)) {
                throw new Exception("rec_create must return string uuid");
            }
        }
        elseif ($method == 'rec_query') {
            if (!is_array($return) || $this->is_assoc_array($return)) {
                throw new Exception("rec_query must return array of records");
            }
        }
        elseif ($method == 'rec_fetch') {
            if (!$return) {
                throw new Exception("rec_fetch must return record");
            }
        }
        elseif ($method == 'rec_update') {
            //nothing
        }
        elseif ($method == 'rec_delete') {
            //nothing
        }
        else {
            throw new Exception("Unknown method '$method'");
        }
    }


    /**
     * Helper to distinguish between arrays and associative arrays.
     *
     * @param array   $array
     * @return boolean $is_assoc
     */
    final protected function is_assoc_array($array) {
        if (!is_array($array) || empty($array)) return false;
        $keys = array_keys($array);
        return array_keys($keys) !== $keys;
    }


    /**
     * Format a response for a mixed data type.  Any extra metadata provided
     * will be merged with existing meta.
     *
     * @param mixed   $mixed
     * @param string  $method
     * @param string  $uuid  (optional)
     * @param array   $extra (optional)
     * @return array  $response
     */
    protected function format($mixed, $method, $uuid=null, $extra=array()) {
        // generic response object
        $resp = array(
            'method'  => $method,
            'success' => true,
            'code'    => Rframe::OKAY,
            'api'     => $this->describe(),
        );

        // determine the path
        if ($uuid) {
            $resp['path'] = implode($this->parser->delimiter, $this->path);
            $resp['path'] .= $this->parser->delimiter.$uuid;
            $resp['uuid'] = $uuid;
        }
        else {
            $resp['path'] = implode($this->parser->delimiter, $this->path);
        }

        // response-type specific formatting
        if (is_a($mixed, 'Rframe_Exception')) {
            // Error!
            $resp['success'] = $mixed->getCode() >= Rframe::OKAY;
            $resp['message'] = $mixed->getMessage();
            $resp['code'] = $mixed->getCode();
        }
        elseif ($method == 'query') {
            // multiple records
            $resp['radix'] = $this->format_query_radix($mixed);
            $resp['meta'] = $this->format_meta($mixed, $method);
            $resp['meta'] = array_merge($resp['meta'], $extra);
        }
        elseif ($method == 'delete') {
            // nothing to do
        }
        else {
            // single record
            $resp['radix'] = $this->format_radix($mixed);
            $resp['meta'] = $this->format_meta($mixed, $method);

            // process any fetch with related items attached
            if (array_key_exists($this->fetch_with_key, $extra)) {
                $with = $extra[$this->fetch_with_key];
                unset($extra[$this->fetch_with_key]);
                $resp['meta'][$this->fetch_with_key] = array();

                if ($with == '*') {
                    $with = $resp['api']['children'];
                }
                if (!is_array($with)) {
                    $with = array($with);
                }
                foreach ($with as $key => $val) {
                    $childname = is_int($key) ? $val : $key;
                    $childargs = is_int($key) ? array() : $val;
                    $wdata = $this->format_fetch_with($resp['path'], $childname, $childargs);
                    if ($wdata) {
                        $resp['meta'][$this->fetch_with_key][$childname] = $childargs;
                        $resp['radix'][$childname] = $wdata;
                    }
                }
            }

            // merge remaining extras
            $resp['meta'] = array_merge($resp['meta'], $extra);
        }

        return $resp;
    }


    /**
     * Attach child resources to a 'fetch' query
     *
     * @param string $path
     * @param string $childname
     * @param array $args
     * @return array $resp
     */
    protected function format_fetch_with($path, $childname, $args=array()) {
        $childpath = $path . $this->parser->delimiter . $childname;

        // TODO: what happens with invalid with?
        $rsc = $this->parser->resource($childpath);
        if (!$rsc) {
            return false;
        }

        $child = $rsc->query($args);
        if ($child['code'] < Rframe::OKAY) {
            return false;
        }
        return $child['radix'];
    }


    /**
     * Format the value returned from rec_query() into an array radix.
     *
     * @param mixed   $mixed
     * @return array $radix
     */
    protected function format_query_radix($mixed) {
        $radix = array();
        foreach ($mixed as $rec) {
            $radix[] = $this->format_radix($rec);
        }
        return $radix;
    }


    /**
     * Create a new record at this resource.  If the record cannot be created,
     * an appropriate Exception should be thrown.
     *
     * @param array   $data
     * @return string $uuid
     * @throws Rframe_Exceptions
     */
    protected function rec_create($data) {
        throw new Exception("Method not implemented");
    }


    /**
     * Query this resource for an array of records.  If the query cannot be
     * executed, an appropriate Exception should be thrown.
     *
     * @param array   $args
     * @return mixed $records
     * @throws Rframe_Exceptions
     */
    protected function rec_query($args) {
        throw new Exception("Method not implemented");
    }


    /**
     * Return the total number of records of a query.  This method is called
     * before any sorting/paging is applied.
     *
     * @param mixed $mixed (reference)
     * @return int  $total
     */
    protected function rec_query_total(&$mixed) {
        return count($mixed);
    }


    /**
     * Apply a single sort to a query.  Sorting should be additive, and this
     * method may get called multiple times to sort something.
     *
     * @param mixed  $mixed (reference)
     * @param string $fld
     * @param string $dir
     */
    protected function rec_query_add_sort(&$mixed, $fld, $dir) {
        throw new Exception("No sort defined");
    }


    /**
     * Apply limit/offset to a query.  This method is called after sorting.
     * A limit of '0' should be interpreted as 'no limit'.
     *
     * @param mixed $mixed (reference)
     * @param int   $limit
     * @param int   $offset
     */
    protected function rec_query_page(&$mixed, $limit, $offset) {
        $limit = ($limit > 0) ? $limit : count($mixed);
        $mixed = array_splice($mixed, $offset, $limit);
    }


    /**
     * Fetch a single record at this resource.  If the record cannot be fetched
     * or viewed, an appropriate Exception should be thrown.
     *
     * The minimal flag indicates whether the record is being fetched for
     * deleting/updating/verifying-existence, or if all data for formatting
     * needs to be fetched as well.
     *
     * @param string  $uuid
     * @param boolean $minimal (optional)
     * @return mixed $record
     * @throws Rframe_Exceptions
     */
    protected function rec_fetch($uuid, $minimal=false) {
        throw new Exception("Method not implemented");
    }


    /**
     * Update a record at this resource.  The record was found using the
     * rec_fetch() function.  If the record cannot be updated, an appropriate
     * Exception should be thrown.
     *
     * @param mixed   $record
     * @param array   $data
     * @throws Rframe_Exceptions
     */
    protected function rec_update($record, $data) {
        throw new Exception("Method not implemented");
    }


    /**
     * Delete a record at this resource.  The record was found using the
     * rec_fetch() function.  If the record cannot be deleted, an appropriate
     * Exception should be thrown.
     *
     * @param mixed   $record
     * @throws Rframe_Exceptions
     */
    protected function rec_delete($record) {
        throw new Exception("Method not implemented");
    }


    /**
     * Format a record into an array, to be used as the 'radix' of the response
     * object.
     *
     * @param mixed   $record
     * @return array $radix
     */
    protected function format_radix($record) {
        throw new Exception("Method not implemented");
    }


    /**
     * Format metadata describing this resource for the 'meta' part of the
     * response object.
     *
     * @param mixed   $mixed
     * @param string  $method
     * @return array $meta
     */
    protected function format_meta($mixed, $method) {
        return array();
    }


}
