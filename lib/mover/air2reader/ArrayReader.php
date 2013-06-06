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

require_once "mover/AIR2_Reader.php";

/**
 * PHP Array reader
 *
 * AIR2_Reader that parses simply reads an array.
 *
 * @author rcavis
 * @package default
 */
class ArrayReader extends AIR2_Reader {

    protected $index = 0;
    protected $input;


    /**
     * Constructor
     *
     * The param should be an array of arrays (NOT assoc arrays)
     *
     * @param array   $array
     */
    function __construct($array) {
        if (!is_array($array)) {
            throw new Exception('Must pass an array');
        }
        if (count($array) && air2_is_assoc_array($array[0])) {
            throw new Exception('Array objects mustnt be assoc arrays!');
        }
        $this->input = $array;
    }


    /**
     * Start reading the array
     */
    protected function begin_read() {
        $this->index = 0;
    }


    /**
     * Read the next line in the array
     *
     * @return array|false
     */
    protected function read_object() {
        if (!isset($this->input[$this->index])) {
            return false;
        }
        else {
            $arr = $this->input[$this->index];
            $arr = is_array($arr) ? $arr : array($arr);
            $data = array('row'  => $this->index, 'data' => $arr);
            $this->index++;
            return $data;
        }
    }


    /**
     * End reading
     */
    protected function end_read() {
        // nothing to do
    }


}
