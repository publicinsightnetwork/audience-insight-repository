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
 * BinSrcResponseSet
 *
 * Unique instance of a SrcResponseSet within a Bin
 *
 * @property integer $bsrs_bin_id
 * @property integer $bsrs_srs_id
 * @property integer $bsrs_inq_id
 * @property integer $bsrs_src_id
 *
 * @property Bin            $BinSource
 * @property SrcResponseSet $SrcResponseSet
 * @property Inquiry        $Inquiry
 * @property Source         $Source
 *
 * @author  rcavis
 * @package default
 */
class BinSrcResponseSet extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('bin_src_response_set');
        $this->hasColumn('bsrs_bin_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('bsrs_srs_id', 'integer', 4, array(
                'primary' => true,
            ));

        // cached srs columns to speed things up
        $this->hasColumn('bsrs_inq_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('bsrs_src_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('bsrs_cre_dtim', 'timestamp', null, array());
        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Bin', array(
                'local' => 'bsrs_bin_id',
                'foreign' => 'bin_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('SrcResponseSet', array(
                'local' => 'bsrs_srs_id',
                'foreign' => 'srs_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('Inquiry', array(
                'local' => 'bsrs_inq_id',
                'foreign' => 'inq_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('Source', array(
                'local' => 'bsrs_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE',
            ));
    }


    /**
     * Read - bin readable, and src_response_set readable
     *
     * @param User $user
     * @return boolean
     */
    public function user_may_read($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        if ($this->Bin->user_may_read($user)) {
            return $this->SrcResponseSet->user_may_read($user);
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Write - bin writable
     *
     * @param User $user
     * @return boolean
     */
    public function user_may_write($user) {
        return $this->Bin->user_may_write($user);
    }


    /**
     * Manage - bin manageable
     *
     * @param User $user
     * @return boolean
     */
    public function user_may_manage($user) {
        return $this->Bin->user_may_manage($user);
    }


    /**
     * Read - bin readable, and src_response_set readable
     *
     * @param Doctrine_Query $q
     * @param User $u
     * @param string $alias (optional)
     */
    public static function query_may_read($q, $u, $alias=null) {
        if ($u->is_system()) return;
        $a = ($alias) ? "$alias." : "";
        $uid = $u->user_id;

        // readable bins
        $read_bin_ids  = "select bin_id from bin where bin_shared_flag=1 or bin_user_id=$uid";
        $bin_read      = "{$a}bsrs_bin_id in ($read_bin_ids)";

        // readable src_response_sets (inquiries)
        $read_org_ids = $u->get_authz_str(ACTION_ORG_PRJ_INQ_SRS_READ, 'porg_org_id', true);
        $prj_ids  = "select porg_prj_id from project_org where $read_org_ids";
        $inq_ids  = "select pinq_inq_id from project_inquiry where pinq_prj_id in ($prj_ids)";
        $srs_read = "{$a}bsrs_inq_id in ($inq_ids)";

        // add to query
        $q->addWhere("($bin_read and $srs_read)");
    }


    /**
     * Write - bin_source writable
     *
     * @param Doctrine_Query $q
     * @param User $u
     * @param string $alias (optional)
     */
    public static function query_may_write($q, $u, $alias=null) {
        if ($u->is_system()) return;
        $a = ($alias) ? "$alias." : "";
        $write_bin_ids  = "select bin_id from bin where bin_user_id=?";
        $q->addWhere("{$a}bsrs_bin_id in ($write_bin_ids)", $u->user_id);
    }


    /**
     * Manage - same as write
     *
     * @param Doctrine_Query $q
     * @param User $u
     * @param string $alias (optional)
     */
    public static function query_may_manage($q, $u, $alias=null) {
        self::query_may_write($q, $u, $alias);
    }


}
