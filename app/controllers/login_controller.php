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

// for PIN SSO delegation
require_once 'Search_Proxy.php';

/**
 * Login Controller
 *
 * Handle logins for AIR2, displaying the login page and authenticating
 * usernames and passwords.
 *
 * @author pkarman
 * @package default
 */


class Login_Controller extends AIR2_Controller {

    /**
     * Override begin() to prevent AIR2_Controller authz from occurring
     */
    public function begin() {
        $this->load->library('AirUser');
        $this->load->library('AirHtml');

        $this->method = $this->router->http_method;
        $this->view = $this->router->http_view;
        $this->decode_input($this->method);
    }


    /**
     * Loads login view and authenticate users
     *
     * we do explicit load->view calls here because the login screen is
     * independent of the rest of the View architecture.
     */
    public function index() {
        // redirect to original request, or home page
        $back = $this->input->get_post('back');
        if (!isset($back) || !strlen($back)) {
            $back = site_url('');
        }

        // admin allows overriding PIN SSO
        $admin = false;
        if (isset($this->input_all['admin']) && $this->input_all['admin']) {
            $admin = true;
        }
        if (isset($_GET['admin']) && $_GET['admin']) {
            $admin = true;
        }

        // create stash
        $stash = array(
            'static_url' => site_url(),
            'back'       => $back,
            'c'          => $this,
            'admin'      => $admin,
        );

        // GET requests show a login form
        if ($this->method == 'GET') {

            // special case.
            // if we are configured to trust the PIN SSO tkt (auth_tkt)
            // then check for it and use its "sso" data value
            // as the AIR2 username
            if (AIR2_PIN_SSO_TRUST && !$admin) {
                $tkt = $this->input->cookie(AIR2_PIN_SSO_TKT);
                if (!$tkt) {
                    $tkt = $this->input->get_post(AIR2_PIN_SSO_TKT);
                }
                if ($tkt) {
                    $at = new Apache_AuthTkt(array(
                            'conf'          => AIR2_PIN_SSO_CONFIG,
                            'encrypt_data'  => false,
                        )
                    );
                    //Carper::carp("got auth_tkt for trust pin sso");
                    if ($at->validate_ticket($tkt)) {
                        $tkt_info = $at->parse_ticket($tkt);
                        $tkt_data = json_decode($tkt_info['data'], true);
                        if (isset($tkt_data['sso'])) {
                            $username = $tkt_data['sso'];
                            $user = $this->_fetch_user($username);
                            if ($user) {

                                // trust prior authentication. create the AIR2 tkt.
                                $this->airuser->create_tkt($user, true, true);
                                $user->user_login_dtim = air2_date();
                                $user->save();
                                //echo "Location: $back\n";
                                redirect($back);
                            }
                            else {
                                Carper::carp("Invalid user in tkt");
                                redirect(AIR2_PIN_SSO_URL . '?back=' . $back);
                            }
                        }
                        else {
                            Carper::carp("Missing sso param in tkt");
                            redirect(AIR2_PIN_SSO_URL . '?back=' . $back);
                        }
                    }
                    else {
                        Carper::carp("Invalid tkt");
                        redirect(AIR2_PIN_SSO_URL . '?back=' . $back);
                    }

                }
                else {
                    // no PIN tkt; redirect to PIN login
                    Carper::carp("No PIN SSO tkt");
                    redirect(AIR2_PIN_SSO_URL . '?back=' . $back);
                }
            }

            // print form
            $this->load->view('login', $stash);
        }

        // POST requests attempt to authenticate
        elseif ($this->method == 'POST') {
            if (isset($_SERVER['HTTP_ORIGIN'])) {
                header('Access-Control-Allow-Origin: ' . $_SERVER['HTTP_ORIGIN']); // allow external
            }
            $uname = isset($this->input_all['username']) ? $this->input_all['username'] : null;

            // #9505 - xss-filter messes up passwords, so get raw input
            $pwd = isset($_POST['password']) ? $_POST['password'] : null;

            // didn't enter username or password
            if (!$uname || !$pwd || strlen($uname) < 1 || strlen($pwd) < 1) {
                if ($this->view == "json") {
                    header('X-AIR2: authentication failed', false, 400);
                    $resp = array('success' => false, 'message' => 'invalid request');
                    print json_encode($resp);
                }
                elseif ($this->view == "xml") {
                    header('X-AIR2: authentication failed', false, 400);
                    // TODO use 'xml' view
                    print "<air2><success>false</success><message>invalid request</message></air2>";
                }
                else {
                    $stash['errormsg'] = 'You must enter both a username and password';
                    $this->load->view('login', $stash);
                }
                return;
            }

            // bad username
            $user = $this->_fetch_user($uname);
            if (!$user || !$user->exists()) {
                if ($this->view == "json") {
                    header('X-AIR2: authentication failed', false, 401);
                    $resp = array('success' => false, 'message' => 'authentication failed');
                    print json_encode($resp);
                    return;
                }
                elseif ($this->view == "xml") {
                    header('X-AIR2: authentication failed', false, 401);
                    // TODO use 'xml' view
                    print "<air2><success>false</success><message>authentication failed</message></air2>";
                    return;
                }
                else {
                    $stash['errormsg'] = 'The information you entered does not match an active account';
                    $this->load->view('login', $stash);
                    return;
                }
            }

            // delegate to PIN SSO?
            $pw_ok = false;
            // the !$admin means we avoid infinite loop with the SSO service,
            // which just points back here.
            if (AIR2_PIN_SSO_TRUST && !$admin) {
                $pw_ok = $this->check_pin_sso($uname, $pwd);
            }
            else {
                $pw_ok = $user->check_password($pwd);
            }

            // bad password
            if (!$pw_ok) {
                if ($this->view == "json") {
                    header('X-AIR2: authentication failed', false, 401);
                    $resp = array('success' => false, 'message' => 'authentication failed');
                    print json_encode($resp);
                    return;
                }
                elseif ($this->view == "xml") {
                    header('X-AIR2: authentication failed', false, 401);
                    // TODO use 'xml' view
                    print "<air2><success>false</success><message>authentication failed</message></air2>";
                    return;
                }
                else {
                    $stash['errormsg'] = 'The information you entered does not match an active account';
                    $this->load->view('login', $stash); //TODO -- form error msg
                    return;
                }
            }

            // authenticated ok. create the tkt.
            $tkt = $this->airuser->create_tkt($user, true, true);
            $user->user_login_dtim = air2_date();
            $user->save();

            // non-html response does not redirect
            if ($this->view == "json") {
                $tkt['success'] = true;
                print json_encode($tkt);
                return;
            }
            elseif ($this->view == "xml") {
                header('X-AIR2: authentication failed', false, 401);
                // TODO use 'xml' view
                print "<air2><success>true</success><air2_tkt>".$tkt['air2_tkt']."</air2_tkt></air2>";
                return;
            }
            else {
                redirect($back);
            }
        }
    }


    /**
     * Does remote HTTP request to PIN SSO service to check $password.
     *
     * @param string  $username
     * @param string  $password
     * @return boolean
     */
    private function check_pin_sso($username, $password) {
        $proxy = new Search_Proxy(array(
                'url'           =>  AIR2_PIN_SSO_AUTH,
                'cookie_name'   =>  AIR2_PIN_SSO_TKT,
                'params'        => array('username'=>$username, 'password'=>$password, ),
            )
        );
        $response = $proxy->response();
        //Carper::carp(var_export($response, true));
        if ($response['response']['http_code'] != 200) {
            return false;
        }
        return true;
    }


    /**
     * Helper function to fetch a User
     *
     * @param string  $username
     * @return User
     */
    private function _fetch_user($username) {
        // get user from DB
        $user = AIR2_Query::create()
        ->from('User u')
        ->where('u.user_username = ?', $username)
        ->andWhere('u.user_status != ?', User::$STATUS_INACTIVE)
        ->leftJoin('u.UserOrg o')
        ->leftJoin('o.AdminRole a')
        ->fetchOne();
        return $user;
    }


}
