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
 * FactValue
 *
 * Used for facts with the option of enumeration values
 *
 * @property integer $fv_id
 * @property integer $fv_fact_id
 * @property integer $fv_parent_fv_id
 * @property integer $fv_seq
 * @property string $fv_value
 * @property string $fv_status
 * @property integer $fv_cre_user
 * @property integer $fv_upd_user
 * @property timestamp $fv_cre_dtim
 * @property timestamp $fv_upd_dtim
 * @property Doctrine_Collection $FactValue
 * @property Fact $Fact
 * @property Doctrine_Collection $SrcFact
 * @property Doctrine_Collection $SrcFact_4
 * @property Doctrine_Collection $TranslationMap
 * @author rcavis
 * @package default
 */
class FactValue extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';

    /**
     * Get all the possible values for the given type.
     *
     * -birth_year
     * -education_level
     * -ethnicity
     * -gender
     * -household_income
     * -lifecycle
     * -political_affiliation
     * -religion
     * -source_website
     * -timezone
     *               false if none found.
     *
     * @param string  $type The type of fact to look up. Examples:
     * @return array Associative array from values to readable labels. Returns
     * */
    public static function get_hash_for($type) {
        $q = AIR2_Query::create()
        ->from("FactValue fv")
        ->innerJoin("fv.Fact f")
        ->where("f.fact_identifier = ?", $type)
        ->orderBy("fv.fv_seq asc")
        ->execute();

        if (count($q) === 0) {
            return false;
        }

        $vals = array();
        foreach ($q as $record) {
            $vals[$record->fv_id] = $record->fv_value;
        }

        return $vals;
    }


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('fact_value');
        $this->hasColumn('fv_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('fv_fact_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('fv_parent_fv_id', 'integer', 4, array(

            ));
        $this->hasColumn('fv_seq', 'integer', 2, array(
                'notnull' => true,
                'default' => 10,
            ));
        $this->hasColumn('fv_value', 'string', 128, array(
                'notnull' => true,
            ));
        $this->hasColumn('fv_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('fv_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('fv_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('fv_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('fv_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasMany('FactValue', array(
                'local' => 'fv_id',
                'foreign' => 'fv_parent_fv_id'
            ));
        $this->hasOne('Fact', array(
                'local' => 'fv_fact_id',
                'foreign' => 'fact_id'
            ));
        $this->hasMany('SrcFact', array(
                'local' => 'fv_id',
                'foreign' => 'sf_fv_id'
            ));
        $this->hasMany('SrcFact as SrcFact_4', array(
                'local' => 'fv_id',
                'foreign' => 'sf_src_fv_id'
            ));
        $this->hasMany('TranslationMap', array(
                'local' => 'fv_id',
                'foreign' => 'xm_xlate_to_fv_id'
            ));
    }


}
