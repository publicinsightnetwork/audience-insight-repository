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

require_once 'APIKey.php';
require_once 'trec_utils.php';

class TestAPIKey extends APIKey {
    public static $UUID_COL = 'ak_key';
    public static $UUIDS = array('TESTAPIKEY1234567890123456789012', 'TESTAPIKEY1234567890123456789034',
    	'TESTAPIKEY1234567890123456789056', 'TESTAPIKEY1234567890123456789078', 'TESTAPIKEY1234567890123456789090');
    public $my_uuid;

    /**
     * Call util to set remove stale records and set UUID, and then setup any
     * table-specific data.
     */
    function preInsert($event) {
        trec_make_new($this);
        $this->ak_email = 'echristiansen@mpr.org';
        $this->ak_contact = 'Emily';
        parent::preInsert($event);
    }


    /**
     * Delete from the database on exit
     */
    function __destruct() {
        trec_destruct($this);
    }
}
