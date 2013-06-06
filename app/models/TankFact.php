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
 * TankFact
 *
 * Tank version of a SrcFact.
 *
 * @property integer $tf_id
 * @property integer $tf_tsrc_id
 *
 * @property integer $sf_fact_id
 * @property integer $sf_fv_id
 * @property integer $sf_src_fv_id
 * @property string $sf_src_value
 * @property TankSource $TankSource
 * @property Fact $Fact
 * @property FactValue $AnalystFV
 * @property FactValue $SourceFV
 *
 * @author rcavis
 * @package default
 */
class TankFact extends AIR2_Record {
    /* Fields to copy from SrcFact */
    protected $copy_fields = array('sf_fv_id', 'sf_src_fv_id', 'sf_src_value');


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('tank_fact');
        $this->hasColumn('tf_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('tf_fact_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('tf_tsrc_id', 'integer', 4, array(
                'notnull' => true,
            ));

        // copy some specific columns of SrcFact
        $c = Doctrine::getTable('SrcFact')->getColumns();
        foreach ($c as $idx => $def) {
            if (in_array($idx, $this->copy_fields)) {
                $this->hasColumn($idx, $def['type'], $def['length'], $def);
            }
        }

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('TankSource', array(
                'local' => 'tf_tsrc_id',
                'foreign' => 'tsrc_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('Fact', array(
                'local' => 'tf_fact_id',
                'foreign' => 'fact_id'
            ));
        $this->hasOne('FactValue as AnalystFV', array(
                'local' => 'sf_fv_id',
                'foreign' => 'fv_id'
            ));
        $this->hasOne('FactValue as SourceFV', array(
                'local' => 'sf_src_fv_id',
                'foreign' => 'fv_id'
            ));
    }


    /**
     * Helper function to lookup a fact by name.
     *
     * @param string  $fact_name
     * @return int|false
     */
    public static function lookup_fact_id($fact_name) {
        $fact = Doctrine::getTable('Fact')->findOneBy('fact_name', $fact_name);
        if ($fact) {
            return $fact->fact_id;
        }
        else {
            return false;
        }
    }


    /**
     * Helper function to lookup a fact value by name.
     *
     * @param string  $fact_name
     * @param string  $fv_name
     * @return int|false
     */
    public static function lookup_factvalue_id($fact_name, $fv_name) {
        $q = Doctrine_Query::create()->from('FactValue fv');
        $q->leftJoin('fv.Fact f');
        $q->where('f.fact_name = ?', $fact_name);
        $q->addWhere('fv.fv_value = ?', $fv_name);
        $fval = $q->fetchOne();
        if ($fval) {
            return $fval->fv_id;
        }
        else {
            return false;
        }
    }


}
