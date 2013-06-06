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

require_once 'rframe/AIRAPI_Resource.php';

/**
 * AIRAPI Resource that represents arrays instead of Doctrine_Records
 *
 * Since PHP has no multi-inheritance, the best way to accomplish this is to
 * inherit from AIRAPI_Resource (for all the AIR-magic), and undo the
 * Doctrine-specific things.
 *
 * Subclasses should implement the "rec_something" methods instead of the
 * "air_something" methods, which should now return arrays.
 *
 * @author rcavis
 * @package default
 */
abstract class AIRAPI_ArrayResource extends AIRAPI_Resource {


    /**
     * Check for arrays
     *
     * @param string  $method
     * @param mixed   $return (reference)
     */
    protected function sanity($method, &$return) {
        if ($method == 'rec_query') {
            if (!(is_array($return) && !$this->is_assoc_array($return))) {
                throw new Exception("rec_query must return array");
            }
        }
        elseif ($method == 'rec_fetch') {
            if (!$this->is_assoc_array($return)) {
                throw new Exception("rec_fetch must return assoc-array");
            }
        }
        else {
            parent::sanity($method, $return);
        }
    }


    /**
     * Format each item in a query
     *
     * @param array   $list
     * @return array $radix
     */
    protected function format_query_radix($list) {
        $radix = array();
        foreach ($list as $row) {
            $radix[] = $this->format_radix($row);
        }
        return $radix;
    }


    /**
     * Must be imlemented by subclass to return anything meaningful
     *
     * @param array   $list
     * @return int  $total
     */
    protected function rec_query_total($list) {
        return count($list);
    }


    /**
     * Must be imlemented by subclass to do anything meaningful
     *
     * @param array   $list (reference)
     * @param string  $fld
     * @param string  $dir
     */
    protected function rec_query_add_sort(&$list, $fld, $dir) {
        // no-op
    }


    /**
     * Must be imlemented by subclass to do anything meaningful
     *
     * @param array   $list   (reference)
     * @param int     $limit
     * @param int     $offset
     */
    protected function rec_query_page(&$list, $limit, $offset) {
        if ($limit > 0) {
            // no-op
        }
        if ($offset > 0) {
            // no-op
        }
    }


    /**
     * Just return the cleaned array
     *
     * @param array   $record
     * @return array $radix
     */
    protected function format_radix($record) {
        if ($this->fields) {
            $record = $this->_clean($record, $this->_fields);
        }
        return $record;
    }


    /**
     * Force implementation by subclasses
     *
     * @param array   $data
     * @return string $uuid
     */
    protected function rec_create($data) {
        throw new Exception('Method not implemented');
        return null;
    }


    /**
     * Force implementation by subclass
     *
     * @param array   $args
     * @return array $list
     */
    protected function rec_query($args) {
        throw new Exception('Method not implemented');
        return null;
    }


    /**
     * Force implementation by subclasses
     *
     * @param string  $uuid
     * @return array $record
     */
    protected function rec_fetch($uuid) {
        throw new Exception('Method not implemented');
        return null;
    }


    /**
     * Force implementation by subclasses
     *
     * @param array   $rec  (reference)
     * @param array   $data
     */
    protected function rec_update(&$rec, $data) {
        throw new Exception('Method not implemented');
    }


    /**
     * Force implementation by subclasses
     *
     * @param array   $rec (reference)
     */
    protected function rec_delete(&$rec) {
        throw new Exception('Method not implemented');
    }


}
