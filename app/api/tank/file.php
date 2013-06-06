<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
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

require_once 'rframe/AIRAPI_FileProxy.php';

/**
 * Tank/File API
 *
 * This *SPECIAL* resource proxies the uploaded file for a CSV-type tank.
 *
 * @author rcavis
 * @package default
 */
class AAPI_Tank_File extends AIRAPI_FileProxy {


    /**
     * Access file from 'query' url
     *
     * @return array $data
     */
    protected function file_query() {
        // sanity
        if ($this->parent_rec->tank_type != Tank::$TYPE_CSV) {
            return false;
        }
        $path = $this->parent_rec->get_file_path();
        if (!file_exists($path)) {
            return false;
        }

        // return file-descriptors
        return array(
            'path' => $path,
            'name' => $this->parent_rec->tank_name,
            'size' => filesize($path),
            'type' => 'application/csv',
        );
    }


}
