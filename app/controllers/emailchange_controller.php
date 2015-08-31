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
 * Public-facing controller for requesting email address changes.
 *
 * @package default
 */
class Emailchange_Controller extends Base_Controller {

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
            $this->email->initialize(array(
                    'smtp_host' => AIR2_SMTP_HOST,
                    'smtp_user' => AIR2_SMTP_USERNAME,
                    'smtp_pass' => AIR2_SMTP_PASSWORD,
                    'smtp_port' => AIR2_SMTP_PORT
                )
            );

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



    /**
     *
     */
    public function unsubscribe_confirm() {
        $this->load->library('session');
        $unsubbed = $this->session->flashdata('unsubscribed');
        if (!$unsubbed) {
            redirect($this->uri_for('email/unsubscribe'));
            return;
        }
        $stash = array(
            'static_url' => $this->uri_for(''),
            'email'      => $unsubbed,
            'method'     => 'THANKS'
        );
        $this->load->view('email/unsubscribe', $stash);
    }


    /**
     *
     *
     * @param unknown $payload (optional)
     */
    public function unsubscribe($payload=null) {
        $this->load->library('session');  // for flash data on POST redirect

        $method = $_SERVER['REQUEST_METHOD'];
        $action = current_url();

        if ($method == 'GET') {
            // payload is (optional) base64-encoded JSON string with email and org
            $email = null;
            $org   = null;
            if ($payload) {
                $buf = base64_decode($payload);
                if ($buf) {
                    $json = json_decode($buf);
                    if (isset($json->email)) {
                        $email = $json->email;
                    }
                    if (isset($json->org)) {
                        $org = $json->org;
                    }
                }
            }
            $organization = null;
            if ($org) {
                $organization = Doctrine::getTable('Organization')->findOneBy('org_name', $org);
            }

            $stash = array(
                'static_url' => $this->uri_for(''),
                'action'     => $action,
                'method'     => 'GET',
                'email'      => $email,
                'org'        => $organization,
            );
            $this->load->view('email/unsubscribe', $stash);
        }
        else {
            $email = $this->input->post('email');
            $org   = $this->input->post('org');

            // invalid params, re-render form with msg
            if (!$email) {
                $stash = array(
                    'static_url' => $this->uri_for(''),
                    'action'     => $action,
                    'method'     => 'GET',
                    'error'      => 'Must supply an email address.'
                );
                $this->load->view('email/unsubscribe', $stash);
                return;
            }

            // find the source
            $src_email = Doctrine::getTable('SrcEmail')->findOneBy('sem_email', strtolower($email));
            if (!$src_email) {
                // can't act. return 404 and do not reveal why to protect privacy of email
                $this->load->view('email/404');
                return;
            }

            // determine our action.
            // if this org, and the org != APM, opt out from the org.
            // if this org == APM, or no org, or all orgs, unsubscribe the email address.
            $opt_out_from = null;
            if ($org && $org != 'all') {
                $organization = Doctrine::getTable('Organization')->findOneBy('org_name', $org);
                if ($organization) {
                    if ($organization->org_id != Organization::$APMPIN_ORG_ID) {
                        $opt_out_from = $organization;
                    }
                }
            }

            $source             = $src_email->Source;
            $should_save        = false;
            $sact               = new SrcActivity();
            $sact->sact_dtim    = air2_date();
            $sact->sact_actm_id = 22;

            if ($opt_out_from) {
                // toggle the relevant src_org record
                foreach ($source->SrcOrg as $so) {
                    if ($so->so_org_id != $opt_out_from->org_id) {
                        continue;
                    }
                    $so->so_status = SrcOrg::$STATUS_OPTED_OUT;
                    $should_save = true;
                    $sact->sact_desc = 'Source unsubscribed via AIR from Org';
                    $sact->sact_ref_type = SrcActivity::$REF_TYPE_ORG;
                    $sact->sact_xid = $so->so_org_id;
                }
            }
            else {
                // toggle the relevant src_email record
                $src_email->sem_status = SrcEmail::$STATUS_UNSUBSCRIBED;
                $src_email->save();
                $should_save = true;
                $sact->sact_desc = 'Source unsubscribed via AIR';
            }

            if (!$should_save) {
                // bad org name, most likely
                $this->load->view('email/404');
                return;
            }

            $source->SrcActivity[] = $sact;
            $source->save();

            // redirect to avoid double post
            $this->session->set_flashdata('unsubscribed', $email);
            redirect($this->uri_for('email/unsubscribe-confirm'));

        }

    }


}
