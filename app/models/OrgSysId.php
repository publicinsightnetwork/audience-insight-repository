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
 * OrgSysId
 *
 * External system id's for organizations in AIR2
 *
 * @property integer $osid_id
 * @property integer $osid_org_id
 * @property string $osid_type
 * @property integer $osid_xuuid
 * @property integer $osid_cre_user
 * @property integer $osid_upd_user
 * @property timestamp $osid_cre_dtim
 * @property timestamp $osid_upd_dtim
 * @property Organization $Organization
 * @author rcavis
 * @package default
 */
class OrgSysId extends AIR2_Record {
    /* code_master values */
    public static $TYPE_EMAIL_MGR = 'E';
    public static $TYPE_MAILCHIMP = 'M';
    public static $TYPE_FORMBUILDER = 'F';
    public static $TYPE_TWITTER = 'T';
    public static $TYPE_FACEBOOK = 'B';

    public static $UNIQUE_TYPES = array('E');

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('org_sys_id');
        $this->hasColumn('osid_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('osid_org_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('osid_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('osid_xuuid', 'string', 128, array(

            ));
        $this->hasColumn('osid_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('osid_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('osid_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('osid_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Organization', array(
                'local' => 'osid_org_id',
                'foreign' => 'org_id',
                'onDelete' => 'CASCADE',
            ));
    }


    /**
     * Inherit from Organization
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        return $this->Organization->user_may_read($user);
    }


    /**
     * Inherit from Organization
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        return $this->Organization->user_may_write($user);
    }


    /**
     * Inherit from Organization
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        return $this->Organization->user_may_manage($user);
    }



    /**
     * Inherit from Organization
     *
     *
     * @param unknown $user
     * @return unknown
     */
    public function user_may_delete($user) {
        return $this->Organization->user_may_manage($user);
    }


    /**
     * Inherit from Organization
     *
     * @param AIR2_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     * @return unknown
     */
    public static function query_may_read(AIR2_Query $q, User $u, $alias=null) {
        if ($u->is_system()) {
            return;
        }
        return Organization::query_may_read($q, $u, $alias);
    }


    /**
     * Only one of certain types (e.g. email) allowed.
     *
     * @param Doctrine_Event $event
     */
    public function preValidate($event) {
        parent::preValidate($event);

        // check if this type is unique and we already have one
        if (!$this->osid_id && in_array($this->osid_type, self::$UNIQUE_TYPES)) {
            $q = AIR2_Query::create()->from('OrgSysId os');
            $q->addWhere('osid_type = ?', $this->osid_type);
            $q->addWhere('osid_org_id = ?', $this->osid_org_id);
            if ($this->exists()) {
                $q->addWhere('osid_id != ?', $this->osid_id);
            }
            if ($q->count() > 0) {
                throw new Exception("May only have one OrgSysId of type " . $this->osid_type);
            }
        }
    }


}
