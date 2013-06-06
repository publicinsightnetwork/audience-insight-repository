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

require_once 'shared/phmagick/phmagick.php';

/**
 * User
 *
 * AIR2 User account
 *
 * @property integer   $user_id
 * @property string    $user_uuid
 * @property string    $user_username
 *
 * @property string    $user_first_name
 * @property string    $user_last_name
 * @property string    $user_summary
 * @property string    $user_desc
 *
 * @property string    $user_password
 * @property timestamp $user_pswd_dtim
 *
 * @property string    $user_pref
 * @property string    $user_type
 * @property string    $user_status
 *
 * @propety timestamp  $user_login_dtim
 *
 * @property integer   $user_cre_user
 * @property integer   $user_upd_user
 * @property timestamp $user_cre_dtim
 * @property timestamp $user_upd_dtim
 *
 * @property Image               $Avatar
 * @property Doctrine_Collection $Bin
 * @property Doctrine_Collection $Project
 * @property Doctrine_Collection $UserSrs
 * @property Doctrine_Collection $UserEmailAddress
 * @property Doctrine_Collection $UserOrg
 * @property Doctrine_Collection $UserPhoneNumber
 * @property Doctrine_Collection $UserUri
 *
 * @author  rcavis
 * @package default
 */
class User extends AIR2_Record {

    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_PUBLISHABLE = 'P';
    public static $STATUS_INACTIVE = 'F';
    public static $TYPE_AIR_USER = 'A';
    public static $TYPE_JOURNALIST = 'J';
    public static $TYPE_RELATED = 'R';
    public static $TYPE_SYSTEM = 'S';

    private $authz = false;
    private $authz_up = false;
    private $authz_uuids = false;
    private $local_authz = false;


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('user');

