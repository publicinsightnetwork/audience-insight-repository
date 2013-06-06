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
 * PasswordReset
 *
 * Table to hold temporary URL's for resetting passwords
 *
 * @property string $pwr_uuid
 * @property timestamp $pwr_expiration_dtim
 * @property integer $pwr_user_id
 * @property User $User
 * @author rcavis
 * @package default
 */
class PasswordReset extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('password_reset');
        $this->hasColumn('pwr_uuid', 'string', 32, array(
                'fixed' => true,
                'primary' => true,
            ));
        $this->hasColumn('pwr_expiration_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('pwr_user_id', 'integer', 4, array(
                'notnull' => true,
            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('User', array(
                'local' => 'pwr_user_id',
                'foreign' => 'user_id'
            ));
    }


}
