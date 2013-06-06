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
 * Directory Controller
 *
 * @author rcavis
 * @package default
 */
class Directory_Controller extends AIR2_HTMLController {


    /**
     * Since there's no UUID for the directory page, just override index
     */
    function index() {
        // only html
        if ($this->view != 'html') {
            show_error('Only HTML view available', 415);
        }

        // users directory (flat)
        $args = array(
            'limit'  => 15,
            'sort'   => 'org_display_name asc,user_last_name asc,user_first_name asc',
            'status' => 'AP',
            'type'   => 'A',
        );
        $users = $this->api->query('user', $args);
        $params = array('status' => 'AP', 'type' => 'A');

        // organizations directory (tree)
        $args = array(
            'limit'  => 0, //no limit
            'sort'   => 'org_display_name asc',
        );
        $orgs = $this->api->query('orgtree', $args);

        // 5 newest users
        $new_users = $this->api->query('user', array('limit' => 5, 'sort' => 'user_cre_dtim desc'));

        // 5 newest orgs
        $new_orgs = $this->api->query('organization', array('limit' => 5, 'sort' => 'org_cre_dtim desc'));

        // super-secret PIN-manager only view!
        $o = Doctrine::getTable('Organization')->find(Organization::$GLOBALPIN_ORG_ID);
        $pinmanage = $o->user_may_manage($this->airuser->get_user());

        // inline data
        $inline = array(
            'URL'      => air2_uri_for('/directory'),
            'PINMNG'   => $pinmanage,
            // related data
            'USERDIR'  => $users,
            'UPARAMS'  => $params,
            'ORGDIR'   => $orgs,
            'USERNEW'  => $new_users,
            'ORGNEW'   => $new_orgs,
        );

        // show page
        $title = 'Directory - '.AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'Directory', $inline);
        $this->response($data);
    }


}
