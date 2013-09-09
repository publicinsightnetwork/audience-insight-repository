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
 * UserSignature
 *
 * A text/email signature tied to a user
 *
 * @property integer    $usig_id
 * @property string     $usig_uuid
 * @property integer    $usig_user_id
 * @property string     $usig_text
 * @property string     $usig_status
 *
 * @property integer    $usig_cre_user
 * @property integer    $usig_upd_user
 * @property timestamp  $usig_cre_dtim
 * @property timestamp  $usig_upd_dtim
 *
 * @property User                $User
 * @property Doctrine_Collection $Email
 *
 * @author rcavis
 * @package default
 */
class UserSignature extends AIR2_Record {

    public static $STATUS_ACTIVE   = 'A';
    public static $STATUS_INACTIVE = 'F';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('user_signature');

        // identifiers
        $this->hasColumn('usig_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('usig_uuid', 'string', 12, array(
                'fixed'   => true,
                'notnull' => true,
                'unique'  => true,
            ));
        $this->hasColumn('usig_user_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('usig_text', 'string', null, array(
                'notnull' => true,
                'airvalidhtml' => array(
                    'display' => 'Signature Text',
                    'message' => 'Not well formed html'
                ),
            ));

        // meta
        $this->hasColumn('usig_status', 'string', 1, array(
                'fixed'   => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('usig_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('usig_upd_user', 'integer', 4, array());
        $this->hasColumn('usig_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('usig_upd_dtim', 'timestamp', null, array());

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('User', array(
                'local'   => 'usig_user_id',
                'foreign' => 'user_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasMany('Email', array(
                'local'   => 'usig_id',
                'foreign' => 'email_usig_id',
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
