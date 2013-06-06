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

require_once 'SystemMessage.php';
require_once 'trec_utils.php';

class TestSystemMessage extends SystemMessage {
    public static $UUID_COL = 'smsg_id';
    public static $UUIDS = array();
    public $my_uuid;


    /**
     * Call util to set remove stale records and set UUID, and then setup any
     * table-specific data.
     */
    function preInsert() {
        trec_make_new($this);

        // table-specific
        $this->smsg_value = 'test value';
        $this->smsg_cre_user = 1; // system user
        $this->smsg_cre_dtim = date('Y-m-d H:i:s');
    }


    /**
     * Delete from the database on exit
     */
    function __destruct() {
        trec_destruct($this);
    }


    /**
     * Create new records that can be cleaned up from the database upon exit.
     *
     * @param int     $smsg_id
     * @param string  $smsg_value
     * @return new Doctrine_Record
     */
    public static function make_new($smsg_id, $smsg_value) {
        self::$UUIDS = array($smsg_id);
        $t = new TestSystemMessage();
        $t->save();
        $t->smsg_value = $smsg_value;
        $t->save();
        return $t;
    }


}
