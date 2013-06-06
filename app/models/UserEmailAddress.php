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
 * UserEmailAddress
 *
 * Email address for a User
 *
 * @property integer $uem_id
 * @property string $uem_uuid
 * @property integer $uem_user_id
 * @property string $uem_address
 * @property boolean $uem_primary_flag
 * @property User $User
 * @author rcavis
 * @package default
 */
class UserEmailAddress extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('user_email_address');
        $this->hasColumn('uem_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('uem_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('uem_user_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('uem_address', 'string', 255, array(
                'notnull' => true,
            ));
        $this->hasColumn('uem_primary_flag', 'boolean', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('uem_signature', 'string', null, array());

        parent::setTableDefinition();
    }



    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('User', array(
                'local' => 'uem_user_id',
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
