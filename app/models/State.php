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
 * State
 *
 * USA States
 *
 * @property integer $state_id
 * @property string $state_name
 * @property string $state_code
 * @author rcavis
 * @package default
 */
class State extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('state');
        $this->hasColumn('state_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('state_name', 'string', 128, array(
                'notnull' => true,
            ));
        $this->hasColumn('state_code', 'string', 2, array(
                'fixed' => true,
                'notnull' => true,
            ));

        parent::setTableDefinition();
    }


    /**
     * Returns array of all state_codes.
     *
     * @return array $all_codes
     */
    public static function get_all_codes() {
        $q = AIR2_Query::create()->from('State a');
        $codes = array();
        foreach ( $q->execute() as $s ) {
            $codes[] = $s->state_code;
        }
        return $codes;
    }


    /**
     * Returns assoc array of all states.
     *
     * @return array $all_states_hash
     */
    public static function get_all() {
        $q = AIR2_Query::create()->from('State a');
        $states = array();
        foreach ( $q->execute() as $s ) {
            $states[$s->state_code] = $s->state_name;
        }
        return $states;
    }


    /**
     *
     *
     * @param string  $code
     * @return boolean
     */
    public static function is_canadian($code) {
        return in_array($code, array("AB", "BC", "MB", "NB", "NF", "NT", "NS", "NU", "ON", "PE", "QC", "SK", "YT"));
    }


    /**
     * Like get_all() where each item is !is_canadian().
     *
     * @return array
     */
    public static function get_all_US() {
        $all = self::get_all();
        $us = array();
        foreach ($all as $k=>$v) {
            if (!self::is_canadian($k)) {
                $us[$k] = $v;
            }
        }
        return $us;
    }


    /**
     * Like get_all() where each item is_canadian().
     *
     * @return array
     */
    public static function get_all_CA() {
        $all = self::get_all();
        $ca = array();
        foreach ($all as $k=>$v) {
            if (self::is_canadian($k)) {
                $ca[$k] = $v;
            }
        }
        return $ca;
    }


}
