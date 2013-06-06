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

require_once 'mover/AIR2_Validator.php';

/**
 * Make sure each data row has an identifier column
 *
 * @author rcavis
 * @package default
 */
class HasIdentValidator extends AIR2_Validator {

    /* not a FATAL error */
    public $break_on_failure = false;

    /* map of possible ident columns; colidx => colname */
    protected $idents = array();


    /**
     * Constructor
     *
     * @param array   $headers
     * @param array   $ident_columns
     */
    function __construct($headers, $ident_columns) {
        foreach ($headers as $idx => $name) {
            if (in_array($name, $ident_columns)) {
                $this->idents[$idx] = $name;
            }
        }
    }


    /**
     * Make sure an ident column is set
     *
     * @param array   $data
     * @param int     $row
     * @return boolean|string
     */
    public function validate_object($data, $row) {
        $has_index = false;
        foreach ($this->idents as $idx => $name) {
            $val = $data[$idx];
            if ($val && strlen(trim($val)) > 0) {
                $has_index = true;
                break;
            }
        }

        if (!$has_index) {
            return "No identifier column for row $row, please check for extra commas in your CSV file.";
        }
        else {
            return true;
        }
    }


}
