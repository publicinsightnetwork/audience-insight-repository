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
 * SrcUri
 *
 * URI related to a Source
 *
 * @property integer $suri_id
 * @property integer $suri_src_id
 * @property boolean $suri_primary_flag
 * @property string $suri_context
 * @property string $suri_type
 * @property string $suri_value
 * @property string $suri_handle
 * @property string $suri_feed
 * @property integer $suri_upd_int
 * @property string $suri_status
 * @property integer $suri_cre_user
 * @property integer $suri_upd_user
 * @property timestamp $suri_cre_dtim
 * @property timestamp $suri_upd_dtim
 * @property Source $Source
 * @author rcavis
 * @package default
 */
class SrcUri extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';
    public static $CONTEXT_PERSONAL = 'P';
    public static $CONTEXT_WORK = 'W';
    public static $CONTEXT_OTHER = 'O';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_uri');
        $this->hasColumn('suri_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('suri_src_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('suri_primary_flag', 'boolean', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('suri_context', 'string', 1, array(
                'fixed' => true,
            ));
        $this->hasColumn('suri_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('suri_value', 'string', 255, array(
                'notnull' => true,
            ));
        $this->hasColumn('suri_handle', 'string', 128, array(
                'notnull' => true,
            ));
        $this->hasColumn('suri_feed', 'string', 255, array(

            ));
        $this->hasColumn('suri_upd_int', 'integer', 4, array(

            ));
        $this->hasColumn('suri_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('suri_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('suri_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('suri_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('suri_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }



    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'suri_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE'
            ));
    }


}
