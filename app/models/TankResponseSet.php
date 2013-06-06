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
 * TankResponseSet
 *
 * Tank version of a SrcResponseSet
 *
 * @property integer $trs_id
 * @property integer $trs_tsrc_id
 *
 * @property integer $srs_inq_id
 * @property timestamp $srs_date
 * @property string $srs_uri
 * @property string $srs_type
 * @property boolean $srs_public_flag
 * @property boolean $srs_fb_approved_flag
 * @property boolean $srs_delete_flag
 * @property boolean $srs_translated_flag
 * @property boolean $srs_export_flag
 * @property string $srs_language
 * @property string $srs_conf_level
 * @property string $srs_uuid
 * @property TankSource $TankSource
 * @property Inquiry $Inquiry
 * @property Doctrine_Collection $TankResponse
 *
 * @author rcavis
 * @package default
 */
class TankResponseSet extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('tank_response_set');
        $this->hasColumn('trs_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('trs_tsrc_id', 'integer', 4, array(
                'notnull' => true,
            ));

        // in tank, srs_uuid is NULLable and not unique
        $this->hasColumn('srs_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => false,
                'unique' => false,
            )
        );

        // get the non-key columns of SrcResponseSet
        $ignore_flds = array('srs_id', 'srs_src_id', 'srs_uuid', 'srs_cre_user',
            'srs_upd_user', 'srs_cre_dtim', 'srs_upd_dtim', 'srs_city', 'srs_state',
            'srs_country', 'srs_county', 'srs_lat', 'srs_long');
        $c = Doctrine::getTable('SrcResponseSet')->getColumns();
        foreach ($c as $idx => $def) {
            if (!in_array($idx, $ignore_flds)) {
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
                'local' => 'trs_tsrc_id',
                'foreign' => 'tsrc_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('Inquiry', array(
                'local' => 'srs_inq_id',
                'foreign' => 'inq_id'
            ));
        $this->hasMany('TankResponse', array(
                'local' => 'trs_id',
                'foreign' => 'tr_trs_id'
            ));
    }


}
