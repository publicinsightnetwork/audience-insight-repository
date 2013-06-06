<?php
/**************************************************************************
 *
 *   Copyright 2013 American Public Media Group
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
class Email_Controller extends Base_Controller {

    /**
     * Request email change.
     *
     * @return void
     */
    public function change() {

        $this->load->library('session');  // for flash data on POST redirect

        $method = $_SERVER['REQUEST_METHOD'];
        $action = current_url();

        if ($method == 'GET') {
            $stash = array(
                'static_url' => $this->uri_for(''),
                'action'     => $action,
                'method'     => 'GET',
            );
            $this->load->view('email/change', $stash);
        }
        else {
            $name = $this->input->post('name');
            $before = $this->input->post('before');
            $after = $this->input->post('after');

            // invalid params, re-render form with msg
            if (!$name || !$before || !$after) {
                $stash = array(
                    'static_url' => $this->uri_for(''),
                    'action'     => $action,
                    'method'     => 'GET',
                    'error'      => 'Must supply a before and after email address and a name.'
                );
                $this->load->view('email/change', $stash);
                return;
            }

            // docs at http://ellislab.com/codeigniter/user-guide/libraries/email.html
            $this->load->library('email');

            // allow for configure via etc/profiles.ini
            $this->email->initialize(array('smtp_host' => AIR2_SMTP_HOST));

            // send to support@
            $this->email->from($after, $name);
            $this->email->to(AIR2_SUPPORT_EMAIL);
            $this->email->subject('PIN email change request');
            $this->email->message("$name at $before has requested an email change to $after\n".
                "Sent from AIR2 " . AIR2_ENVIRONMENT . " server.");
            if (!$this->email->send()) {
                error_log($this->email->print_debugger());
                return false;
            }

            // reset to use again
            $this->email->clear();

            // send to requester
            $this->email->from(AIR2_SUPPORT_EMAIL, 'PIN Support');
            $this->email->to("$before, $after");
            $this->email->subject('Public Insight Network: your email change request');
            $this->email->message("Thanks for requesting an email change for the Public Insight Network.\n".
                "Your request is being processed.");
            if (!$this->email->send()) {
                error_log($this->email->print_debugger());
                return false;
            }

            // redirect to avoid double post
            $this->session->set_flashdata('request', 'ok');
            redirect($this->uri_for('email/thanks'));
        }
    }



    /**
     *
     */
    public function thanks() {
        $this->load->library('session');
        if (!$this->session->flashdata('request')) {
            redirect($this->uri_for('email/change'));
            return;
        }
        $stash = array(
            'static_url' => $this->uri_for(''),
            'method'     => 'THANKS'
        );
        $this->load->view('email/change', $stash);
    }


}
