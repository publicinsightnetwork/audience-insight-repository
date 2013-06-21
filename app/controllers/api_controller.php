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
 * Controller in charge of outputting all RSS feeds from air2.
 *
 * @package default
 */
class API_Controller extends Base_Controller {

    /**
     * Getting registration info
     *
     * @return void
     */
    public function register() {

        $this->load->library('session');  // for flash data on POST redirect

        $method = $_SERVER['REQUEST_METHOD'];
        $action = current_url();

        if ($method == 'GET') {
            $stash = array(
                'static_url' => $this->uri_for(''),
                'action'     => $action,
                'method'     => 'GET',
            );
            $this->load->view('api/register', $stash);
        }
        else {
            $name = $this->input->post('name');
            $email = $this->input->post('email');

            // invalid params, re-render form with msg
            if (!$name || !$email || $email == "pijdev@mpr.org") {
                $stash = array(
                    'static_url' => $this->uri_for(''),
                    'action'     => $action,
                    'method'     => 'GET',
                    'error'      => 'Must supply an email address and a name.'
                );
                $this->load->view('api/register', $stash);
                return;
            }


            $this->save($name, $email);

            // docs at http://ellislab.com/codeigniter/user-guide/libraries/email.html
            $this->load->library('email');

            // allow for configure via etc/profiles.ini
            $this->email->initialize(array('smtp_host' => 'localhost'));

            // send to support@
            $this->email->from($email, $name);
            $this->email->to(AIR2_API_KEY_EMAIL);
            $this->email->subject('Publishing API Registration Requested');
            $this->email->message("$name at $email has requested a key for the Publishing API.\n".
                "Sent from AIR2 " . AIR2_ENVIRONMENT . " server.");
            if (!$this->email->send()) {
                error_log($this->email->print_debugger());
                return false;
            }

            // reset to use again
            $this->email->clear();

            // send to requester
            $this->email->from(AIR2_SUPPORT_EMAIL, 'PIN Support');
            $this->email->to($email);
            $this->email->subject('Your PIN API Registration');
            $this->email->message("Thanks for requesting a PIN API key.\n".
                "Your request is being processed.");
            if (!$this->email->send()) {
                error_log($this->email->print_debugger());
                return false;
            }

            // redirect to avoid double post
            $this->session->set_flashdata('register', 'ok');
            redirect($this->uri_for('api/thanks'));
        }
    }



    /**
     *
     */
    public function thanks() {
        $this->load->library('session');
        if (!$this->session->flashdata('register')) {
            redirect($this->uri_for('api/register'));
            return;
        }
        $stash = array(
            'static_url' => $this->uri_for(''),
            'method'     => 'THANKS'
        );
        $this->load->view('api/register', $stash);
    }


    /**
     * Save form information
     *
     * @param unknown $name
     * @param unknown $email
     */
    protected function save($name, $email) {
        $ip_address = $this->input->server('REMOTE_ADDR');

        $api_key = new APIKey();
        $api_key->ak_contact = $name;
        $api_key->ak_email = $email;
        $api_key->ak_key = air2_generate_uuid(32);
        $api_key->save();

        $api_stat = new APIStat();
        $api_stat->APIKey = $api_key;
        $api_stat->as_ip_addr = $ip_address;
        $api_stat->save();
    }


}
