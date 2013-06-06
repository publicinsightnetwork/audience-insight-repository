<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
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
 * AIR2_Query base class
 *
 * @author pkarman
 * @package default
 */
class AIR2_Query extends Doctrine_Query {
    /* queries without ->select() are implicit select-alls */
    protected $is_explicit_select = false;


    /**
     * Since php doesn't support late static binding in 5.2 we need to override
     * this method to instantiate a new MyQuery instead of Doctrine_Query
     *
     * @param Doctrine_Connection $conn  (optional)
     * @param string  $class (optional)
     * @return AIR2_Query
     */
    public static function create($conn=null, $class=null) {
        return new AIR2_Query($conn);
    }


    /**
     * Set the query to use a particular connection
     *
     * @param Doctrine_Connection $conn
     */
    public function set_connection($conn) {
        //$opts = $conn->getOptions();
        //Carper::carp("connection set to " . $opts['dsn']);
        $this->_conn = $conn;
    }


    /**
     * Prequery hook
     */
    public function preQuery() {
        if ($this->gettype() == Doctrine_Query::SELECT) {
            $this->set_connection(AIR2_DBManager::get_slave_connection());
        }
        else {
            $this->set_connection(AIR2_DBManager::get_master_connection());
        }
    }


    /**
     * After the first time you call $q->select(), a query is no longer an
     * implicit select all.
     *
     * @param string  $select
     * @return Doctrine_Query
     */
    public function select($select=null) {
        $this->is_explicit_select = true;
        return parent::select($select);
    }


    /**
     * The first time you call addSelect (assuming that you didn't do an
     * explicit $q->select() query), all the joined relations will be
     * auto-selected.  After this point, however, your select statement will
     * be explicit, so if you continue to join relations, they will not be
     * automatically included in the select.
     *
     * @param string  $select
     * @return Doctrine_Query
     */
    public function addSelect($select) {
        if (!$this->is_explicit_select) {
            // get the "from" parts, and add them to the select
            $this->getSqlQuery(); // trigger the dql parser
            $aliases = array_keys($this->_queryComponents);
            foreach ($aliases as $idx => $a) {
                $aliases[$idx] .= '.*';
            }
            $this->select(implode(', ', $aliases));
        }

        // now add the select statement
        return parent::addSelect($select);
    }


}
