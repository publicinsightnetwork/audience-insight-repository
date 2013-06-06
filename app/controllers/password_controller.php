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

require_once 'Password_Reset_Controller.php';
require_once 'PINPassword.php';

/**
 * Password_Controller:
 *
 * AIR2 implementation of the abstract "Password_Reset_Controller" class. The
 * routes file must designate that 'password/([\w]+)' gets redirected to
 * 'password/password_change_page/$1' for this to work properly.
 *
 * @author rcavis
 * @package default
 */
class Password_Controller extends Password_Reset_Controller {

    /* reCAPTCHA configuration (http://recaptcha.net/api/getkey?app=php) */
    protected $domain_name = 'air2.O';
    protected $public_key = '6LfB6boSAAAAAMWlhFBBOKDwIswY0oSevs8gZ9wJ';
    protected $private_key = '6LfB6boSAAAAAIKViVbqe9FZW_Q-C-fLVbwAsUli';

    /* doctrine configuration */
    protected $doctrine_model_name   = 'PasswordReset';
    protected $doctrine_token_col    = 'pwr_uuid';
    protected $doctrine_expire_col   = 'pwr_expiration_dtim';
    protected $doctrine_login_pk_col = 'pwr_user_id';

    /* other configuration */
    //protected $url_expire_duration = 86400; //in seconds
    //protected $url_dtim_format = 'Y-m-d H:i:s';

    /* error message configuration */
    //protected $form_missing_field = 'Fill in all required fields.';
    //protected $form_password_match = 'Passwords did not match!';
    protected $form_captcha_error = 'The captcha text entered didn\'t match. Please try again.';
    //protected $form_cred_error = 'Unable to validate credentials.';
    //protected $form_reset_url_error = 'There was a problem with your request. Contact an administrator.';
    //protected $form_pw_change_error = 'There was a problem with setting your new password. Sorry.';

    /* private variables */
    private $uem_address;
    private $user_id;


    /**
     * Load database connection in constructor
     */
    public function __construct() {
        parent::__construct();
        AIR2_DBManager::init();
    }


    /**
     * Abstract method implementation
     *
     * @param string  $action
     * @param string  $captcha_html
     * @param string  $err_msg      (optional)
     */
    protected function show_reset_request_form($action, $captcha_html, $err_msg=null) {
        $stash = array(
            'static_url' => site_url(),
            'action'     => $action,
            'captcha'    => $captcha_html,
            'errors'     => $err_msg,
        );
        $this->load->view('password/reset_request', $stash);
    }


    /**
     * Abstract method implementation
     *
     * @param string  $email
     * @param boolean $success
     */
    protected function show_email_sent_page($email, $success) {
        $header = $success ? 'Success!' : 'Error!';
        $body = $success ?
            "An email containing a link to change your password was sent to $email." :
            "There was a problem sending an email to $email.";
        $stash = array(
            'static_url' => site_url(),
            'email_header'     => $header,
            'email_content'    => $body,
            'email_success'    => $success,
        );
        $this->load->view('password/reset_request', $stash);
    }


    /**
     * Abstract method implementation
     *
     * @param string  $action
     * @param string  $captcha_html
     * @param string  $err_msg      (optional)
     */
    protected function show_change_form($action, $captcha_html, $err_msg=null) {
        $stash = array(
            'static_url' => site_url(),
            'action'     => $action,
            'captcha'    => $captcha_html,
            'errors'     => $err_msg,
        );
        $this->load->view('password/change_form', $stash);
    }


    /**
     * Abstract method implementation
     */
    protected function show_password_changed_page() {
        $stash = array(
            'static_url' => site_url(),
            'login_url'  => base_url() . 'login',
        );
        $this->load->view('password/change_form', $stash);
        mail($this->uem_address, 'AIR2 Password Successfully Changed!',
            "Your AIR2 password has been changed.  Log in at ".base_url()."login");
    }


    /**
     * Abstract method implementation
     *
     * @param string  $login_name
     * @return array user credentials
     */
    protected function get_login_credentials($login_name) {
        // first search for a username on the user table
        $usr = Doctrine::getTable('User')->findOneBy('user_username', $login_name);
        if (!$usr) {
            // attempt to search by email address (user_email_address table)
            $em = Doctrine::getTable('UserEmailAddress')->findOneBy('uem_address', $login_name);
            if ($em) {
                $this->user_id = $em->uem_user_id;
                $this->uem_address = $em->uem_address;
            }
        }
        else {
            $this->user_id = $usr->user_id;
            foreach ($usr->UserEmailAddress as $add) {
                if ($add->uem_primary_flag) {
                    $this->uem_address = $add->uem_address;
                    break;
                }
            }
            if (!$this->uem_address && count($usr->UserEmailAddress) > 0) {
                $this->uem_address = $usr->UserEmailAddress[0]->uem_address;
            }
            if (!$this->uem_address) {
                // FATAL ERROR! Unable to find any email address
                echo '<h2>Error!</h2><strong>No email address is set for your account!';
                echo 'Please contact a system administrator.</strong>';
                exit(0);
            }
        }

        if ($this->user_id && $this->uem_address) {
            return array($this->user_id, $this->uem_address);
        }
        else {
            return false;
        }
    }


    /**
     * Abstract method implementation
     *
     * @param string  $email
     * @param string  $url
     * @return boolean success of sending email
     */
    protected function send_email($email, $url) {
        //echo "DEBUG: SKIPPING EMAIL TO $email, containing url: <a href='$url'>$url</a><br/><br/>";
        //return true;
        return mail($email, 'Change Password Link', "To change password, go to $url");
    }


    /**
     * Abstract method implementation
     *
     * @return string
     */
    protected function get_url_token() {
        return air2_generate_uuid(32);
    }


    /**
     * Abstract method implementation
     *
     * @param int     $login_id
     * @param string  $password
     * @return boolean success of changing password
     */
    protected function change_password($login_id, $password) {
        $usr = Doctrine::getTable('User')->find($login_id);
        $usr->user_password = $password;
        try {
            $usr->save();
            return true;
        }


        catch (Exception $e) {
            $this->form_pw_change_error = "$e";
            return false;
        }


    }


    /**
     *
     *
     * @param unknown $login_name
     * @param unknown $password
     * @return unknown
     */
    protected function validate_password($login_name, $password) {
        $pinpass = new PINPassword(array(
                'username' => $login_name,
                'phrase' => $password,
            )
        );
        if (! $pinpass->validate()) {
            $this->form_validation_error = 'Password ' . $pinpass->get_error();
            return false;
        }
        return true;
    }


    /**
     * Custom "link expired" 404 page.
     *
     * @param boolean $page_existed
     */
    protected function show_404($page_existed=false) {
        $this->load->view('password/link_expired', array(
            'static_url' => site_url(),
            'reset_url'  => site_url() . 'password',
        ));
    }


}
