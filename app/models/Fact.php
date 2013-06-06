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
 * Fact
 *
 * A type of information related to a source
 *
 * @property integer $fact_id
 * @property string $fact_uuid
 * @property string $fact_name
 * @property string $fact_identifier
 * @property string $fact_status
 * @property integer $fact_cre_user
 * @property integer $fact_upd_user
 * @property timestamp $fact_cre_dtim
 * @property timestamp $fact_upd_dtim
 * @property string $fact_fv_type
 * @property Doctrine_Collection $FactValue
 * @property Doctrine_Collection $SrcFact
 * @author rcavis
 * @package default
 */
class Fact extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';
    public static $FV_TYPE_MULTIPLE = 'M';
    public static $FV_TYPE_FK_ONLY = 'F';
    public static $FV_TYPE_STR_ONLY = 'S';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('fact');
        $this->hasColumn('fact_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('fact_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('fact_name', 'string', 128, array(
                'notnull' => true,
            ));
        $this->hasColumn('fact_identifier', 'string', 128, array(
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('fact_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('fact_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('fact_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('fact_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('fact_upd_dtim', 'timestamp', null, array(

            ));
        $this->hasColumn('fact_fv_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasMany('FactValue', array(
                'local' => 'fact_id',
                'foreign' => 'fv_fact_id'
            ));

        $this->hasMany('SrcFact', array(
                'local' => 'fact_id',
                'foreign' => 'sf_fact_id'
            ));
    }


    /**
     * Determine if a birth year string is 'sane' or not.
     *
     * @param string  $value
     * @return boolean $sane
     */
    public static function birth_year_is_sane($value) {
        // sane years must be 4 digits
        if (strlen($value) == 4) {
            // check year range
            $int = intval($value);
            $now = date('Y');
            if ($int <= $now && $int >= ($now - 125)) {
                return true;
            }
        }
        return false;
    }


}
