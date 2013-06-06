<?php
/**************************************************************************
 *
 *   Copyright 2011 American Public Media Group
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
 * State
 *
 * USA States
 *
 * @property string $zip_code
 * @property string $state
 * @property string $city
 * @property string $county
 * @package default
 */
class GeoLookup extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('geo_lookup');
        $this->hasColumn('zip_code', 'string', 16, array(
                'primary' => true,
            )
        );
        $this->hasColumn('state', 'string', 128, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('city', 'string', 255, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('county', 'string', 128, array(
            )
        );
        $this->hasColumn('latitude', 'float', null, array(

            )
        );
        $this->hasColumn('longitude', 'float', null, array(

            )
        );
        $this->hasColumn('population', 'integer', 4, array(

            )
        );


        parent::setTableDefinition();
    }


}
