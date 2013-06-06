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
 * Import Controller
 *
 * @author rcavis
 * @package default
 */
class Import_Controller extends AIR2_HTMLController {

    // this is actually a view on the 'tank' resource
    protected $alt_resource_name = 'tank';


    /**
     * Load inline HTML
     *
     * @param string $uuid
     * @param array  $base_rs
     */
    protected function show_html($uuid, $base_rs) {
        // load radix from CSV-api, if this is a CSV file
        $csv_rs = false;
        if ($base_rs['radix']['tank_type'] == Tank::$TYPE_CSV) {
            $csv_rs = $this->api->fetch("csv/$uuid");
            $base_rs['radix'] = $csv_rs['radix'];
        }

        $inline = array(
            // base data
            'UUID' => $base_rs['uuid'],
            'URL'  => air2_uri_for($base_rs['path']),
            'BASE' => $base_rs,
            // related data
            'TSRCDATA'  => $this->api->query("tank/$uuid/source", array('limit' => 25, 'sort' => 'status_sort asc', 'src_username asc')),
            'ORGDATA'   => $this->api->query("tank/$uuid/organization", array('limit' => 0, 'sort' => 'org_display_name asc')),
            'ACTDATA'   => $this->api->query("tank/$uuid/activity", array('limit' => 0, 'sort' => 'tact_dtim desc')),
            // optional csv data
            'CSVDATA' => $csv_rs,
        );

        // show page
        $title = $base_rs['radix']['tank_name'].' - '.AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'Import', $inline);
        $this->response($data);
    }


}
