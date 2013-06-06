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
 * UserSrs
 *
 * Relationship between a user and a submission.  Used to track things like
 * read/unread status, and favorites.  Kept very minimal on purpose, as the
 * user_visit table already provides more robust logging around user
 * activity.
 *
 * @property integer $usrs_user_id
 * @property integer $usrs_srs_id
 * @property boolean $usrs_read_flag
 * @property boolean $usrs_favorite_flag
 *
 * @property SrcResponseSet $SrcResponseSet
 * @property User           $User
 *
 * @author  rcavis
 * @package default
 */
class UserSrs extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('user_srs');
        $this->hasColumn('usrs_user_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('usrs_srs_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('usrs_read_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('usrs_favorite_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('usrs_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('usrs_upd_dtim', 'timestamp', null, array(

            ));
        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('SrcResponseSet', array(
                'local' => 'usrs_srs_id',
                'foreign' => 'srs_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('User', array(
                'local' => 'usrs_user_id',
                'foreign' => 'user_id',
                'onDelete' => 'CASCADE',
            ));
    }


    /**
     * Only owner
     *
     * @param User    $user
     * @return int  $authz
     */
    public function user_may_read($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        if ($user->user_id == $this->usrs_user_id) {
            return AIR2_AUTHZ_IS_OWNER;
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Only owner
     *
     * @param User    $user
     * @return int  $authz
     */
    public function user_may_write($user) {
        return $this->user_may_read($user);
    }


    /**
     * Only owner
     *
     * @param User    $user
     * @return int  $authz
     */
    public function user_may_manage($user) {
        return $this->user_may_write($user);
    }


}
