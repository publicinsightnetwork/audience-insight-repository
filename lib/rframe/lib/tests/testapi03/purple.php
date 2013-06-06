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
class TestAPI03_Purple extends Rframe_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'create', 'fetch', 'update', 'delete');
    protected $CREATE_DATA = array('val');
    protected $QUERY_ARGS  = array();
    protected $UPDATE_DATA = array('val');

    // test vars
    private static $ID = 99;


    /**
     * Create
     *
     * @param array   $data
     * @return string $uuid
     */
    protected function rec_create($data) {
        global $__TEST_OBJECTS;
        if (!isset($data['val'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'val required');
        }
        $id = self::$ID++;
        $foo = new FooRecord($id, $data['hat']);
        $__TEST_OBJECTS[] = $foo;
        return "$id";
    }


    /**
     * Query
     *
     * @param array   $args
     * @return array $records
     */
    protected function rec_query($args) {
        global $__TEST_OBJECTS;

        $rs = array();
        foreach ($__TEST_OBJECTS as $obj) {
            if (is_a($obj, 'FooRecord')) {
                $rs[] = $obj;
            }
        }
        return $rs;
    }


    /**
     * Fetch
     *
     * @param string  $uuid
     * @return mixed $record
     */
    protected function rec_fetch($uuid) {
        $all = $this->rec_query(array());
        foreach ($all as $foo_obj) {
            $id = $foo_obj->get_id();
            if ($id == $uuid) {
                return $foo_obj;
            }
        }

        // uuid not found!
        throw new Rframe_Exception(Rframe::BAD_IDENT, "Purple $uuid not found");
    }


    /**
     * Update
     *
     * @param mixed   $record
     * @param array $data
     */
    protected function rec_update($record, $data) {
        if (array_key_exists('val', $data)) {
            $record->set_value($data['val']);
        }
    }


    /**
     * Delete
     *
     * @param mixed   $record
     */
    protected function rec_delete($record) {
        global $__TEST_OBJECTS;

        $del_id = $record->get_id();
        foreach ($__TEST_OBJECTS as $idx => $obj) {
            if (is_a($obj, 'FooRecord') && $obj->get_id() == $del_id) {
                array_splice($__TEST_OBJECTS, $idx, 1);
            }
            unset($record);
        }
    }


    /**
     * Format
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
     * Format meta
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
