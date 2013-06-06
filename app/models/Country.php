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
 * Country
 *
 * AIR2 Country codes
 *
 * @property integer $cntry_id
 * @property string $cntry_name
 * @property string $cntry_code
 * @property integer $cntry_disp_seq
 * @author rcavis
 * @package default
 */
class Country extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('country');
        $this->hasColumn('cntry_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('cntry_name', 'string', 128, array(
                'notnull' => true,
                'autoincrement' => false,
            ));
        $this->hasColumn('cntry_code', 'string', 2, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('cntry_disp_seq', 'integer', 2, array(
                'notnull' => true,
            ));

        parent::setTableDefinition();
    }


    /**
     * Returns array of all cntry_codes.
     *
     * @return array $all_codes
     */
    public static function get_all_codes() {
        $q = AIR2_Query::create()->from('Country a');
        $codes = array();
        foreach ( $q->execute() as $c ) {
            $codes[] = $c->cntry_code;
        }
        return $codes;
    }


    /**
     * Returns assoc array of all countries.
     *
     * @return array $all_countries_hash
     */
    public static function get_all() {
        $q = AIR2_Query::create()->from('Country a');
        $countries = array();
        foreach ( $q->execute() as $c ) {
            $countries[$c->cntry_code] = $c->cntry_name;
        }
        return $countries;
    }


}
