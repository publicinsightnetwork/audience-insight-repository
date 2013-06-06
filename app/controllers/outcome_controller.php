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
 * Outcome Controller
 *
 * @author rcavis
 * @package default
 */
class Outcome_Controller extends AIR2_HTMLController {


    /**
     * Load inline HTML
     *
     * @param type $uuid
     * @param type $base_rs
     */
    protected function show_html($uuid, $base_rs) {
        $inline = array(
            // base data
            'UUID' => $base_rs['uuid'],
            'URL'  => air2_uri_for($base_rs['path']),
            'BASE' => $base_rs,
            // related data
            'SRCDATA' => $this->api->query("outcome/$uuid/source",  array('limit' => 8)),
            'PRJDATA' => $this->api->query("outcome/$uuid/project", array('limit' => 5)),
            'INQDATA' => $this->api->query("outcome/$uuid/inquiry", array('limit' => 5)),
        );

        // show page
        $title = $base_rs['radix']['out_headline'].' - '.AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'Outcome', $inline);
        $this->response($data);
    }


}
