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

require_once 'Source.php';
require_once 'trec_utils.php';

class TestSource extends Source {
    public static $UUID_COL = 'src_uuid';
    public static $UUIDS = array('TESTSOURCE01', 'TESTSOURCE02',
        'TESTSOURCE03', 'TESTSOURCE04', 'TESTSOURCE05', 'TESTSOURCE06',
        'TESTSOURCE07', 'TESTSOURCE08', 'TESTSOURCE09', 'TESTSOURCE10',
        'TESTSOURCE11', 'TESTSOURCE12', 'TESTSOURCE13', 'TESTSOURCE14',
        'TESTSOURCE15', 'TESTSOURCE16', 'TESTSOURCE17', 'TESTSOURCE18',
        'TESTSOURCE19', 'TESTSOURCE20', 'TESTSOURCE21', 'TESTSOURCE22',
        'TESTSOURCE23', 'TESTSOURCE24', 'TESTSOURCE25', 'TESTSOURCE26');
    public $my_uuid;


    /**
     * Call util to set remove stale records and set UUID, and then setup any
     * table-specific data.
     */
    function preInsert() {
        trec_make_new($this);

        // table-specific
        if (is_null($this->src_username)) $this->src_username = 'TestSource'.$this->my_uuid;
        if (is_null($this->src_first_name)) $this->src_first_name = 'Test Source '.$this->my_uuid;
    }


    /**
     * Delete from the database on exit
     */
    function __destruct() {
        trec_destruct($this);
    }


}
