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
 * TankOrg
 *
 * Allows Organization opt-in/opt-out/etc for each TankSource as it's imported
 * into the system.
 *
 * @property integer $to_id
 * @property integer $to_tank_id
 * @property string  $to_org_id
 * @property integer $to_so_status
 * @property boolean $to_so_home_flag
 * @property Tank         $Tank
 * @property Organization $Organization
 * @author rcavis
 * @package default
 */
class TankOrg extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('tank_org');
        $this->hasColumn('to_id', 'integer', 4, array(
                'primary'       => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('to_tank_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('to_org_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('to_so_status', 'string', 1, array(
                'notnull' => true,
                'fixed'   => true,
                'default' => SrcOrg::$STATUS_OPTED_IN,
            ));
        $this->hasColumn('to_so_home_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Tank', array(
                'local' => 'to_tank_id',
                'foreign' => 'tank_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('Organization', array(
                'local' => 'to_org_id',
                'foreign' => 'org_id',
                'onDelete' => 'CASCADE'
            ));
    }


    /**
     * Create or update a SrcOrg record for a Source.
     *
     * @param Source  $src
     */
    public function process_source(Source $src) {
        // run raw-sql for efficiency
        $conn = AIR2_DBManager::get_master_connection();
        $src_id = $src->src_id;
        $org_id = $this->to_org_id;
        $unset_home_flags = false;

        // check for existing (and total)
        $where = "where so_src_id = $src_id and so_org_id = $org_id";
        $status = "(select so_status from src_org $where) as status";
        $ishome = "(select so_home_flag from src_org $where) as ishome";
        $select = "select count(*) as total, $status, $ishome";
        $q = "$select from src_org where so_src_id = $src_id";
        $rs = $conn->fetchRow($q);

        // run operation
        $op = false;
        $data = array();
        if (is_null($rs['status'])) {
            // insert
            $data = array(
                'so_src_id'         => $src_id,
                'so_org_id'         => $org_id,
                'so_uuid'           => air2_generate_uuid(),
                'so_effective_date' => air2_date(),
                'so_home_flag'      => $this->to_so_home_flag ? 1 : 0,
                'so_status'         => $this->to_so_status,
                'so_cre_user'       => $this->Tank->tank_user_id,
                'so_upd_user'       => $this->Tank->tank_user_id,
                'so_cre_dtim'       => $this->Tank->tank_cre_dtim,
                'so_upd_dtim'       => $this->Tank->tank_upd_dtim,
            );

            // determine home flag
            if ($rs['total'] == 0) {
                $data['so_home_flag'] = true;
            }
            elseif ($this->to_so_home_flag && $data['total'] > 0) {
                $unset_home_flags = true;
            }

            // insert
            $flds = implode(',', array_keys($data));
            $vals = air2_sql_param_string($data);
            $q = "insert into src_org ($flds) values ($vals)";
            $conn->exec($q, array_values($data));
        }
        else {
            // update
            $updates = array();

            // change to status
            if ($rs['status'] != $this->to_so_status) {
                $updates[] = "so_status='".$this->to_so_status."'";
            }
            // change to home flag (only allow setting, not unsetting)
            if ($this->to_so_home_flag && !$rs['ishome']) {
                $updates[] = "so_home_flag=1"; //MUST be true
                if ($rs['total'] > 1) {
                    $unset_home_flags = true;
                }
            }

            // do we need to do anything?
            if (count($updates)) {
                $set = implode(', ', $updates);
                $where = "so_src_id=$src_id and so_org_id=$org_id";
                $q = "update src_org set $set where $where";
                $conn->exec($q);
            }
        }

        // optionally unset other home flags
        if ($unset_home_flags) {
            $set = 'so_home_flag=0';
            $where = "so_src_id=$src_id and so_org_id!=$org_id";;
            $conn->exec("update src_org set $set where $where");
        }
    }


}
