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
 * Email Controller
 *
 * @author rcavis
 * @package default
 */
class Email_Controller extends AIR2_HTMLController {


    /**
     * Load inline HTML
     *
     * @param type $uuid
     * @param type $base_rs
     */
    protected function show_html($uuid, $base_rs) {
        $user = $this->user->user_uuid;
        $inline = array(
            // base data
            'UUID' => $base_rs['uuid'],
            'URL'  => air2_uri_for($base_rs['path']),
            'BASE' => $base_rs,
            // related data
            'SIGDATA' => $this->api->query("user/$user/signature", array('limit' => 30, 'sort' => 'usig_upd_dtim desc')),
            'INQDATA' => $this->api->query("email/$uuid/inquiry", array('limit' => 8, 'sort' => 'einq_cre_dtim desc')),
            'EXPDATA' => $this->api->fetch("email/$uuid/export"),
            // users primary email
            'USEREMAIL' => $this->user->get_primary_email(),
        );

        // show page
        $title = $base_rs['radix']['email_campaign_name'].' - '.AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'Email', $inline);
        $this->response($data);
    }


    /**
     *
     * Load inline HTML for the "index" page
     *
     * @param array $index_rs
     */
    protected function index_html($index_rs) {
        $inline = array(
            // base data
            'URL'    => air2_uri_for($index_rs['path']),
            'BASE'   => $index_rs,
        );

        // show page
        $title = 'Search Emails - '.AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'EmailSearch', $inline);
        $this->response($data);
    }


}
