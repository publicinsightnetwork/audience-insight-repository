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

require_once 'Apache_AuthTkt.php';

/**
 * AIR2 Secure User Tkt
 *
 * This class encapsulates user security/credentials for the AIR system. This
 * is stored in a 'tkt' (ticket), which is essentially an encrypted cookie.
 *
 * @author rcavis
 * @package default
 */
class AirUser {
    /* Default time (in seconds) before a cookie expires */
    private static $COOKIE_EXPIRE_TIME = 14400; // 4 hours matches PIN SSO

    /* Encoding to use for digest */
    private static $DIGEST_TYPE = 'md5';

    private $cookie = AIR2_AUTH_TKT_NAME;
    private $auth_tkt = NULL; // ticket object
    private $tkt_info = NULL; // array of values in the ticket
    private $tkt_is_valid = false;
    private $tkt_data = array(); // decoded tkt data
    private $air2_user = NULL;

    /**
     * Constructor
     *
     * Sets up user credentials from the users tkt (or lack of)
     */
    public function __construct() {

        $this->auth_tkt = new Apache_AuthTkt(array(
                'conf'          => AIR2_AUTH_TKT_CONFIG_FILE,
                'encrypt_data'  => true,
            )
        );

        $authcook = null;
        if (isset($_COOKIE[$this->cookie])) {
            $authcook = $_COOKIE[$this->cookie];
        }
        elseif (isset($_GET[$this->cookie])) {
            $authcook = $_GET[$this->cookie];
            unset($_GET[$this->cookie]);
        }
        elseif (isset($_POST[$this->cookie])) {
            $authcook = $_POST[$this->cookie];
            unset($_POST[$this->cookie]);
        }
        else {
            $this->tkt_is_valid = false;
            return;
        }

        if (isset($authcook)) {
            // check for a valid ticket
            $this->tkt_info = $this->auth_tkt->validate_ticket($authcook);
            if ($this->tkt_info) {
                // ticket decrypted ok --- check the internal timestamp to see if it's expired
                $sec_rem = ($this->tkt_info['ts'] + self::$COOKIE_EXPIRE_TIME) - time();
                if ($sec_rem > 0) {
                    $this->tkt_is_valid = true;
                    $this->tkt_data = json_decode($this->tkt_info['data'], true);
                    // keep-alive on the cookie, so active sessions do not expire
                    // Trac #2418
                    if (isset($this->tkt_info['ts'])) unset($this->tkt_info['ts']);
                    $this->refresh_tkt();
                }
                else {
                    $this->delete_tkt();
                }
            }
        }
        else {
            $this->tkt_is_valid = false;
        }
    }


    /**
     * Check for a valid ticket
     *
     * @access public
     * @return bool whether the users tkt is valid or not
     */
    public function has_valid_tkt() {
        return $this->tkt_is_valid;
    }


    /**
     * Creates a new (valid) ticket for a user
     *
     * @param array   $user_obj
     * @param boolean $setck              (optional) false to skip setting the cookie
     * @param boolean $use_explicit_authz (optional) true to set authz with get_explicit_authz()
     * @return void
     */
    public function create_tkt($user_obj, $setck=true, $use_explicit_authz=false) {
        $this->tkt_data['user'] = array(
            'type'         => $user_obj['user_type'],
            'home_org'     => $user_obj->get_home_org_name(),
        );

        if ($use_explicit_authz) {
            $this->set_authz( $user_obj->get_explicit_authz() );
        }
        else {
            $this->set_authz($user_obj->get_authz());
        }

        $tkt = $this->get_tkt($user_obj['user_username'], $user_obj['user_id']);
        if ($setck) {
            setcookie(
                $this->cookie,
                $tkt[$this->cookie],
                time()+self::$COOKIE_EXPIRE_TIME,
                '/'
            );
        }
        return $tkt;
    }


    /**
     * Refresh the tkt with any changes made to $this->tkt_data
     *
     * @access public
     * @return void
     */
    public function refresh_tkt() {
        if ($this->has_valid_tkt()) {
            $tkt = $this->get_tkt($this->get_username(), $this->get_id());
            setcookie(
                $this->cookie,
                $tkt[$this->cookie],
                time()+self::$COOKIE_EXPIRE_TIME, //won't affect tktinfo ts
                '/'
            );
        }
    }


