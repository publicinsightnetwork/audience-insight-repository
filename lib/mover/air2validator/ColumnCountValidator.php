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

require_once 'AIR2_Validator.php';

/**
 * Validator for the number of columns in an object.
 *
 * @author rcavis
 * @package default
 */
class ColumnCountValidator extends AIR2_Validator {

    /* this is a FATAL error */
    public $break_on_failure = true;

    /* expected num cols */
    protected $num_cols;


    /**
     * Constructor
     *
     * @param int     $num_cols
     */
    function __construct($num_cols) {
        $this->num_cols = $num_cols;
    }


    /**
     * Check the number of columns
     *
     * @param array   $data
     * @param int     $row
     * @return boolean|string
     */
    public function validate_object($data, $row) {
        $found = count($data);
        $expected = $this->num_cols;
        if ($found != $expected) {
            return "Expecting $expected columns, found $found in row $row";
        }
        return true;
    }


}
