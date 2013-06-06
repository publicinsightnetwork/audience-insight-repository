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
 * TankResponse
 *
 * Tank version of a SrcResponse.
 *
 * @property integer $tr_id
 * @property integer $tr_tsrc_id
 * @property integer $tr_trs_id
 *
 * @property integer $sr_ques_id
 * @property boolean $sr_media_asset_flag
 * @property string $sr_orig_value
 * @property string $sr_mod_value
 * @property string $sr_status
 * @property string $sr_uuid
 * @property integer $sr_cre_user
 * @property integer $sr_upd_user
 * @property timestamp $sr_cre_dtim
 * @property timestamp $sr_upd_dtim
 * @property TankResponseSet $TankResponseSet
 * @property Question $Question
 * @property TankSource $TankSource
 *
 * @author rcavis
 * @package default
 */
class TankResponse extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('tank_response');
        $this->hasColumn('tr_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('tr_tsrc_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('tr_trs_id', 'integer', 4, array(
                'notnull' => true,
            ));
        // in tank, sr_uuid is NULLable and not unique
        $this->hasColumn('sr_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => false,
                'unique' => false,
            )
        );

        // get the non-key columns of SrcResponse
        $ignore_flds = array('sr_id', 'sr_src_id', 'sr_srs_id', 'sr_uuid',
            'sr_cre_user', 'sr_upd_user', 'sr_cre_dtim', 'sr_upd_dtim');
        $c = Doctrine::getTable('SrcResponse')->getColumns();
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
        $this->hasOne('TankResponseSet', array(
                'local' => 'tr_trs_id',
                'foreign' => 'trs_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('Question', array(
                'local' => 'sr_ques_id',
                'foreign' => 'ques_id'
            ));
        $this->hasOne('TankSource', array(
                'local' => 'tr_tsrc_id',
                'foreign' => 'tsrc_id',
                'onDelete' => 'CASCADE'
            ));
    }


}
