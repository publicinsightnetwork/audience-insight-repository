<?php
/**************************************************************************
 *
 *   Copyright 2013 American Public Media Group
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
 * InquiryActivity
 *
 * Activity occuring in reference to an inquiry
 *
 * @property integer $iu_id
 * @property char $iu_type
 * @property char $iu_status
 * @property integer $iu_xid
 * @property string $iu_first_name
 * @property string $iu_last_name
 * @property string $iu_email
 * @property integer $iu_cre_user
 * @property integer $iu_upd_user
 * @property timestamp $iu_cre_dtim
 * @property timestamp $iu_upd_dtim
 * @property User $User
 * @package default
 */
class InquiryUser extends AIR2_Record {

    public static $TYPE_WATCHER = 'W';
    public static $TYPE_AUTHOR = 'A';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('inquiry_user');
        $this->hasColumn('iu_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('iu_inq_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('iu_type', 'string', 1, array(
                'notnull' => true,
                'default' => self::$TYPE_WATCHER,
            ));
        $this->hasColumn('iu_status', 'string', 1, array(
                'notnull' => true,
                'default' => 'A',
            ));
        $this->hasColumn('iu_user_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('iu_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('iu_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('iu_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('iu_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();

        $this->index('inquiry_user_idx', array(
                'fields' => array('iu_inq_id', 'iu_user_id', 'iu_type'),
                'type' => 'unique'
            )
        );

    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('User', array(
                'local' => 'iu_user_id',
                'foreign' => 'user_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('Inquiry', array(
                'local' => 'iu_inq_id',
                'foreign' => 'inq_id',
                'onDelete' => 'CASCADE',
            ));
    }


    /**
     * Inherit from Inquiry
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        return $this->Inquiry->user_may_read($user);
    }


    /**
     * Inherit from Inquiry
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        return $this->Inquiry->user_may_write($user);
    }


    /**
     * Inherit from Inquiry
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        return $this->Inquiry->user_may_manage($user);
    }


    /**
     * May delete if you can manage or if you are the user referenced.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_delete($user) {
        $ret = $this->user_may_manage($user);
        if ($ret || $user->user_id == $this->iu_user_id) {
            return $ret;
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


}
