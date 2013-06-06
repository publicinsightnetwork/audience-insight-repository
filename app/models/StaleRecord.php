<?php
/**************************************************************************
 *
 *   Copyright 2013 American Public Media Group
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
 * StaleRecord
 *
 * flag records needing update in search index
 *
 * @property integer   $str_xid
 * @property char      $str_type
 * @property timestamp $str_upd_dtim
 * @package default
 */
class StaleRecord extends AIR2_Record {

    /* type values */
    public static $TYPE_SOURCE = 'S';
    public static $TYPE_RESPONSE = 'R';
    public static $TYPE_INQUIRY = 'I';
    public static $TYPE_PROJECT = 'P';
    public static $TYPE_PUBLIC_RESPONSE = 'A';



    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('stale_record');
        $this->hasColumn('str_xid', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('str_type', 'string', 1, array(
                'primary' => true,
            ));
        $this->hasColumn('str_upd_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
            
        parent::setTableDefinition();
    }


}
