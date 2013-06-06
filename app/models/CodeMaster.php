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
 * CodeMaster
 *
 * Contains descriptions of character codes used in AIR2
 *
 * @property integer $cm_id
 * @property string $cm_field_name
 * @property string $cm_code
 * @property string $cm_table_name
 * @property string $cm_disp_value
 * @property integer $cm_disp_seq
 * @property string $cm_area
 * @property string $cm_status
 * @property integer $cm_cre_user
 * @property integer $cm_upd_user
 * @property timestamp $cm_cre_dtim
 * @property timestamp $cm_upd_dtim
 * @author rcavis
 * @package default
 */
class CodeMaster extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('code_master');
        $this->hasColumn('cm_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('cm_field_name', 'string', 128, array(
                'notnull' => true,
            ));
        $this->hasColumn('cm_code', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('cm_table_name', 'string', 128, array(
                'notnull' => true,
            ));
        $this->hasColumn('cm_disp_value', 'string', 128, array(

            ));
        $this->hasColumn('cm_disp_seq', 'integer', 2, array(
                'notnull' => true,
                'default' => 10,
            ));
        $this->hasColumn('cm_area', 'string', 255, array(

            ));
        $this->hasColumn('cm_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('cm_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('cm_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('cm_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('cm_upd_dtim', 'timestamp', null, array(
            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
    }


}
