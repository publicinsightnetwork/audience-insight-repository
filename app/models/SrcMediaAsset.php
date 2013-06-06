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
 * SrcMediaAsset
 *
 * Media Asset of a Source
 *
 * @property integer $sma_id
 * @property integer $sma_src_id
 * @property integer $sma_sr_id
 * @property string $sma_file_ext
 * @property string $sma_type
 * @property string $sma_file_uri
 * @property integer $sma_file_size
 * @property string $sma_status
 * @property boolean $sma_export_flag
 * @property boolean $sma_public_flag
 * @property boolean $sma_archive_flag
 * @property boolean $sma_delete_flag
 * @property integer $sma_cre_user
 * @property integer $sma_upd_user
 * @property timestamp $sma_cre_dtim
 * @property timestamp $sma_upd_dtim
 * @property Source $Source
 * @property Doctrine_Collection $SmaAnnotation
 * @author rcavis
 * @package default
 */
class SrcMediaAsset extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';
    public static $TYPE_IMAGE = 'I';
    public static $TYPE_VIDEO = 'V';
    public static $TYPE_DOCUMENT = 'D';
    public static $TYPE_AUDIO_FILE = 'A';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_media_asset');
        $this->hasColumn('sma_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('sma_src_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sma_sr_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sma_file_ext', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('sma_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('sma_file_uri', 'string', 255, array(
                'notnull' => true,
            ));
        $this->hasColumn('sma_file_size', 'integer', 4, array(

            ));
        $this->hasColumn('sma_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('sma_export_flag', 'boolean', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sma_public_flag', 'boolean', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sma_archive_flag', 'boolean', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sma_delete_flag', 'boolean', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sma_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sma_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('sma_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sma_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'sma_src_id',
                'foreign' => 'src_id'
            ));
        $this->hasMany('SmaAnnotation', array(
                'local' => 'sma_id',
                'foreign' => 'smaan_sma_id'
            ));
    }


}
