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

require_once 'AIR2_MoverException.php';

/**
 * AIR2_Mutator interface
 *
 * Interface for modifying data read by an AIR2_Reader, before it is returned
 * through its Iterator interface.  This is useful if you want to map values
 * read from a source before they are written somewhere by an AIR2_Writer.
 *
 * @author rcavis
 * @package default
 */
interface AIR2_Mutator {

    /**
     * Mutate a row of data from an AIR2_Reader
     *
     * @return array $data the mutated row data
     * @param array   $data the row data
     * @param int     $idx  the row index
     */
    public function mutate($data, $idx);

}
