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

require_once 'AIR2_HTMLController.php';

/**
 * Saved Search Controller
 *
 * @package default
 */
class SavedSearch_Controller extends AIR2_HTMLController {


    /**
     * Perform redirect to search page
     *
     * @param string $uuid
     * @param array  $base_rs
     */
    protected function show_html($uuid, $base_rs) {
        $ssearch = $base_rs['radix']['ssearch_params'];
        $json = json_decode($ssearch, true);
        if ($json) {
            $ssearch = $json['idx'] . '?' . $json['params'];
        }
        $uri = $this->uri_for("search/$ssearch");
        redirect($uri);
    }


}
