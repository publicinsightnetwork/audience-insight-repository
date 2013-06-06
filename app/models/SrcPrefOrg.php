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
 * SrcPrefOrg
 *
 * ???
 *
 * @property integer $spo_id
 * @property integer $spo_src_id
 * @property integer $spo_org_id
 * @property timestamp $spo_effective
 * @property string $spo_type
 * @property integer $spo_xid
 * @property boolean $spo_lock_flag
 * @property string $spo_status
 * @property integer $spo_cre_user
 * @property integer $spo_upd_user
 * @property timestamp $spo_cre_dtim
 * @property timestamp $spo_upd_dtim
 * @property Source $Source
 * @property Organization $Organization
 * @author rcavis
 * @package default
 */
class SrcPrefOrg extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_pref_org');
        $this->hasColumn('spo_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('spo_src_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('spo_org_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('spo_effective', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('spo_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('spo_xid', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('spo_lock_flag', 'boolean', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('spo_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('spo_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('spo_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('spo_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('spo_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'spo_src_id',
                'foreign' => 'src_id'
            ));
        $this->hasOne('Organization', array(
                'local' => 'spo_org_id',
                'foreign' => 'org_id'
            ));
    }


}
