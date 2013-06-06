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

/**
 * SrcOrgCache
 *
 * A cached table containing the explicit Org opt-ins calculated from the
 * src_org table, cascading down the Org-tree.
 *
 * @property integer $soc_src_id
 * @property integer $soc_org_id
 * @property Source $Source
 * @property Organization $Organization
 * @author rcavis
 * @package default
 */
class SrcOrgCache extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_org_cache');
        $this->hasColumn('soc_src_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('soc_org_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('soc_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'soc_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('Organization', array(
                'local' => 'soc_org_id',
                'foreign' => 'org_id',
                'onDelete' => 'CASCADE',
            ));
    }


    /**
     * Static function to refresh src_org_cache from src_org
     *
     * @param Source|src_id|src_uuid $source
     * @return int number of rows cached
     */
    public static function refresh_cache($source) {
        $conn = AIR2_DBManager::get_master_connection();

        // get the src_id
        $src_id;
        if (is_numeric($source)) {
            $src_id = $source;
        }
        elseif (is_string($source)) {
            $q = 'select src_id from source where src_uuid = ?';
            $src_id = $conn->fetchOne($q, array($source), 0);
        }
        elseif (is_object($source)) {
            $src_id = $source->src_id;
        }

        // sanity!
        if (!$src_id) {
            Carper::carp("Source !exists");
            return;
        }

        // delete all src_org_cache recs for this source
        $conn->execute("delete from src_org_cache where soc_src_id = $src_id");

        // array of org_id => status
        $org_status = Source::get_authz_status($src_id);

        // bulk-insert
        $vals = array();
        foreach ($org_status as $org_id => $status) {
            $vals[] = "($src_id,$org_id,'$status')";
        }
        if (count($vals)) {
            $vals = implode(',', $vals);
            $stmt = "insert into src_org_cache (soc_src_id, soc_org_id, soc_status)";
            $conn->execute("$stmt values $vals");
        }

        return count($vals);
    }


}
