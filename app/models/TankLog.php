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
 * TankLog
 *
 * AIR2 logging events concerting a Tank object
 *
 * @property integer $tlog_id
 * @property integer $tlog_tank_id
 * @property integer $tlog_user_id
 * @property string $tlog_dtim
 * @property string $tlog_text
 * @property string $tlog_type
 * @property string $tlog_status
 * @property Tank $Tank
 * @property User $User
 * @author rcavis
 * @package default
 */
class TankLog extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('tank_log');
        $this->hasColumn('tlog_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('tlog_tank_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('tlog_user_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('tlog_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('tlog_text', 'string', null, array(

            ));
        $this->hasColumn('tlog_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('tlog_status', 'string', 1, array(
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
        $this->hasOne('Tank', array(
                'local' => 'tlog_tank_id',
                'foreign' => 'tank_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('User', array(
                'local' => 'tlog_user_id',
                'foreign' => 'user_id',
                'onDelete' => 'CASCADE'
            ));
    }


}
