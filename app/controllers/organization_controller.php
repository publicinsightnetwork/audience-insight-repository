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
 * Organization Controller
 *
 * @author rcavis
 * @package default
 */
class Organization_Controller extends AIR2_HTMLController {


    /**
     * Load inline HTML
     *
     * @param type $uuid
     * @param type $base_rs
     */
    protected function show_html($uuid, $base_rs) {
        $name = $base_rs['radix']['org_name'];
        $search_query = array('q' => "org_name=$name");
        $inline = array(
            // base data
            'UUID' => $base_rs['uuid'],
            'URL'  => air2_uri_for($base_rs['path']),
            'BASE' => $base_rs,
            // search url's
            'INQSRCH'  => air2_uri_for('search/queries', $search_query),
            'SRCSRCH'  => air2_uri_for('search/active-sources', $search_query),
            // related data
            'CHILDDATA' => $this->api->query("organization/$uuid/child", array('limit' => 6, 'sort' => 'org_name asc')),
            'PRJDATA'   => $this->api->query("organization/$uuid/project", array('limit' => 10, 'sort' => 'prj_display_name asc')),
            'SRCDATA'   => $this->api->query("organization/$uuid/source", array('limit' => 5, 'sort' => 'so_cre_dtim desc')),
            'USRDATA'   => $this->api->query("organization/$uuid/user", array('limit' => 8, 'sort' => 'user_status asc, user_first_name asc')),
            'INQDATA'   => $this->api->query("organization/$uuid/inquiry", array('limit' => 5, 'sort' => 'inq_cre_dtim desc')),
            'SYSIDDATA' => $this->api->query("organization/$uuid/sysid", array('limit' => 5, 'sort' => 'osid_type desc')),
            'ACTVDATA'  => $this->api->query("organization/$uuid/activity", array('limit' => 8)),
            'OUTDATA'   => $this->api->query("organization/$uuid/outcome", array('limit' => 4)),
            'NETDATA'   => $this->api->query("organization/$uuid/network", array('limit' => 6)),
        );

        // show page
        $title = $base_rs['radix']['org_display_name'].' - '.AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'Organization', $inline);
        $this->response($data);
    }


}