        // identifiers and foreign keys
        $this->hasColumn('user_id', 'integer', 4, array(
                'primary'       => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('user_uuid', 'string', 12, array(
                'fixed'   => true,
                'notnull' => true,
                'unique'  => true,
            ));
        $this->hasColumn('user_username', 'string', 255, array(
                'unique' => true,
            ));

        // profile info
        $this->hasColumn('user_first_name', 'string', 64, array(
                'notnull' => true,
            ));
        $this->hasColumn('user_last_name', 'string', 64, array(
                'notnull' => true,
            ));
        $this->hasColumn('user_summary', 'string', 255,  array());
        $this->hasColumn('user_desc',    'string', null, array());

        // password
        $this->hasColumn('user_password', 'string', 32, array(
                'fixed' => true,
            ));
        $this->hasColumn('user_pswd_dtim', 'timestamp', null, array());

        // metadata
        $this->hasColumn('user_pref', 'string', null, array());
        $this->hasColumn('user_type', 'string', 1, array(
                'fixed'   => true,
                'notnull' => true,
                'default' => self::$TYPE_AIR_USER,
            ));
        $this->hasColumn('user_status', 'string', 1, array(
                'fixed'   => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));

        $this->hasColumn('user_login_dtim', 'timestamp', null, array());

        // stamps
        $this->hasColumn('user_cre_user', 'integer', 4, array());
        $this->hasColumn('user_upd_user', 'integer', 4, array());
        $this->hasColumn('user_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('user_upd_dtim', 'timestamp', null, array());

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasMany('Bin', array(
                'local' => 'user_id',
                'foreign' => 'bin_user_id'
            ));
        $this->hasMany('Project', array(
                'local' => 'user_id',
                'foreign' => 'prj_user_id'
            ));
        $this->hasMany('UserEmailAddress', array(
                'local' => 'user_id',
                'foreign' => 'uem_user_id'
            ));
        $this->hasMany('UserOrg', array(
                'local' => 'user_id',
                'foreign' => 'uo_user_id'
            ));
        $this->hasMany('UserPhoneNumber', array(
                'local' => 'user_id',
                'foreign' => 'uph_user_id'
            ));
        $this->hasMany('UserSrs', array(
                'local' => 'user_id',
                'foreign' => 'usrs_user_id',
            ));
        $this->hasMany('UserUri', array(
                'local' => 'user_id',
                'foreign' => 'uuri_user_id'
            ));
        $this->hasMany('SavedSearch', array(
                'local' => 'user_id',
                'foreign' => 'ssearch_cre_user',
            )
        );

        // image
        $this->hasOne('ImageUserAvatar as Avatar', array(
                'local' => 'user_id',
                'foreign' => 'img_xid',
            ));

        // add a mutator on the password field
        $this->hasMutator('user_password', '_encrypt_password');
    }


    /**
     * Helper function to check if User is a system user.
     *
     * @return boolean
     */
    public function is_system() {
        return $this->user_type === self::$TYPE_SYSTEM;
    }


    /**
     * CASCADEs delete to change contact_user_id on ProjectOrg to AIR2SYSTEM,
     * and delete any image assets
     *
     * @param Doctrine_Event $event
     * @return int number of rows affected
     */
    public function preDelete($event) {
        // nuke any avatar files
        if ($this->Avatar && $this->Avatar->exists()) {
            $this->Avatar->delete();
        }

        // do not orphan any project_org records, nor hit FK constraint.
        $conn = AIR2_DBManager::get_master_connection();
        $sql  = "UPDATE project_org SET porg_contact_user_id = 1 WHERE ".
            "porg_contact_user_id = {$this->user_id}";
        return $conn->execute($sql);
    }


    /**
     * Mutates the user_password to be encrypted
     *
     * @param string  $cleartext
     */
    protected function _encrypt_password($cleartext) {
        $encrypted = $this->_encrypt_string($cleartext);
        $this->_set('user_password', $encrypted);
    }


    /**
     * Encrypts a string
     *
     * @param string  $str
     * @return string the encrypted string
     */
    protected function _encrypt_string($str) {
        $salt = md5($str);
        return md5($str . $salt);
    }


    /**
     * Checks for equality between a password string against user_password
     *
     * @param string  $cleartext
     * @return boolean
     */
    public function check_password($cleartext) {
        $encrypted = $this->_encrypt_string($cleartext);
        return $encrypted === $this->user_password;
    }


    /**
     * Add a query string to search for Users.
     *
     * @param AIR2_Query $q      (reference)
     * @param string  $alias
     * @param string  $search
     * @param boolean $useOr  (optional)
     */
    public static function add_search_str(&$q, $alias, $search, $useOr=null) {
        $a = ($alias) ? "$alias." : "";
        $str = "({$a}user_first_name LIKE ? OR {$a}user_last_name LIKE ? OR ".
            "{$a}user_username like ?)";

        if ($useOr) {
            $q->orWhere($str, array("$search%", "$search%", "$search%"));
        }
        else {
            $q->addWhere($str, array("$search%", "$search%", "$search%"));
        }
    }


    /**
     * Get authorization object for this User.
     *   array(org_id => bitmask-role)
     *
     * This represents the Organization Asset authz.  That is, explicit roles
     * cascade both up and down the Org tree.  Explicit roles will always
     * override implicit ones.
     *
     * @return array
     */
    public function get_authz() {
        if ($this->authz) {
            return $this->authz;
        }

        // reset
        $this->authz = array();
        $this->authz_up = array();

        // sort orgs, and calculate authz
        $sorted = Organization::sort_by_depth($this->UserOrg, 'uo_org_id');
        foreach ($sorted as $uo) {
            if ($uo->uo_status == UserOrg::$STATUS_ACTIVE) {
                $children = Organization::get_org_children($uo->uo_org_id);
                $bitmask = $uo->AdminRole->get_bitmask();
                foreach ($children as $org_id) {
                    $this->authz[$org_id] = $bitmask;
                    $this->authz_up[$org_id] = $bitmask;
                }

                // get upwards-authz
                $parents = Organization::get_org_parents($uo->uo_org_id);
                foreach ($parents as $org_id) {
                    $curr = isset($this->authz_up[$org_id]) ? $this->authz_up[$org_id] : 0;
                    $this->authz_up[$org_id] = max(array($bitmask, $curr));
                }
            }
        }
        return $this->authz;
    }



    /**
     * Like get_authz() but returns only explicity assigned UserOrg records,
     * not recursive/hierarchical.
     *
     * @return array
     */
    public function get_explicit_authz() {
        if ($this->local_authz) {
            return $this->local_authz;
        }

        $this->local_authz = array();

        foreach ($this->UserOrg as $uo) {
            if ($uo->uo_status == UserOrg::$STATUS_ACTIVE) {
                $this->local_authz[$uo->uo_org_id] = $uo->AdminRole->get_bitmask();
            }
        }

        return $this->local_authz;
    }



    /**
     * Convenience for comparing a role bitmask + org_id combination.
     *
     * @param integer $min_authz
     * @param integer $org_id
     * @return boolean true if authz ok
     */
    public function has_authz_for($min_authz, $org_id) {
        $org_authz = $this->get_authz();
        if (!isset($org_authz[$org_id])) {
            return false;
        }
        return $org_authz[$org_id] & $min_authz;
    }


    /**
     * Like get_authz() but returns org_uuid as key instead of org_id.
     *
     * @return array $authz_uuids
     */
    public function get_authz_uuids() {
        if (!$this->authz) {
            $this->get_authz();
        }
        if ($this->authz_uuids) {
            return $this->authz_uuids;
        }

        $conn = AIR2_DBManager::get_connection();
        $rs = $conn->fetchAll('select org_id, org_uuid from organization');
        $map = array();
        foreach ($rs as $row) $map[$row['org_id']] = $row['org_uuid'];

        foreach ($this->authz as $org_id => $role) {
            $uuid = $map[$org_id];
            $this->authz_uuids[$uuid] = $role;
        }
        return $this->authz_uuids;
    }


    /**
     * Clear authz so that it's recalculated on the next call.
     */
    public function clear_authz() {
        $this->authz = false;
        $this->authz_up = false;
        $this->authz_uuids = false;
        $this->clearRelated('UserOrg');
    }


    /**
     * Returns a SQL/DQL-ready string for $column using
     * the org_ids returned by get_authz() and using a bitwise
     * comparison against $role.
     *
     * @param integer $role
     * @param string  $column
     * @param boolean $cascade_up (optional)
     * @return string
     */
    public function get_authz_str($role, $column, $cascade_up=false) {
        $authz = $this->get_authz();

        // optionally use cascade-ups
        if ($cascade_up) {
            $authz = $this->authz_up;
        }

        $org_ids = array();
        foreach ($authz as $org_id => $mask) {
            if ($mask & $role) {
                $org_ids[] = $org_id;
            }
        }
        $org_str = "$column IS NULL";
        if (count($org_ids)) {
            $org_str = "$column IN (" . implode(",", $org_ids) . ")";
        }
        return $org_str;
    }


    /**
     * Everyone may read the user.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // check public user-reading role
        $authz = $user->get_authz();
        foreach ($authz as $orgid => $mask) {
            if (ACTION_USR_READ & $mask) {
                return AIR2_AUTHZ_IS_PUBLIC;
            }
        }

        // check org-user roles
        foreach ($this->UserOrg as $uo) {
            $role = isset($authz[$uo->uo_org_id]) ? $authz[$uo->uo_org_id] : null;
            if (ACTION_ORG_USR_READ & $role) {
                return AIR2_AUTHZ_IS_MANAGER;
            }
        }
        return AIR2_AUTHZ_IS_PUBLIC; //TODO: fix this
    }


    /**
     * Writable by owner and joined-org managers.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        if ($user->user_uuid == $this->user_uuid) {
            return AIR2_AUTHZ_IS_OWNER;
        }

        // look in related organizations
        $authz = $user->get_authz();
        foreach ($this->UserOrg as $uo) {
            $role = isset($authz[$uo->uo_org_id]) ? $authz[$uo->uo_org_id] : null;
            if ($this->exists() && ACTION_ORG_USR_UPDATE & $role) {
                return AIR2_AUTHZ_IS_MANAGER;
            }
            elseif (!$this->exists() && ACTION_ORG_USR_CREATE & $role) {
                return AIR2_AUTHZ_IS_MANAGER;
            }
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Manageable by MANAGERs in joined orgs
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // look in related organizations
        $authz = $user->get_authz();
        foreach ($this->UserOrg as $uo) {
            $role = isset($authz[$uo->uo_org_id]) ? $authz[$uo->uo_org_id] : null;
            if (ACTION_ORG_USR_DELETE & $role) {
                return AIR2_AUTHZ_IS_MANAGER;
            }
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Apply authz rules for who may write to a User.
     *
     * @param AIR2_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     */
    public static function query_may_write(AIR2_Query $q, User $u, $alias=null) {
        if ($u->is_system()) {
            return;
        }
        $a = ($alias) ? "$alias." : "";

        // owner
        $owner = "{$a}user_id = {$u->user_id}";

        // update-user authz in org
        $manage_org_ids = $u->get_authz_str(ACTION_ORG_USR_UPDATE, 'uo_org_id', false);
        $stat = UserOrg::$STATUS_ACTIVE;
        $usr_ids = "select uo_user_id from user_org where $manage_org_ids";
        $q->addWhere("($owner or {$a}user_id in ($usr_ids))");
    }


    /**
     * Apply authz rules for who may manage a User.
     *
     * @param AIR2_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     */
    public static function query_may_manage(AIR2_Query $q, User $u, $alias=null) {
        if ($u->is_system()) {
            return;
        }
        $a = ($alias) ? "$alias." : "";

        // delete-usr authz in org
        $manage_org_ids = $u->get_authz_str(ACTION_ORG_USR_DELETE, 'uo_org_id', false);
        $stat = UserOrg::$STATUS_ACTIVE;
        $usr_ids = "select uo_user_id from user_org where $manage_org_ids";
        $q->addWhere("{$a}user_id in ($usr_ids)");
    }


    /**
     * Get a User preference value.
     *
     * @param string  $name
     * @return string
     */
    public function get_pref($name) {
        $prefs = json_decode($this->user_pref, true);
        return isset($prefs[$name]) ? $prefs[$name] : null;
    }


    /**
     * Set a User preference value.
     *
     * @param string  $name
     * @param string  $value
     */
    public function set_pref($name, $value) {
        $prefs = json_decode($this->user_pref, true);
        if (!$prefs) {
            $prefs = array(); //initial setup
        }
        $prefs[$name] = $value;
        $this->user_pref = json_encode($prefs);
    }


    /**
     * Helper function to fetch the User record for the remote user.
     *
     * @return User object
     */
    public static function get_remote_user() {
        return Doctrine::getTable('User')->findOneBy('user_id', AIR2_REMOTE_USER_ID);
    }


    /**
     * Finds the a "default project" for a User.
     *
     * @return integer prj_id, or NULL if not found.
     */
    public function find_default_prj_id() {
        foreach ($this->UserOrg as $uo) {
            if ($uo->uo_status == UserOrg::$STATUS_ACTIVE) {
                $prj_id = $uo->Organization->org_default_prj_id;
                return $prj_id; // just return first one encountered
            }
        }
        return null;
    }


    /**
     * Get the org_name of a User's home org, or '0' if they don't have one.
     *
     * @return string $org_name
     */
    public function get_home_org_name() {
        foreach ($this->UserOrg as $uo) {
            if ($uo->uo_home_flag) {
                return $uo->Organization->org_name;
            }
        }
        return 0;
    }


    /**
     * Returns Home Org for the User, or '0' if they do not have one.
     *
     * @return Organization $org
     */
    public function get_home_org() {
        foreach ($this->UserOrg as $uo) {
            if ($uo->uo_home_flag) {
                return $uo->Organization;
            }
        }
        return 0;
    }



    /**
     * Returns the UserEmailAddress where uem_public_flag==true.
     *
     * @return string $email_address
     */
    public function get_primary_email() {
        foreach ($this->UserEmailAddress as $uem) {
            if ($uem->uem_primary_flag) {
                return $uem->uem_address;
            }
        }
    }


    /**
     * Checks user_status for values that correlate to "active".
     *
     * @return boolean
     */
    public function is_active() {
        $status = $this->user_status;
        if ($status == self::$STATUS_ACTIVE
            || $status == self::$STATUS_PUBLISHABLE
        ) {
            return true;
        }
        return false;
    }


}
