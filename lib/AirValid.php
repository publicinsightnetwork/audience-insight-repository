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

require_once DOCPATH.'/Doctrine/Validator/Driver.php';

/**
 * Doctrine Validator Airvalid
 *
 * Custom Doctrine Validator type to allow processing multiple regexps and
 * returning custom error messages.  Table definitions should include this in
 * their column definitions.  For example:
 *
 *    $this->hasColumn('something', 'string', 16, array(
 *            'airvalid' => array(
 *                '/^[\S].*[\S]$/' => 'Invalid leading or trailing whitespace',
 *            ),
 *         ));
 *
 * @author rcavis
 * @package default
 */
class Doctrine_Validator_Airvalid extends Doctrine_Validator_Driver {


    /**
     * Validate a field value
     * TODO: figure out how to handle non-string values
     *
     * @param mixed   $value
     * @return boolean
     */
    public function validate($value) {
        $errs = $this->invoker->getErrorStack();
        $fld = $this->field;
        $args = $this->args;

        // don't run on null values
        if (is_null($value)) {
            return true;
        }

        // check each regexp defined for the column
        foreach ($this->args as $regex => $msg) {
            // add the errors ourselves (so we can produce our own msg)
            if (!preg_match($regex, $value)) {
                $errs->add($fld, $msg);
            }
        }

        // ALWAYS return true ... we added things to the error stack ourselves
        return true;
    }


}
