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
 * APIStats
 *
 * APIStats for tracking users
 *
 * @property integer   $as_id
 * @property string    $as_ak_key
 * @property string    $as_ip_addr
 * @property timestamp $as_cre_dtim
 * @author echristiansen
 * @package default
 */

class APIStat extends AIR2_Record {
	/**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('api_stat');
        $this->hasColumn('as_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('as_ak_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('as_ip_addr', 'string', 16, array(
                'notnull' => true,
            ));
        $this->hasColumn('as_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));

        parent::setTableDefinition();
    }

    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('APIKey', array(
                'local' => 'as_ak_id',
                'foreign' => 'ak_id'
            ));
    }

    
}
