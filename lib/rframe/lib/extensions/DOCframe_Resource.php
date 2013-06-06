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
 * Abstract class to implement some common Doctrine functionality on top of
 * the rframe resource.
 *
 * Intended for use with Doctrine 1.2.
 *
 * For information on Doctrine, see <http://www.doctrine-project.org/>.
 *
 * @version 0.1
 * @author ryancavis
 * @package default
 */
abstract class DOCframe_Resource extends Rframe_Resource {

    /**
     * Check for Doctrine class types
     *
     * @param string  $method
     * @param mixed   $return (reference)
     */
    protected function sanity($method, &$return) {
        if ($method == 'rec_query') {
            if (!is_a($return, 'Doctrine_Query')) {
                throw new Exception("rec_query must return Doctrine_Query");
            }
        }
        elseif ($method == 'rec_fetch') {
            if (!is_a($return, 'Doctrine_Record')) {
                throw new Exception("rec_fetch must return Doctrine_Record");
            }
        }
        else {
            parent::sanity($method, $return);
        }
    }


    /**
     * Format the value returned from rec_query() into an array radix.
     *
     * @param Doctrine_Query $q
     * @return array $radix
     */
    protected function format_query_radix(Doctrine_Query $q) {
        $recs = $q->execute();
        $radix = array();
        foreach ($recs as $rec) {
            $radix[] = $this->format_radix($rec);
        }
        return $radix;
    }


    /**
     * Get total from a Doctrine_Query object.
     *
     * @param Doctrine_Query $q
     * @return int  $total
     */
    protected function rec_query_total(Doctrine_Query $q) {
        return $q->count();
    }


    /**
     * Add sort to Doctrine_Query.
     *
     * @param Doctrine_Query $q
     * @param string $fld
     * @param string $dir
     */
    protected function rec_query_add_sort(Doctrine_Query $q, $fld, $dir) {
        $q->addOrderBy("$fld $dir");
    }


    /**
     * Add a limit/offset to a Doctrine_Query.
     *
     * @param Doctrine_Query $q
     * @param int   $limit
     * @param int   $offset
     */
    protected function rec_query_page(Doctrine_Query $q, $limit, $offset) {
        if ($limit > 0) {
            $q->limit($limit);
        }
        if ($offset > 0) {
            $q->offset($offset);
        }
    }


    /**
     * Format a Doctrine_Record as an array.
     *
     * @param Doctrine_Record $record
     * @return array $radix
     */
    protected function format_radix(Doctrine_Record $record) {
        return $record->toArray();
    }


}
