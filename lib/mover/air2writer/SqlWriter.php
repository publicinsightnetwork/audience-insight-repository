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

require_once "mover/AIR2_Writer.php";

/**
 * SQL writer
 *
 * Writes data to a database using a Doctrine_Connection to execute the raw sql
 * inserts.
 *
 * Example usage:
 *
 *  $db_mapping = array(
 *      'db_table1' => array(
 *          'db_col1' => array(
 *              'map' => 0,               // <-- column of input data to map to
 *          ),
 *          'db_col2' => array(
 *              'val' => 'static value',  // <-- set to static value
 *          ),
 *          'db_col3' => array(
 *              'map' => 1,
 *          ),
 *      ),
 *      'db_table2' => array(
 *          'db_col1' => array(
 *              'map' => 2,
 *          ),
 *      ),
 *  );
 *
 *  $reader = new SomethingReader($params);
 *  $writer = new MySqlImporter($doctrine_conn, $db_mapping);
 *  $num = $writer->write_data($reader);
 *
 *  echo "Wrote $num objects to database\n";
 *  echo "Encountered ".count($writer->get_errors())." errors\n";
 *
 * @author rcavis
 * @package default
 */
class SqlWriter extends AIR2_Writer {

    /* mapping from AIR2_Reader */
    protected $db_mapping;

    /* track number of inserts (not necessarily COMMIT'ed) */
    protected $num_inserts_performed;

    /* database connection */
    protected $conn;


    /**
     * Constructor
     *
     * @param Doctrine_Connection $conn
     * @param array   $db_mapping
     */
    function __construct(Doctrine_Connection $conn, $db_mapping) {
        $this->conn = $conn;
        $this->db_mapping = $db_mapping;
    }


    /**
     * Start a database transaction, if atomic
     */
    protected function begin_write() {
        $this->num_inserts_performed = 0;

        // start a transaction, if we're doing an atomic-write
        if ($this->atomic) {
            $this->conn->beginTransaction();
        }
    }


    /**
     * Use the dbmap to insert an object into the database
     *
     * @param array   $obj
     * @param boolean $commit
     */
    protected function write_object($obj, $commit) {
        foreach ($this->db_mapping as $tbl => $cols) {
            $col_names = array();
            $vals = array();
            foreach ($cols as $name => $def) {
                $col_names[] = $name;
                $vals[] = isset($def['map']) ? $obj[$def['map']] : $def['val'];
            }

            // implode arrays to create the statement
            $col_q = array_pad(array(), count($col_names), '?');
            $col_q = implode(',', $col_q);
            $col_names = implode(',', $col_names);
            $stmt = "INSERT INTO $tbl ($col_names) VALUES ($col_q)";

            // execute the statement
            $t = $this->conn->exec($stmt, $vals);
        }
        $this->num_inserts_performed++;
    }


    /**
     * Commit any outstanding changes
     *
     * @param boolean $cancel
     * @return int total number of items actually imported into the db
     */
    protected function end_write($cancel=false) {
        if ($cancel) {
            if ($this->atomic) $this->conn->rollback();
            return 0;
        }
        else {
            if ($this->atomic) $this->conn->commit();
            return $this->num_inserts_performed;
        }
    }


}
