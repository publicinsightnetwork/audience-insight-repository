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

require_once 'Tank.php';
require_once 'trec_utils.php';

class TestTank extends Tank {
    public static $UUID_COL = 'tank_uuid';
    public static $UUIDS = array('TESTTANK0001', 'TESTTANK0002',
        'TESTTANK0003', 'TESTTANK0004', 'TESTTANK0005', 'TESTTANK0006',
        'TESTTANK0007', 'TESTTANK0008', 'TESTTANK0009', 'TESTTANK0010');
    public $my_uuid;


    /**
     * Call util to set remove stale records and set UUID, and then setup any
     * table-specific data.
     */
    function preInsert() {
        trec_make_new($this);

        // table-specific
        if (is_null($this->tank_name)) {
            $this->tank_name = 'TestTank '.$this->my_uuid;
        }
        if (is_null($this->tank_type)) {
            $this->tank_type = Tank::$TYPE_CSV;
        }
        if (is_null($this->tank_status)) {
            $this->tank_status = Tank::$STATUS_READY;
        }
    }


    /**
     * Delete from the database on exit
     */
    function __destruct() {
        trec_destruct($this);
    }


}
