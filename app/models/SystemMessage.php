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
 * SystemMessage
 *
 * Error messages for AIR2
 *
 * @property integer $smsg_id
 * @property string $smsg_value
 * @property string $smsg_status
 * @property integer $smsg_cre_user
 * @property integer $smsg_upd_user
 * @property timestamp $smsg_cre_dtim
 * @property timestamp $smsg_upd_dtim
 * @author rcavis
 * @package default
 */
class SystemMessage extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('system_message');
        $this->hasColumn('smsg_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('smsg_value', 'string', 255, array(

            ));
        $this->hasColumn('smsg_status', 'string', 1, array(
                'fixed' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('smsg_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('smsg_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('smsg_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('smsg_upd_dtim', 'timestamp', null, array(

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
