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
 * Validator for unique column values.
 *
 * @author rcavis
 * @package default
 */
class UniqueColumnValidator extends AIR2_Validator {

    /* not a FATAL error */
    public $break_on_failure = false;

    /* column to validate unique */
    protected $col_idx;
    protected $col_name;

    /* case-sensitive when comparing values */
    protected $case_sensitive;

    /* allow blank/null for field */
    protected $allow_blank;

    /* track in assoc-array */
    protected $track;


    /**
     * Constructor
     *
     * @param int     $colidx
     * @param string  $colname
     * @param bool    $casesensitive
     * @param bool    $allowblank
     */
    function __construct($colidx, $colname, $casesensitive=false, $allowblank=false) {
        $this->col_idx = $colidx;
        $this->col_name = $colname;
        $this->case_sensitive = $casesensitive;
        $this->allow_blank = $allowblank;
        $this->track = array();
    }


    /**
     * Check the number of columns
     *
     * @param array   $data
     * @param int     $row
     * @return boolean|string
     */
    public function validate_object($data, $row) {
        $val = $data[$this->col_idx];

        // allow blanks?
        if (!$this->allow_blank) {
            if ($val === null || strlen($val) < 1) {
                $name = $this->col_name;
                return "Blank $name found in row $row";
            }
        }

        // case sensitivity
        if (!$this->case_sensitive) {
            $val = strtolower($val);
        }

        // look for existing val
        if (isset($this->track[$val])) {
            $withrow = $this->track[$val];
            $name = $this->col_name;
            return "Duplicate $name '$val' found in row $row and row $withrow";
        }
        else {
            $this->track[$val] = $row;
            return true;
        }
    }


}
