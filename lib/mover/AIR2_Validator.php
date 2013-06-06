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

/**
 * Abstract AIR2 Data Validator class
 *
 * This class defines the interface for a AIR2 data validation, as used in
 * the AIR2_Writer class.  It also lets the subclass determine if failing
 * validation is fatal enough that other validators shouldn't be called on
 * this object.
 *
 * @author rcavis
 * @package default
 */
abstract class AIR2_Validator {

    /*
     * By default, failing validation shouldn't stop subsequent validators
     * from being called.  Subclasses may override this.
     */
    public $break_on_failure = false;


    /**
     * Validate an object.  If the object validates, it should return true.
     * Otherwise, it should return a useful string error message, usually
     * incorporating the row/column that the error occured on.
     *
     * @param array   $data
     * @param int     $row
     * @return boolean|string
     */
    abstract public function validate_object($data, $row);


}
