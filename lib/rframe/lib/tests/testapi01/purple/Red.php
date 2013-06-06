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
class TestAPI01_Purple_Red extends Rframe_Resource {

    // API definitions
    protected $ALLOWED = array('fetch', 'query');
    protected $CREATE_DATA = array();
    protected $QUERY_ARGS  = array('filter');
    protected $UPDATE_DATA = array();


    /**
     * Query this resource for an array of records.  If the query cannot be
     * executed, an appropriate Exception should be thrown.
     *
     * @param array   $args
     * @return array $records
     * @throws Rframe_Exceptions
     */
    protected function rec_query($args) {
        $purple_foo = $this->parent_rec;
        $red_bars = $purple_foo->get_bars();
        
        if (isset($args['filter'])) {
            $result = array();
            $f = $args['filter'];
            foreach ($red_bars as $bar) {
                if (preg_match("/$f/", $bar->get_value())) {
                    $result[] = $bar;
                }
            }
            $red_bars = $result;
        }
        
        return $red_bars;
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
        $purple_foo = $this->parent_rec;
        $red_bars = $purple_foo->get_bars();

        foreach ($red_bars as $bar_obj) {
            $id = $bar_obj->get_id();
            if ($id == $uuid) {
                return $bar_obj;
            }
        }

        // uuid not found!
        throw new Rframe_Exception(Rframe::BAD_IDENT, "Red $uuid not found");
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
            'blah_id'  => $record->get_id(),
            'blah_val' => $record->get_value(),
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
                'blah_id'  => 'integer',
                'blah_val' => 'string',
            ),
        );
    }
    
    
    
}
