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

require_once 'TagMaster.php';
require_once 'trec_utils.php';

class TestTagMaster extends TagMaster {
    public static $UUID_COL = 'tm_name';
    public static $UUIDS = array('TESTTAG0001', 'TESTTAG0002',
        'TESTTAG0003', 'TESTTAG0004', 'TESTTAG0005', 'TESTTAG0006',
        'TESTTAG0007', 'TESTTAG0008', 'TESTTAG0009', 'TESTTAG0010');
    public $my_uuid;


    /**
     * Call util to set remove stale records and set UUID, and then setup any
     * table-specific data.
     */
    function preInsert() {
        trec_make_new($this);
    }


    /**
     * Delete from the database on exit
     */
    function __destruct() {
        if ($this->my_uuid) {
            $conn = AIR2_DBManager::get_master_connection();
            $conn->exec('delete from tag where tag_tm_id in (select tm_id from '.
                'tag_master where tm_name = ?)', array($this->my_uuid));
        }
        trec_destruct($this);
    }


}
