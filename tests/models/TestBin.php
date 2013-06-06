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

require_once 'Bin.php';
require_once 'trec_utils.php';

class TestBin extends Bin {
    public static $UUID_COL = 'bin_uuid';
    public static $UUIDS = array('TESTBIN00100', 'TESTBIN00101', 'TESTBIN00102', 'TESTBIN00103');
    public $my_uuid;


    /**
     * Call util to set remove stale records and set UUID, and then setup any
     * table-specific data.
     */
    function preInsert() {
        trec_make_new($this);

        // table-specific
        if (!$this->bin_user_id) $this->bin_user_id = 1;
        if (!$this->bin_name) $this->bin_name = 'Test Bin '.$this->my_uuid;
    }


    /**
     * Delete from the database on exit
     */
    function __destruct() {
        if ($this->my_uuid) {
            // make sure any src_export records are cleaned up
            $conn = AIR2_DBManager::get_master_connection();
            $bid = 'select bin_id from bin where bin_uuid = ?';
            $del = "delete from src_export where se_xid = ($bid) and se_ref_type = ?";
            $conn->exec($del, array($this->my_uuid, SrcExport::$REF_TYPE_BIN));
        }
        trec_destruct($this);
    }


}
