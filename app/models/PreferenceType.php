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
 * PreferenceType
 *
 * Different types of preferences available to sources
 *
 * @property integer $pt_id
 * @property string $pt_uuid
 * @property string $pt_name
 * @property string $pt_identifier
 * @property string $pt_status
 * @property integer $pt_cre_user
 * @property integer $pt_upd_user
 * @property timestamp $pt_cre_dtim
 * @property timestamp $pt_upd_dtim
 * @property Doctrine_Collection $PreferenceTypeValue
 * @author rcavis
 * @package default
 */
class PreferenceType extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('preference_type');
        $this->hasColumn('pt_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('pt_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('pt_name', 'string', 128, array(
                'notnull' => true,
            ));
        $this->hasColumn('pt_identifier', 'string', 128, array(
                'notnull' => true,
            ));
        $this->hasColumn('pt_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('pt_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('pt_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('pt_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('pt_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasMany('PreferenceTypeValue', array(
                'local' => 'pt_id',
                'foreign' => 'ptv_pt_id'
            ));
    }


}
