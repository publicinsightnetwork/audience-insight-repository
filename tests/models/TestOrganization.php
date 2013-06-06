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

require_once 'Organization.php';
require_once 'TestProject.php';
require_once 'trec_utils.php';

class TestOrganization extends Organization {
    public static $UUID_COL = 'org_uuid';
    public static $UUIDS = array('TESTORG00001', 'TESTORG00002',
        'TESTORG00003', 'TESTORG00004', 'TESTORG00005', 'TESTORG00006',
        'TESTORG00007', 'TESTORG00008', 'TESTORG00009');
    public $my_uuid;


    /**
     * Call util to set remove stale records and set UUID, and then setup any
     * table-specific data.
     */
    function preInsert() {
        trec_make_new($this);

        // prevent default-project creation
        Organization::$CREATE_DEFAULT_PRJ = false;

        // table-specific
        $this->org_name = 'TestOrg'.$this->org_uuid;
        $this->org_display_name = $this->org_name;
        $this->org_type = 'T';
        $this->org_status = 'A';
        $this->org_html_color = '00FF00';
    }


    /**
     * Delete from the database on exit
     */
    function __destruct() {
        trec_destruct($this);
    }


}
