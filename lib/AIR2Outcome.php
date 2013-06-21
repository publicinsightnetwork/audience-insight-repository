<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
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

require_once 'Search_Proxy.php';

/**
 * AIR2Bin utility class
 *
 * Static class for bulk operations related to bins
 *
 * @author echristiansen
 * @package default
 */
abstract class AIR2Outcome {
 	/**
     * Add sources to a PINfluence
     *
     * @param  Outcome $outcome
     * @param  array   $idents
     */
    public static function add_sources($outcome, $idents, $type) {
        $stats = array('total', 'insert', 'duplicate', 'invalid');
        $where = self::get_where_condition($idents, $stats);
        if (!$where) return $stats;

        // duplicates
        $conn = AIR2_DBManager::get_master_connection();
        $s = "select src_id from source $where";
        $q = "select count(*) from src_outcome where sout_out_id=? and sout_src_id in ($s)";
        $stats['duplicate'] += $conn->fetchOne($q, array($outcome->out_id), 0);

        // insert
        $user_id = $outcome->UpdUser->user_id;
        $s = "select ?, src_id, ?, ?, ?, ?, ? from source $where";
        $q = "insert ignore into src_outcome (sout_out_id,sout_src_id, sout_type, sout_cre_user, sout_cre_dtim, sout_upd_user, sout_upd_dtim) $s";
        $stats['insert'] += $conn->exec($q, array($outcome->out_id, $type, $user_id, air2_date(), $user_id, air2_date()));
        $stats['invalid'] += ($stats['total'] - $stats['insert'] - $stats['duplicate']);
        return $stats;
    }

 	/**
     * Add sources to a PINfluence
     *
     * @param  Outcome  $outcome
     * @param  Bin      $bin
     * @param  string   $type
     */
    public static function add_sources_from_bin($outcome, $bin, $type) {
        $stats = array('total' => 0, 'insert' => 0, 'duplicate' => 0, 'invalid' => 0);
        $bin_id = $bin->bin_id;
        $b_where = "where bsrc_bin_id=$bin_id"; //hardcode so i don't get mixed up

        // totals
        $conn = AIR2_DBManager::get_master_connection();
        $stats['total'] = $conn->fetchOne("select count(*) from bin_source $b_where", array(), 0);

        // duplicates
        $b_s = "select bsrc_src_id from bin_source $b_where";
        $b_q = "select count(*) from src_outcome where sout_out_id=? and sout_src_id in ($b_s)";

        $stats['duplicate'] += $conn->fetchOne($b_q, array($outcome->out_id), 0);

        // insert
        $user_id = $outcome->UpdUser->user_id;
        $s_where = "where src_id in ($b_s)";
        $s_s = "select ?, src_id, ?, ?, ?, ?, ? from source $s_where";

        $s_q = "insert ignore into src_outcome (sout_out_id,sout_src_id, sout_type, sout_cre_user, sout_cre_dtim, sout_upd_user, sout_upd_dtim) $s_s";
        $stats['insert'] += $conn->exec($s_q, array($outcome->out_id, $type, $user_id, air2_date(), $user_id, air2_date()));
        $stats['invalid'] += ($stats['total'] - $stats['insert'] - $stats['duplicate']);
        return $stats;
    }


	/**
     * Helper to get a where condition for input data, and setup the
     * stats array.  Will return a string on success, or false if no
     * idents were provided.
     *
     * @param  array  $idents
     * @param  array  $stats
     * @param  string $tbl (src or srs)
     * @return string $where_str
     */
    protected static function get_where_condition($idents, &$stats, $tbl='src') {
        self::init_stats($stats);
        if (is_string($idents)) {
            $idents = array($idents);
        }
        if (!is_array($idents)) {
            return false;
        }

        // calculate total
        $total = count($idents);
        if ($total == 0) return false;

        // some stat counts
        if (isset($stats['total'])) $stats['total'] = $total;
        $idents = array_unique($idents);
        $dups = $total - count($idents);
        if (isset($stats['duplicate'])) $stats['duplicate'] = $dups;

        // detect src_id's or src_uuid's
        if (is_string($idents[0]) && strlen($idents[0]) == 12) {
            $uuid_str = air2_array_to_string($idents);
            return "where {$tbl}_uuid in ($uuid_str)";
        }
        else {
            $id_str = implode(',', $idents);
            return "where {$tbl}_id in ($id_str)";
        }
    }

    /**
     * Initialize an array of stats at counts 0
     *
     * @param  array $stat_counts
     * @return array $stat_counts
     */
    protected static function init_stats(&$stat_counts) {
        $stat_counts = array_flip($stat_counts);
        foreach ($stat_counts as $key => $val) {
            $stat_counts[$key] = 0;
        }
        return $stat_counts;
    }

}
