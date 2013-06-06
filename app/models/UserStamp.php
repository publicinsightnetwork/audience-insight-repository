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

require_once 'User.php';

/**
 * UserStamp
 *
 * This is a SPECIAL model to define the relationship between "_cre_user"-type
 * fields and the User model.  It sets all fields to read-only.
 *
 * @property integer $user_id
 * @property string $user_uuid
 * @property string $user_username
 * @property string $user_password
 * @property timestamp $user_pswd_dtim
 * @property string $user_first_name
 * @property string $user_last_name
 * @property string $user_type
 * @property string $user_status
 * @property integer $user_cre_user
 * @property integer $user_upd_user
 * @property timestamp $user_cre_dtim
 * @property timestamp $user_upd_dtim
 * @author rcavis
 * @package default
 */
class UserStamp extends User {

    /**
     * Set all columns to readonly.
     */
    public function setTableDefinition() {
        parent::setTableDefinition();

        $tbl = $this->getTable();
        $cols = $tbl->getColumns();
        foreach ($cols as $name => $opts) {
            $tbl->setColumnOption($name, 'readonly', true);
        }
    }


    /**
     * Don't export this table to the database
     */
    public function setUp() {
        parent::setUp();
        $this->setAttribute(Doctrine::ATTR_EXPORT, Doctrine::EXPORT_NONE);
    }


}
