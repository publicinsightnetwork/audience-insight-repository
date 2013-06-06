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
 * UserOrg
 *
 * Organizations that Users belong to
 *
 * @property integer $uo_id
 * @property integer $uo_org_id
 * @property integer $uo_user_id
 * @property integer $uo_ar_id
 * @property string $uo_uuid
 * @property string $uo_user_title
 * @property string $uo_status
 * @property boolean $uo_notify_flag
 * @property boolean $uo_home_flag
 * @property integer $uo_cre_user
 * @property integer $uo_upd_user
 * @property timestamp $uo_cre_dtim
 * @property timestamp $uo_upd_dtim
 * @property User $User
 * @property AdminRole $AdminRole
 * @property Organization $Organization
 * @author rcavis
 * @package default
 */
class UserOrg extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('user_org');
        $this->hasColumn('uo_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('uo_org_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('uo_user_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('uo_ar_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('uo_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('uo_user_title', 'string', 255, array(

            ));
        $this->hasColumn('uo_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('uo_notify_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('uo_home_flag', 'boolean', 1, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('uo_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('uo_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('uo_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('uo_upd_dtim', 'timestamp', null, array(

            ));

        $this->index('uo_ix_2', array(
                'fields' => array('uo_org_id', 'uo_user_id'),
                'type' => 'unique'
            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('User', array(
                'local' => 'uo_user_id',
                'foreign' => 'user_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('Organization', array(
                'local' => 'uo_org_id',
                'foreign' => 'org_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('AdminRole', array(
                'local' => 'uo_ar_id',
                'foreign' => 'ar_id'
            ));
        $this->hasMany('UserOrg as SelfSameOrg', array(
                'local' => 'uo_org_id',
                'foreign' => 'uo_org_id',
            )
        );
    }


    /**
     * Make sure the user always has one home flag
     *
     * @param Doctrine_Event $event
     */
    public function postSave($event) {
        if ($this->uo_home_flag) {
            $conn = AIR2_DBManager::get_master_connection();
            $conn->execute("UPDATE user_org SET uo_home_flag = FALSE WHERE ".
                "uo_user_id = ? AND uo_id != ?", array($this->uo_user_id, $this->uo_id));
        }
        parent::postSave($event);
    }


    /**
     * Add custom search query (from the get param 'q')
     *
     * @param AIR2_Query $q
     * @param string  $alias
     * @param string  $search
     * @param boolean $useOr
     */
    public static function add_search_str(&$q, $alias, $search, $useOr=null) {
        // find the "Organization" alias in the query
        $from_parts = $q->getDqlPart('from');
        foreach ($from_parts as $string_part) {
            if ($match = strpos($string_part, "$alias.Organization")) {
                $offset = strlen("$alias.Organization") + 1; // remove space
                $usr_alias = substr($string_part, $match + $offset);

                Organization::add_search_str($q, $usr_alias, $search, $useOr);
                break;
            }
        }
    }


    /**
     * User Organizations are publicly visible.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        return $this->User->user_may_read($user);
    }


    /**
     * NOTE: although a User can't edit their org associations, they CAN edit
     * their title in that org.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // special case: owner may edit titles of existing records
        if ($this->exists() && $this->uo_user_id == $user->user_id) {
            $owner_may_modify = array('uo_user_title', 'uo_notify_flag', 'uo_home_flag');
            $mod_flds = $this->getModified();

            // check that only allowed fields are set
            foreach ($owner_may_modify as $fld) {
                unset($mod_flds[$fld]);
            }
            if (count($mod_flds) == 0) {
                return AIR2_AUTHZ_IS_OWNER;
            }
        }

        // update-usr authz in related org
        $org_id = $this->uo_org_id;
        $authz = $user->get_authz();
        $role = array_key_exists($org_id, $authz) ? $authz[$org_id] : 0;
        if (ACTION_ORG_USR_UPDATE & $role) {
            return AIR2_AUTHZ_IS_MANAGER;
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Manage (delete) authz
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // TODO: remove this from manage
        if ($this->exists() && $this->uo_user_id == $user->user_id) {
            $owner_may_modify = array('uo_user_title', 'uo_notify_flag', 'uo_home_flag');
            $mod_flds = $this->getModified();

            // check that only allowed fields are set
            foreach ($owner_may_modify as $fld) {
                unset($mod_flds[$fld]);
            }
            if (count($mod_flds) == 0) {
                return AIR2_AUTHZ_IS_OWNER;
            }
        }

        // delete-usr authz in related org
        $org_id = $this->uo_org_id;
        $authz = $user->get_authz();
        $role = array_key_exists($org_id, $authz) ? $authz[$org_id] : 0;
        if (ACTION_ORG_USR_DELETE & $role) {
            return AIR2_AUTHZ_IS_MANAGER;
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Find the number of active Users in any given Organization
     *
     * @param int     $org_id
     * @return int
     */
    public static function get_user_count($org_id) {
        $uost = UserOrg::$STATUS_ACTIVE;
        $ust1 = User::$STATUS_ACTIVE;
        $ust2 = User::$STATUS_PUBLISHABLE;

        $conn = AIR2_DBManager::get_connection();
        $active_users = "select user_id from user where user_status " .
            "= '$ust1' or user_status = '$ust2'";
        $q = "select count(*) from user_org where uo_org_id = ? and " .
            "uo_status = '$uost' and uo_user_id in ($active_users)";
        $n = $conn->fetchOne($q, array($org_id), 0);
        return $n;
    }


}
