<?php
/**************************************************************************
 *
 *   Copyright 2013 American Public Media Group
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
 * Doctrine Validator AirValidNoHtml
 *
 * Custom Doctrine Validator type to that field contains no html.
 * For example:
 *
 *    $this->hasColumn('something', 'string', 16, array(
 *        'airvalidhtml' => array(
 *            'display' => 'Some Thing',
 *            'message' => 'HTML is not allowed in this field.',
 *        ),
 *    ));
 *
 * @author astevenson
 * @package default
 */
class Doctrine_Validator_AirValidNoHtml extends Doctrine_Validator_Driver {


    /**
     * Validate a field value
     *
     * @param mixed   $value
     * @return boolean
     */
    public function validate($value) {
        $errs = $this->invoker->getErrorStack();

        // don't run on null values
        if (is_null($value)) {
            return true;
        }

        // check for invalid characters
        if (preg_match('/[<>&]/', $value)) {
            $errs->add(
                $this->getArg('display'),
                $this->getArg('message')
            );
        }

        return true;
    }


}
