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

require_once 'Inquiry.php';
require_once 'trec_utils.php';

class TestInquiry extends Inquiry {
    public static $UUID_COL = 'inq_uuid';
    public static $UUIDS =
        array(
        'TESTINQUIRY1',
        'TESTINQUIRY2',
        'TESTINQUIRY3',
        'TESTINQUIRY4',
        'TESTINQUIRY5',
        'TESTINQUIRY6',
        'TESTINQUIRY7',
        'TESTINQUIRY8',
        'TESTINQUIRY9',
        'TESTINQ10',
        'TESTINQ11',
        'TESTINQ12',
        'TESTINQ13',
        'TESTINQ14',
        'TESTINQ15',
        'TESTINQ16',
        'TESTINQ17',
        'TESTINQ18',
        'TESTINQ19',
        'TESTINQ20',
        'TESTINQ21',
        'TESTINQ22',
        'TESTINQ23',
        'TESTINQ24',
        'TESTINQ25',
        'TESTINQ26',
        'TESTINQ27',
        'TESTINQ28',
        'TESTINQ29',
        'TESTINQ30',
        'TESTINQ31',
        'TESTINQ32',
        'TESTINQ33',
        'TESTINQ34',
        'TESTINQ35',
        'TESTINQ36',
        'TESTINQ37',
    );
    public $my_uuid;


    /**
     * Call util to set remove stale records and set UUID, and then setup any
     * table-specific data.
     */
    function preInsert() {
        trec_make_new($this);

        // table-specific
        $this->inq_title = 'Inquiry '.$this->inq_uuid;
        //$this->inq_status = 'A';
        $this->inq_type = Inquiry::$TYPE_TEST;
    }


    /**
     * Delete from the database on exit
     */
    function __destruct() {
        trec_destruct($this);
    }


}
