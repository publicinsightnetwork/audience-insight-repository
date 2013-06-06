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
 * Locale
 *
 * Locale codes for AIR2
 *
 * @property integer $loc_id
 * @property string  $loc_key
 * @property string  $loc_lang
 * @property string  $loc_region
 * @author rcavis
 * @package default
 */
class Locale extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('locale');
        $this->hasColumn('loc_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('loc_key', 'string', 5, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('loc_lang', 'string', 255, array(

            ));
        $this->hasColumn('loc_region', 'string', 255, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasMany('Inquiry', array(
                'local' => 'loc_id',
                'foreign' => 'inq_loc_id'
            ));
    }


}
