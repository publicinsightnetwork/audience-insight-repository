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
 * SrcPreference
 *
 * Preferences of a Source
 *
 * @property integer $sp_src_id
 * @property integer $sp_ptv_id
 * @property string $sp_uuid
 * @property string $sp_status
 * @property boolean $sp_lock_flag
 * @property integer $sp_cre_user
 * @property integer $sp_upd_user
 * @property timestamp $sp_cre_dtim
 * @property timestamp $sp_upd_dtim
 * @property Source $Source
 * @property PreferenceTypeValue $PreferenceTypeValue
 * @author rcavis
 * @package default
 */
class SrcPreference extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_preference');
        $this->hasColumn('sp_src_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('sp_ptv_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('sp_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('sp_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('sp_lock_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('sp_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sp_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('sp_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sp_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'sp_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('PreferenceTypeValue', array(
                'local' => 'sp_ptv_id',
                'foreign' => 'ptv_id',
                'onDelete' => 'CASCADE'
            ));
    }

     /**
     * Inherit from Source
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read(User $user) {
        return $this->Source->user_may_read($user);
    }

    /**
     * Inherit from Source
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        return $this->Source->user_may_write($user);
    }


    /**
     * Inherit from Source
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        return $this->Source->user_may_manage($user);
    }

}
