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
 * User Controller
 *
 * @author rcavis
 * @package default
 */
class User_Controller extends AIR2_HTMLController {


    /**
     * Load inline HTML
     *
     * @param string  $uuid
     * @param array   $base_rs
     */
    protected function show_html($uuid, $base_rs) {
        // use local url unless this AIR instance is on PINSSO
        $pwdurl = air2_uri_for('password');
        $is_sys = $base_rs['radix']['user_type'] == User::$TYPE_SYSTEM;
        if (!$is_sys && AIR2_PIN_SSO_TRUST) {
            $pwdurl = 'https://www.publicinsightnetwork.org/authn/password';
        }

        // inline user data
        $inline = array(
            // base data
            'UUID' => $base_rs['uuid'],
            'URL'  => air2_uri_for($base_rs['path']),
            'BASE' => $base_rs,
            // related data
            'ORGDATA'  => $this->api->query("user/$uuid/organization", array('limit' => 5, 'sort' => 'uo_home_flag desc')),
            'ACTDATA'  => $this->api->query("user/$uuid/activity", array('limit' => 12)),
            'NETDATA'  => $this->api->query("user/$uuid/network", array('limit' => 6)),
            // password reset url
            'PWDURL'   => $pwdurl,
        );

        // show page
        $uname = $base_rs['radix']['user_username'];
        $first = $base_rs['radix']['user_first_name'];
        $last  = $base_rs['radix']['user_last_name'];
        $name  = ($first && $last) ? "$first $last" : $uname;
        $title = "$name - ".AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'User', $inline);
        $this->response($data);
    }


}
