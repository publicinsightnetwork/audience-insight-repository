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
 * APIKey
 *
 * APIKeys for tracking users
 *
 * @property integer   $ak_id
 * @property string    $ak_key
 * @property string    $ak_email
 * @property string    $ak_contact
 * @property integer   $ak_approved
 * @property timestamp $ak_cre_dtim
 * @property timestamp $ak_upd_dtim
 * @author echristiansen
 * @package default
 */
class APIKey extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('api_key');
        $this->hasColumn('ak_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('ak_key', 'string', 32, array(
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('ak_email', 'string', 255, array(
                'notnull' => true,
            ));
        $this->hasColumn('ak_contact', 'string', 255, array(
                'notnull' => true,
            ));
        $this->hasColumn('ak_approved', 'integer', 1, array(
                'default' => 0,
            ));
        $this->hasColumn('ak_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('ak_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Return UUID column name for this class.
     *
     * @return string
     */
    public function get_uuid_col() {
        return 'ak_key';
    }


}
