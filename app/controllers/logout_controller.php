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


/**
 * Logout Controller
 *
 * Logs an authenticated user out of AIR2, deleting their tkt and redirecting.
 *
 * @author pkarman
 * @package default
 */
class Logout_Controller extends AIR2_Controller {

    /**
     * Override begin() to prevent AIR2_Controller authz from occurring
     */
    public function begin() {
        $this->load->library('AirUser');
        $this->load->library('AirHtml');
    }


    /**
     * Delete tkt and redirect
     */
    public function index() {
        $this->airuser->delete_tkt();
        $this->delete_bin_cookie();

        $login_uri = $this->uri_for('login');

        // special case.
        // if we are configured to trust the PIN SSO tkt (auth_tkt)
        // then check for it and if present, do not redirect to login
        // or else we effectively login again immediately.
        if (AIR2_PIN_SSO_TRUST) {
            $tkt = $this->input->cookie(AIR2_PIN_SSO_TKT);
            if (!$tkt) {
                $tkt = $this->input->get_post(AIR2_PIN_SSO_TKT);
            }
            if ($tkt) {
                $this->load->view('sso_logout.php', array(
                        'c'             => $this,
                        'sso_logout'    => AIR2_PIN_SSO_LOGOUT,
                        'static_url'    => site_url(),
                    )
                );
                return;
            }
        }
        redirect($login_uri);  // TODO better?
    }


}
