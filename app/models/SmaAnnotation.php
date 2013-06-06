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
 * SmaAnnotation
 *
 * Annotation on a media asset.
 *
 * @property integer $smaan_id
 * @property integer $smaan_sma_id
 * @property string $smaan_value
 * @property integer $smaan_cre_user
 * @property integer $smaan_upd_user
 * @property timestamp $smaan_cre_dtim
 * @property timestamp $smaan_upd_dtim
 * @property SrcMediaAsset $SrcMediaAsset
 * @author rcavis
 * @package default
 */
class SmaAnnotation extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('sma_annotation');
        $this->hasColumn('smaan_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('smaan_sma_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('smaan_value', 'string', null, array(

            ));
        $this->hasColumn('smaan_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('smaan_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('smaan_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('smaan_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }



    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('SrcMediaAsset', array(
                'local' => 'smaan_sma_id',
                'foreign' => 'sma_id'
            ));
    }


}
