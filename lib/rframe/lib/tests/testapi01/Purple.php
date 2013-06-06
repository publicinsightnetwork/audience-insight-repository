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
 * Test API resource
 *
 * @version 0.1
 * @author ryancavis
 * @package default
 */
class TestAPI01_Purple extends Rframe_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'create', 'fetch', 'update', 'delete');
    protected $CREATE_DATA = array('hat');
    protected $QUERY_ARGS  = array('start', 'end');
    protected $UPDATE_DATA = array('bird');

    // test vars
    private static $ID = 99;


    /**
     * Create a new record at this resource.  If the record cannot be created,
     * an appropriate Exception should be thrown.
     *
     * @param array   $data
     * @return string $uuid
     * @throws Rframe_Exceptions
     */
    protected function rec_create($data) {
        global $__TEST_OBJECTS;
        if (!isset($data['hat'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'hat required');
        }
        if (!is_string($data['hat']) || strlen($data['hat']) < 2) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'hat too small');
        }
        $id = self::$ID++;
        $foo = new FooRecord($id, $data['hat']);
        $__TEST_OBJECTS[] = $foo;
        return "$id";
    }


    /**
     * Query this resource for an array of records.  If the query cannot be
     * executed, an appropriate Exception should be thrown.
     *
     * @param array   $args
     * @return array $records
     * @throws Rframe_Exceptions
     */
    protected function rec_query($args) {
        global $__TEST_OBJECTS;

        // start with all
        $rs = $__TEST_OBJECTS;

        // restrict 'starts'
        if (isset($args['start'])) {
            $matched = array();
            $starts = $args['start'];
            foreach ($rs as $foo_obj) {
                $val = $foo_obj->get_value();
                if (preg_match("/^$starts/", $val)) {
                    $matched[] = $foo_obj;
                }
            }
            $rs = $matched;
        }

        // restrict 'ends'
        if (isset($args['end'])) {
            $matched = array();
            $ends = $args['end'];
            foreach ($rs as $foo_obj) {
                $val = $foo_obj->get_value();
                if (preg_match("/$ends$/", $val)) {
                    $matched[] = $foo_obj;
                }
            }
            $rs = $matched;
        }
        return $rs;
    }


    /**
     * Fetch a single record at this resource.  If the record cannot be fetched
     * or viewed, an appropriate Exception should be thrown.
     *
     * @param string  $uuid
     * @return mixed $record
     * @throws Rframe_Exceptions
     */
    protected function rec_fetch($uuid) {
        global $__TEST_OBJECTS;
        foreach ($__TEST_OBJECTS as $foo_obj) {
            $id = $foo_obj->get_id();
            if ($id == $uuid) {
                return $foo_obj;
            }
        }

        // uuid not found!
        throw new Rframe_Exception(Rframe::BAD_IDENT, "Purple $uuid not found");
    }


    /**
     * Update a record at this resource.  The record was found using the
     * rec_fetch() function.  If the record cannot be updated, an appropriate
     * Exception should be thrown.
     *
     * @param mixed   $record
     * @param array $data
     * @throws Rframe_Exceptions
     */
    protected function rec_update($record, $data) {
        if (array_key_exists('bird', $data)) {
            if (is_string($data['bird']) && strlen($data['bird']) < 2) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'bird too small');
            }
            $record->set_value($data['bird']);
        }
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
        global $__TEST_OBJECTS;

        $del_id = $record->get_id();
        foreach ($__TEST_OBJECTS as $idx => $foo_obj) {
            $id = $foo_obj->get_id();
            if ($id == $del_id) {
                array_splice($__TEST_OBJECTS, $idx, 1);
            }
            unset($record);
        }
    }


    /**
     * Format a record into an array, to be used as the 'radix' of the response
     * object.
     *
     * @param mixed   $record
     * @return array $radix
     */
    protected function format_radix($record) {
        $radix = array(
            'my_id'  => $record->get_id(),
            'my_val' => $record->get_value(),
        );
        return $radix;
    }


    /**
     * Format metadata describing this resource for the 'meta' part of the
     * response object.
     *
     * @param mixed $mixed
     * @param string $method
     * @return array $meta
     */
    protected function format_meta($mixed, $method) {
        return array(
            'columns' => array(
                'my_id'  => 'integer',
                'my_val' => 'string',
            ),
        );
    }


}
