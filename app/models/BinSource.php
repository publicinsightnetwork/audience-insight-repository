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
 * BinSource
 *
 * Unique instance of a source within a single Bin
 *
 * @property integer $bsrc_bin_id
 * @property integer $bsrc_src_id
 * @property string  $bsrc_notes
 * @property string  $bsrc_meta
 *
 * @property Bin                 $Bin
 * @property Source              $Source
 *
 * @author  rcavis
 * @package default
 */
class BinSource extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('bin_source');
        $this->hasColumn('bsrc_src_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('bsrc_bin_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('bsrc_notes', 'string', 255, array(
            ));
        $this->hasColumn('bsrc_meta', 'string', 255, array(
            ));
        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Bin', array(
                'local' => 'bsrc_bin_id',
                'foreign' => 'bin_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('Source', array(
                'local' => 'bsrc_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE',
            ));
    }


    /**
     * Attempt to pass search query on to the Source
     *
     * @param Doctrine_Query $q
     * @param string $alias
     * @param string $search
     * @param boolean $useOr
     */
    public static function add_search_str($q, $alias, $search, $useOr=null) {
        $from_parts = $q->getDqlPart('from');
        foreach ($from_parts as $string_part) {
            if (preg_match("/{$alias}\.Source *(\w*)/", $string_part, $matches)) {
                $src_alias = isset($matches[1]) ? $matches[1] : null;
                Source::add_search_str($q, $src_alias, $search, $useOr);
                break;
            }
        }
    }


    /**
     * Read - bin readable, and source readable
     *
     * @param User $user
     * @return boolean
     */
    public function user_may_read($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        if ($this->Bin->user_may_read($user)) {
            if ($this->Source->user_may_read($user)) {
                return AIR2_AUTHZ_IS_ORG;
            }

            // check bin_src_response_sets for this source
            $q = Doctrine_Query::create()->from('BinSrcResponseSet');
            $q->andWhere('bsrs_bin_id = ?', $this->bsrc_bin_id);
            $q->andWhere('bsrs_src_id = ?', $this->bsrc_src_id);
            BinSrcResponseSet::query_may_read($q, $user);
            if ($q->count() > 0) {
                return AIR2_AUTHZ_IS_PROJECT;
            }
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
     * Read - bin readable, and (source-or-any-bin'd-submission readable)
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
        $read_bin_ids = "select bin_id from bin where bin_shared_flag=1 or bin_user_id=$uid";
        $bin_read = "{$a}bsrc_bin_id in ($read_bin_ids)";

        // readable sources
        $read_org_ids = $u->get_authz_str(ACTION_ORG_SRC_READ, 'soc_org_id');
        $cache = "select soc_src_id from src_org_cache where $read_org_ids";
        $src_read = "{$a}bsrc_src_id in ($cache)";

        // readable src_response_sets (inquiries)
        $read_org_ids = $u->get_authz_str(ACTION_ORG_PRJ_INQ_SRS_READ, 'porg_org_id', true);
        $prj_ids  = "select porg_prj_id from project_org where $read_org_ids";
        $inq_ids  = "select pinq_inq_id from project_inquiry where pinq_prj_id in ($prj_ids)";
        $src_ids  = "select bsrs_src_id from bin_src_response_set where bsrs_inq_id in ($inq_ids)";
        if ($alias) {
            $src_ids .= " and bsrs_bin_id={$a}bsrc_bin_id"; //get even more specific
        }
        $srs_read = "{$a}bsrc_src_id in ($src_ids)";

        // add to query
        $q->addWhere("($bin_read and ($src_read or $srs_read))");
    }


    /**
     * Write - bin writable
     *
     * @param Doctrine_Query $q
     * @param User $u
     * @param string $alias (optional)
     */
    public static function query_may_write($q, $u, $alias=null) {
        if ($u->is_system()) return;
        $a = ($alias) ? "$alias." : "";
        $write_bin_ids = "select bin_id from bin where bin_user_id=?";
        $q->addWhere("{$a}bsrc_bin_id in ($write_bin_ids)", $u->user_id);
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
