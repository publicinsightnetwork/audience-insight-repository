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
 * PreferenceTypeValue
 *
 * Enumerates what values a source can pick from for each preference type
 *
 * @property integer $ptv_id
 * @property integer $ptv_pt_id
 * @property string $ptv_uuid
 * @property integer $ptv_seq
 * @property string $ptv_value
 * @property string $ptv_status
 * @property integer $ptv_cre_user
 * @property integer $ptv_upd_user
 * @property timestamp $ptv_cre_dtim
 * @property timestamp $ptv_upd_dtim
 * @property PreferenceType $PreferenceType
 * @property Doctrine_Collection $SrcPreference
 * @author rcavis
 * @package default
 */
class PreferenceTypeValue extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('preference_type_value');
        $this->hasColumn('ptv_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('ptv_pt_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('ptv_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('ptv_seq', 'integer', 2, array(
                'notnull' => true,
                'default' => 10,
            ));
        $this->hasColumn('ptv_value', 'string', 255, array(

            ));
        $this->hasColumn('ptv_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('ptv_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('ptv_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('ptv_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('ptv_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('PreferenceType', array(
                'local' => 'ptv_pt_id',
                'foreign' => 'pt_id'
            ));
        $this->hasMany('SrcPreference', array(
                'local' => 'ptv_id',
                'foreign' => 'sp_ptv_id'
            ));
    }


}
