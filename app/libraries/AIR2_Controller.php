<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
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

require_once 'rframe/AIRAPI.php';
require_once 'Base_Controller.php';
require_once APPPATH . '/libraries/AirUser.php';

/**
 * AIR2 Application Controller Base Class (overrides default CI controller)
 *
 * This class object is the parent class to every controller used in AIR2. It
 * implements security, as well as encapsulating any variables passed in
 * with the client request.
 *
 * @author rcavis
 * @package default
 */
class AIR2_Controller extends Base_Controller {

    // api
    protected $api;

    // supported browsers (name => min-version)
    protected $browsers = array(
        '/internet explorer/i' => 999,  // no more IE support -- see redmine #6512
        '/firefox/i'           => 3,
        '/safari/i'            => 500, //safari has strange version numbers
        '/chrome/i'            => 1,
        '/.*/'                  => null, //just let everything else through
    );

    /**
     * Currently logged in user.
     *
     * @var User
     **/
    protected $user = null;

    /**
     * Constructor.
     *
     * @return void
     **/
    public function __construct() {
        parent::__construct();

    }

    /**
     * begin() checks for security (authentication) using AirUser library.
     *
     * @method begin()
     */
    public function begin() {
        parent::begin();

        $this->load->library('AirUser');
        $this->load->library('AirHtml');

        // load recent view lib
        $u = $this->airuser->get_user();
        if ($u) {
            $this->load->library('AirRecent', array('user' => $u));
        }

        // Keep current user for later.
        $this->user = $u;

        // load API
        $u = $this->airuser->get_user();
        if ($u) {
            $this->api = new AIRAPI($u);
        }

        $this->_init_security();

        // supported browsers
        if ($this->view == 'html') {
            $supported = false;
            $this->load->library('user_agent');
            $bro = $this->agent->browser();
            $ver = $this->agent->version();

            // compare the leading version number
            try {
                $leading = intval(array_shift(explode('.', $ver)));
                foreach ($this->browsers as $regex => $num) {
                    if (preg_match($regex, $bro)) {
                        if (is_null($num) || $leading >= $num) {
                            $supported = true;
                        }
                        break;
                    }
                }
            }
            catch (Exception $e) {
                $supported = true; //Just let them through
            }

            // die now if unsupported
            if (!$supported) {
                $this->airoutput->view = 'unsupported';
                $this->airoutput->write();
                exit;
            }
        }

    }

    /**
     * Write out a response
     *
     * @param array   $data        (optional)
     * @param int     $status_code (optional)
     */
    protected function response($data=array(), $status_code=200) {
        if (empty($data)) {
            show_404();
        }

        // write
        $this->airoutput->write($data, $status_code);
    }

    /**
     * initialize security for this controller
     *
     * This function determines what (if any) security the user has and
     * encapsulates it in the $AIR2User class variable.  Will return a
     * login page and exit if the user cannot be authenticated.
     *
     * @access private
     * @return void
     */
    private function _init_security() {
        // check if the credentials were good
        if ( !$this->airuser->has_valid_tkt() || !$this->airuser->get_user() ) {
            // user not authenticated
            $this_uri = current_url() . '?' . $this->input->server('QUERY_STRING');
            //Carper::carp("Permission denied for $this_uri");
            $uri = $this->uri_for('login', array('back' => $this_uri));
            //echo "Location: $uri\n";
            redirect($uri);
            exit(0);
        }

        // ok credentials. does the user have min authz?
        $air2_user = $this->airuser->get_user();

        // skip authz check if SYSTEM or TEST user
        // TODO the TEST type really ought to be tested here as well
        // but that will require audit of existing unit tests.
        if ($air2_user['user_type'] != 'S' && $air2_user['user_type'] != 'T') {
            $cum_authz = 0;
            foreach ($air2_user->get_authz() as $org_id=>$bitmask) {
                $cum_authz += $bitmask;
            }

            if ($cum_authz == 0) {
                Carper::carp("authn ok for " . $air2_user->user_username . " type=".$air2_user['user_type']. " but no authz");
                show_error('Insufficient authz', 403);
            }
        }

        //set global remote user ID and TYPE (for upd/cre user stamps)
        define('AIR2_REMOTE_USER_ID', $this->airuser->get_id());
        define('AIR2_REMOTE_USER_TYPE', $air2_user['user_type']);

        // enable activity logging
        // TODO: where else can this go? Would it be better to default to true?
        AIR2Logger::$ENABLE_LOGGING = true;

        // authn ok
        return true;
    }

    /**
     * Request Bin data inline as we're returning HTML, so the Bins display
     * without an ajax call.  The "bin-state" cookie must request that this
     * data be sent.  The cookie has the following json-encoded structure:
     * AIR2_BIN_STATE_CK:
     *   view: (which view is displayed ... 'sm', 'lg' or 'si')
     *   params: (the GET params to load with)
     *   uuid: (the uuid of the bin --- only used in view = 'si')
     *   open: (true or false, whether the drawer is open)
     *
     * @return string 'false' or the json-encoded bin/contents list
     */
    public function get_bin_data() {
        $ck = isset($_COOKIE[AIR2_BIN_STATE_CK]) ? $_COOKIE[AIR2_BIN_STATE_CK] : null;
        if (!$ck) return 'false';
        $json = json_decode($ck, true);

        // get the remote user
        $this_user = $this->airuser->get_user();

        // sanity check!
        if (!$json || !isset($json['params']) || !is_array($json['params'])
            || !isset($json['view'])) {
            return 'false';
        }
        if ($json['view'] != 'si' && isset($json['uuid'])) {
            return 'false';
        }
        if ($json['view'] == 'si' && !isset($json['uuid'])) {
            return 'false';
        }

        // query for resources
        $path = ($json['view'] == 'si') ? "bin/{$json['uuid']}/source" : 'bin';
        $rs = $this->api->query($path, $json['params']);

        // must be OKAY
        if ($rs['code'] != AIRAPI::OKAY) return 'false';
        return json_encode($rs);
    }


    /**
     * Returns an inline single-bin object, when the bin view being displayed is
     * 'si' (single), and 'uuid' is set.
     *
     * @return string 'false' or the json-encoded single bin
     */
    public function get_bin_base() {
        $ck = isset($_COOKIE[AIR2_BIN_STATE_CK]) ? $_COOKIE[AIR2_BIN_STATE_CK] : null;
        if (!$ck) return 'false';
        $json = json_decode($ck, true);

        // sanity check!
        if (!$json || !isset($json['view']) || $json['view'] != 'si' || !isset($json['uuid'])) {
            return 'false';
        }

        // fetch resource
        $rs = $this->api->fetch("bin/{$json['uuid']}");

        // must be OKAY
        if ($rs['code'] != AIRAPI::OKAY) return 'false';
        return json_encode($rs);
    }


    /**
     * Delete the current bin cookie
     */
    public function delete_bin_cookie() {
        setcookie(AIR2_BIN_STATE_CK, null, time()-3600, '/');
    }


    /**
     * Returns the authz-action constants, as loaded from actions.ini
     */
    public function get_authz_action_constants() {
        $consts = array();
        $all_of_em = get_defined_constants(true);
        foreach ($all_of_em['user'] as $name => $val) {
            if (substr($name, 0, 7) == 'ACTION_') $consts[$name] = $val;
            elseif (substr($name, 0, 16) == 'AIR2_AUTHZ_ROLE_') $consts[$name] = $val;
        }
        return $consts;
    }


}
