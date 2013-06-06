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
 * Perl adaptor for PHP
 *
 * Static class that can be used to call perl subroutines from PHP.  Note that
 * all I/O from the sub must be basic types, since it must be json-encodable.
 *
 * @author rcavis
 * @package default
 */
class PerlException extends Exception {


    /**
     * Attempt to remove irrelevant exception info about the phperl layer
     *
     * @param string $perlout
     * @param int    $code
     */
    public function __construct($perlout, $code) {
        parent::__construct($perlout, $code);

        // try to get the actual message/trace
        $parts = explode(' at /', $perlout);
        if (count($parts) > 1) {
            $this->message = $parts[0];
            $this->file = '/'.trim($parts[1]);
            $this->line = -1;

            // attempt to get the actual line
            $parts = explode(' line ', $this->file);
            if (count($parts) == 2) {
                $this->file = $parts[0];
                $this->line = intval($parts[1]);
            }
        }
    }


}
