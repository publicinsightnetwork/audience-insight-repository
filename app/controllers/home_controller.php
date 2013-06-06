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
 * Home Controller
 *
 * @author rcavis
 * @package default
 */
class Home_Controller extends AIR2_HTMLController {


    /**
     * Since there's no UUID for a home controller, just override index
     */
    public function index() {
        // only html
        if ($this->view != 'html') {
            show_error('Only HTML view available', 415);
        }

        // projects
        $args = array(
            'limit' => 8,
            'sort' => 'prj_cre_dtim desc, prj_display_name asc',
        );
        $projects = $this->api->query('project', $args);

        // users
        $args = array(
            'limit' => 5,
            'sort' => 'user_cre_dtim desc',
            'status' => 'AP',
            'type'   => 'A',
        );
        $myhome = $this->airuser->get_user()->get_home_org_name();
        if ($myhome) {
            $args['sort_home'] = $myhome;
        }
        $users = $this->api->query('user', $args);

        // inquiries
        $args = array('limit' => 6, 'sort' => 'inq_cre_dtim desc');
        $inqs = $this->api->query('inquiry', $args);

        // counts
        $usrcount = $users['meta']['total'];
        $orgs = $this->api->query('organization', array('limit' => 1));
        $orgcount = $orgs['meta']['total'];

        // inline data
        $inline = array(
            // related data
            'USERDATA'  => $users,
            'PROJDATA'  => $projects,
            'INQDATA'   => $inqs,
            'SSDATA'    => $this->api->query("savedsearch", array('limit' => 5)),
            'IMPDATA'   => $this->api->query("tank", array('limit' => 5, 'type' => Tank::$TYPE_CSV)),
            'ALERTDATA' => $this->api->query("alert", array('limit' => 5)),
            // some counts
            'USRCOUNT'  => $usrcount,
            'ORGCOUNT'  => $orgcount,
        );

        // show page
        $title = 'Home - '.AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'Home', $inline);
        $this->response($data);
    }


}
