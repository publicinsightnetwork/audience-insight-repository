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
 * UserUri
 *
 * URI resources for a User
 *
 * @property integer $uuri_id
 * @property string  $uuri_uuid
 * @property integer $uuri_user_id
 * @property string  $uuri_type
 * @property string  $uuri_value
 * @property string  $uuri_feed
 * @property integer $uuri_upd_int
 * @property string  $uuri_handle
 *
 * @property User    $User
 *
 * @author  rcavis
 * @package default
 */
class UserUri extends AIR2_Record {

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
        $this->setTableName('user_uri');
        $this->hasColumn('uuri_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('uuri_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('uuri_user_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('uuri_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('uuri_value', 'string', 255, array(
                'notnull' => true,
            ));
        $this->hasColumn('uuri_feed', 'string', 255, array());
        $this->hasColumn('uuri_upd_int', 'integer', 4, array());
        $this->hasColumn('uuri_handle', 'string', 128, array());
        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('User', array(
                'local' => 'uuri_user_id',
                'foreign' => 'user_id',
                'onDelete' => 'CASCADE'
            ));
    }


    /**
     * Inherit from user
     *
     * @param  User $user
     * @return int  $authz
     */
    public function user_may_read($user) {
        return $this->User->user_may_read($user);
    }


    /**
     * Inherit from user
     *
     * @param  User $user
     * @return int  $authz
     */
    public function user_may_write($user) {
        return $this->User->user_may_write($user);
    }


    /**
     * Inherit from user
     *
     * @param  User $user
     * @return int  $authz
     */
    public function user_may_manage($user) {
        return $this->User->user_may_manage($user);
    }


}
