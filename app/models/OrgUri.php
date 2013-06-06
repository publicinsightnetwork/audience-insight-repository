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
 * OrgUri
 *
 * URI resources for an Organization
 *
 * @property integer $ouri_id
 * @property string  $ouri_uuid
 * @property integer $ouri_org_id
 * @property string  $ouri_type
 * @property string  $ouri_value
 * @property string  $ouri_feed
 * @property integer $ouri_upd_int
 * @property string  $ouri_handle
 *
 * @property Organization $Organization
 *
 * @author  rcavis
 * @package default
 */
class OrgUri extends AIR2_Record {

    /* code_master values */
    public static $TYPE_INTROVID   = 'V';
    public static $TYPE_FACEBOOK   = 'F';
    public static $TYPE_LINKEDIN   = 'L';
    public static $TYPE_TWITTER    = 'T';
    public static $TYPE_GOOGLEPLUS = 'G';
    public static $TYPE_PINTEREST  = 'I';
    public static $TYPE_PERSONAL   = 'M';
    public static $TYPE_WORK       = 'W';
    public static $TYPE_OTHER      = 'O';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('org_uri');
        $this->hasColumn('ouri_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('ouri_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('ouri_org_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('ouri_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('ouri_value', 'string', 255, array(
                'notnull' => true,
            ));
        $this->hasColumn('ouri_feed', 'string', 255, array());
        $this->hasColumn('ouri_upd_int', 'integer', 4, array());
        $this->hasColumn('ouri_handle', 'string', 128, array());
        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Organization', array(
                'local' => 'ouri_org_id',
                'foreign' => 'org_id',
                'onDelete' => 'CASCADE'
            ));
    }


    /**
     * Inherit from org
     *
     * @param  User $user
     * @return int  $authz
     */
    public function user_may_read($user) {
        return $this->Organization->user_may_read($user);
    }


    /**
     * Inherit from org
     *
     * @param  User $user
     * @return int  $authz
     */
    public function user_may_write($user) {
        return $this->Organization->user_may_write($user);
    }


    /**
     * Inherit from org
     *
     * @param  User $user
     * @return int  $authz
     */
    public function user_may_manage($user) {
        return $this->Organization->user_may_manage($user);
    }


}
