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
 * UserPhoneNumber
 *
 * Phone number for a User
 *
 * @property integer $uph_id
 * @property string $uph_uuid
 * @property integer $uph_user_id
 * @property string $uph_country
 * @property string $uph_number
 * @property string $uph_ext
 * @property boolean $uph_primary_flag
 * @property User $User
 * @author rcavis
 * @package default
 */
class UserPhoneNumber extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('user_phone_number');
        $this->hasColumn('uph_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('uph_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('uph_user_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('uph_country', 'string', 3, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('uph_number', 'string', 12, array(
                'notnull' => true,
            ));
        $this->hasColumn('uph_ext', 'string', 12, array(

            ));
        $this->hasColumn('uph_primary_flag', 'boolean', null, array(
                'notnull' => true,
            ));

        parent::setTableDefinition();
    }



    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('User', array(
                'local' => 'uph_user_id',
                'foreign' => 'user_id',
                'onDelete' => 'CASCADE'
            ));
    }


    /**
     * Everyone may read.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        return $this->User->user_may_read($user);
    }


    /**
     * Only owner and system may write.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        return $this->User->user_may_write($user);
    }


    /**
     * Same as writing.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        return $this->User->user_may_manage($user);
    }


}
