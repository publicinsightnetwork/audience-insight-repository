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
class TestAPI03_Purple_Red extends Rframe_Resource {

    // single resource
    protected static $REL_TYPE = self::ONE_TO_ONE;

    // API definitions
    protected $ALLOWED = array('create', 'fetch', 'update', 'delete');
    protected $CREATE_DATA = array('val');
    protected $QUERY_ARGS  = array();
    protected $UPDATE_DATA = array('val');

    // test vars
    private static $ID = 888;


    /**
     * Create
     *
     * @param array   $data
     * @return string $uuid
     */
    protected function rec_create($data) {
        $foo = $this->parent_rec;
        if (!isset($data['val'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'val required');
        }
        $id = self::$ID++;
        $ham = new HamRecord($id, $data['val']);
        $foo->set_ham($ham);
        return "$id";
    }


    /**
     * Fetch
     *
     * @return mixed $record
     */
    protected function rec_fetch($uuid) {
        $foo = $this->parent_rec;
        $ham = $foo->get_ham();
        if (!$ham) {
            throw new Rframe_Exception(RFrame::ONE_DNE, 'ham not found');
        }
        return $ham;
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
        $foo = $this->parent_rec;
        $foo->remove_ham();
        unset($record);
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