    /**
     * Get a new (valid) ticket for a user, returning it without setting a
     * cookie.
     *
     * @access public
     * @param string  $usrname the username of the user
     * @param int     $usrid   the PK id of the user
     * @param array   $data    (optional) data to add to the tkt
     * @return array associative array with the cookie name and the tkt
     */
    public function get_tkt($usrname, $usrid, $data=array()) {
        foreach ($data as $key => $val) {
            $this->tkt_data[$key] = $val;
        }
        $this->tkt_data['user_id'] = $usrid;
        $new_ticket = $this->auth_tkt->create_ticket(array(
                'user' => $usrname,
                'data' => json_encode($this->tkt_data),
                'ts'   => isset($this->tkt_info['ts']) ? $this->tkt_info['ts'] : time()
            )
        );
        $this->tkt_is_valid = true;
        return array($this->cookie => $new_ticket);
    }


    /**
     * Deletes this user's ticket
     *
     * @access public
     * @return void
     */
    public function delete_tkt() {
        setcookie($this->cookie, null, time()-3600, '/');
        $this->tkt_is_valid = false;
    }


    /**
     * Gets the authz associative array from the ticket. Includes org_id and
     * a bitmask representing the role.
     *
     * @access public
     * @return array the authz validated for this user
     */
    public function get_authz() {
        if ($this->has_valid_tkt() && isset($this->tkt_data['authz'])) {
            $packed = base64_decode($this->tkt_data['authz']);

            // SANITY ... divisible by 10 bytes!
            if (strlen($packed) % 10 != 0) return false;

            $authz = array();
            for ($i=0; $i<strlen($packed); $i+=10) {
                $a = unpack('nid/Nhalf1/Nhalf2', substr($packed, $i, 10));
                $mask = ($a['half1'] << 32) | $a['half2'];
                $authz[$a['id']] = $mask;
            }
            return $authz;
        }
        return false;
    }


    /**
     * Sets the authz of a user.  The $authz must have the form:
     * array(<orgid> => <bitmask>, <orgid2> => <bitmask>, ...)
     *
     * @param string  $authz associative array of org-names to roles
     */
    public function set_authz($authz) {
        $packed = null;
        foreach ($authz as $id => $mask) {
            // mask is a 64-bit unsigned int - split it!
            $half1 = $mask >> 32;
            $half2 = $mask & 0xFFFFFFFF;
            $packed .= pack("nNN", $id, $half1, $half2);
        }
        $this->tkt_data['authz'] = base64_encode($packed);
    }



    /**
     * Gets the ID of an authenticated user
     *
     * @access public
     * @return int id of the user
     */
    public function get_id() {
        if ($this->has_valid_tkt() && isset($this->tkt_data['user_id'])) {
            return $this->tkt_data['user_id'];
        }
        return -1;
    }


    /**
     * Gets the username of an authenticated user
     *
     * @access public
     * @return string username of the user
     */
    public function get_username() {
        if ($this->has_valid_tkt() && isset($this->tkt_info['uid'])) {
            return $this->tkt_info['uid'];
        }
        return null;
    }


    /**
     * Return an array of info about the remote user.
     *
     * @access public
     * @return array
     */
    public function get_user_info() {
        if ($usr = $this->get_user()) {
            return array(
                'uuid'         => $usr->user_uuid,
                'username'     => $usr->user_username,
                'first_name'   => $usr->user_first_name,
                'last_name'    => $usr->user_last_name,
                'type'         => $usr->user_type,
                'status'       => $usr->user_status,
                'home_org'     => $usr->get_home_org_name(),
            );
        }
        return null;
    }


    /**
     * Get the User record associated with this tkt
     *
     * @return User
     */
    public function get_user() {
        $user_id = $this->get_id();

        // cache user record
        if (!$this->air2_user && $user_id !== -1) {
            $this->air2_user = Doctrine::getTable('User')->find($user_id);
        }
        return $this->air2_user;
    }


    /**
     * Return a json-string representing recent views.  Always return array.
     *
     * @return string
     */
    public function get_recent_views() {
        if (!$this->get_user()) {
            return false;
        }
        $recent = $this->get_user()->get_pref('recent');
        if (!$recent) {
            $recent = array();
        }
        $reqd_views = array('project', 'source', 'inquiry', 'submission');
        foreach ($reqd_views as $name) {
            if (!isset($recent[$name])) {
                $recent[$name] = array();
            }
        }
        return json_encode($recent);
    }


}
