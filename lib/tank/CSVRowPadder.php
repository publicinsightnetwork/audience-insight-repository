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

require_once 'mover/AIR2_Mutator.php';

/**
 * AIR2 CSVRowPadder
 *
 * When Excel saves a file as CSV, it tends to truncate the columns off the end
 * of some rows.  (http://support.microsoft.com/?kbid=77295).  Since all of the
 * readers/writers/validators expect all the rows to have the same width,
 * this mutator will pad rows up to a certain width.
 *
 * @author rcavis
 * @package default
 */
class CSVRowPadder implements AIR2_Mutator {

    /* width to pad up to */
    protected $width;

    /**
     * Constructor
     *
     * @param int     $width
     */
    public function __construct($width) {
        $this->width = $width;
    }


    /**
     * Pad a row up to the correct width
     *
     * @param array   $data the row data
     * @param int     $idx  the row index
     * @return array $data the mutated row data
     */
    public function mutate($data, $idx) {
        return array_pad($data, $this->width, '');
    }


}
