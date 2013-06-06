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

class TestCleanup {

    protected $tbl_name;
    protected $where_fields;
    protected $where_values;
    protected $max_delete = 1;


    /**
     * Create an object to destroy something in the database when it's
     * destroyed.  To be safe, this class can by default only destroy one
     * thing in the database.
     *
     * @param string  $tbl
     * @param string|array $flds
     * @param mixed|array $vals
     * @param integer $max_delete (optional)
     */
    public function __construct($tbl, $flds, $vals, $max_delete=1) {
        $this->tbl_name = $tbl;
        $this->where_fields = is_array($flds) ? $flds : array($flds);
        $this->where_values = is_array($vals) ? $vals : array($vals);
        $this->max_delete = $max_delete;

        // sanity check
        $flds = $this->where_fields;
        $vals = $this->where_values;
        if (count($flds) == 0 || count($flds) != count($vals)) {
            throw new Exception("Invalid fields/values for table $tbl");
        }
        foreach ($flds as $idx => $fname) {
            if (!$fname || strlen($fname) < 3) {
                throw new Exception("Invalid cleanup field $fname");
            }
            if (!$vals[$idx] || strlen($vals[$idx]) < 1) {
                throw new Exception("Invalid cleanup value ".$vals[$idx]);
            }
        }
    }


    /**
     * Destroy stuff in the database
     */
    function __destruct() {
        $conn = AIR2_DBManager::get_master_connection();

        // build the "where"
        $where = array();
        foreach ($this->where_fields as $idx => $fld) {
            $where[] = "$fld = ?";
        }
        $where = implode(' and ', $where);

        // count before deleting
        $q = "select count(*) from {$this->tbl_name} where $where";
        $num = $conn->fetchOne($q, $this->where_values, 0);
        if ($num > $this->max_delete) {
            $msg = "UNABLE TO CLEANUP - more than {$this->max_delete} rows";
            $msg .= " returned by query --> $q";
            throw new Exception($msg);
        }

        // execute delete
        $q = "delete from {$this->tbl_name} where $where";
        $del = $conn->exec($q, $this->where_values);
        if ($del != $num) {
            $msg = "PROBLEM CLEANING UP: expected to delete $num, got $del!";
            $msg .= "  Query --> $q";
            throw new Exception($msg);
        }

        // debug output
        if (getenv('AIR_DEBUG')) {
            diag("TestCleanup deleted $del stale {$this->tbl_name}");
        }
    }


}
