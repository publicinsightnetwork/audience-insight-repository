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
 * @author rcavis
 * @package default
 */
abstract class AIR2Bin {


    /**
     * Add sources to a bin
     *
     * @param  Bin    $bin
     * @param  array  $idents
     * @param  string $notes
     * @return array  $counts
     */
    public static function add_sources($bin, $idents, $notes=null) {
        $stats = array('total', 'insert', 'duplicate', 'invalid');
        $where = self::get_where_condition($idents, $stats);
        if (!$where) return $stats;

        // duplicates
        $conn = AIR2_DBManager::get_master_connection();
        $s = "select src_id from source $where";
        $q = "select count(*) from bin_source where bsrc_bin_id=? and bsrc_src_id in ($s)";
        $stats['duplicate'] += $conn->fetchOne($q, array($bin->bin_id), 0);

        // insert
        $s = "select ?, src_id, ? from source $where";
        $q = "insert ignore into bin_source (bsrc_bin_id,bsrc_src_id,bsrc_notes) $s";
        $stats['insert'] += $conn->exec($q, array($bin->bin_id, $notes));
        $stats['invalid'] += ($stats['total'] - $stats['insert'] - $stats['duplicate']);
        return $stats;
    }


    /**
     * Add submissions to a bin, and make sure their sources are in
     * there too.
     *
     * @param  Bin    $bin
     * @param  array  $idents
     * @param  string $notes
     * @return array  $counts
     */
    public static function add_submissions($bin, $idents, $notes=null) {
        $stats = array('total', 'insert', 'duplicate', 'invalid');
        $where = self::get_where_condition($idents, $stats, 'srs');
        if (!$where) return $stats;

        // duplicates
        $conn = AIR2_DBManager::get_master_connection();
        $s = "select srs_id from src_response_set $where";
        $q = "select count(*) from bin_src_response_set where bsrs_bin_id=? and bsrs_srs_id in ($s)";
        $stats['duplicate'] += $conn->fetchOne($q, array($bin->bin_id), 0);

        // insert submissions
        $s = "select ?, srs_id, srs_inq_id, srs_src_id from src_response_set $where";
        $q = "insert ignore into bin_src_response_set (bsrs_bin_id,bsrs_srs_id,bsrs_inq_id,bsrs_src_id) $s";
        $stats['insert'] += $conn->exec($q, array($bin->bin_id));
        $stats['invalid'] += ($stats['total'] - $stats['insert'] - $stats['duplicate']);

        // make sure the sources are there (quietly)
        $s = "select srs_id from src_response_set $where";
        $q = "select bsrs_src_id from bin_src_response_set where bsrs_bin_id=? and bsrs_srs_id in ($s)";
        $src_ids = $conn->fetchColumn($q, array($bin->bin_id), 0);
        self::add_sources($bin, $src_ids, $notes);
        return $stats;
    }


    /**
     * Add the contents of a tank to a bin.  (Will only add tank_sources
     * that are fully imported into the proper AIR tables)
     *
     * @param  Bin    $bin
     * @param  Tank   $tank
     * @param  string $notes
     * @return array  $counts
     */
    public static function add_tank($bin, $tank, $notes=null) {
        $stats = self::init_stats($stats = array('total', 'insert', 'duplicate', 'invalid'));
        $stat1 = TankSource::$STATUS_RESOLVED;
        $stat2 = TankSource::$STATUS_DONE;
        $where = "where tsrc_tank_id=? and (tsrc_status='$stat1' or tsrc_status='$stat2') and src_id is not null";

        // totals
        $conn = AIR2_DBManager::get_master_connection();
        $stats['total'] = $conn->fetchOne("select count(*) from tank_source $where", array($tank->tank_id), 0);
        $distinct = $conn->fetchOne("select count(distinct(src_id)) from tank_source $where", array($tank->tank_id), 0);
        $stats['duplicate'] = $stats['total'] - $distinct;

        // duplicates
        $s = "select bsrc_src_id from bin_source where bsrc_bin_id=?";
        $q = "select count(*) from tank_source $where and src_id in ($s)";
        $stats['duplicate'] += $conn->fetchOne($q, array($tank->tank_id, $bin->bin_id), 0);

        // insert
        $s = "select ?, src_id, ? from tank_source $where and src_id in (select src_id from source)";
        $q = "insert ignore into bin_source (bsrc_bin_id,bsrc_src_id,bsrc_notes) $s";
        $stats['insert'] += $conn->exec($q, array($bin->bin_id, $notes, $tank->tank_id));
        $stats['invalid'] += ($stats['total'] - $stats['insert'] - $stats['duplicate']);
        return $stats;
    }


    /**
     * Add the contents of one bin to another
     *
     * @param  Bin    $bin
     * @param  Bin    $bin_from
     * @param  string $notes
     * @return array  $counts
     */
    public static function add_bin($bin, $bin_from, $notes=null) {
        $stats = self::init_stats($stats = array('total', 'insert', 'duplicate', 'invalid'));
        $from_id = $bin_from->bin_id;
        $where = "where bsrc_bin_id=$from_id"; //hardcode so i don't get mixed up

        // totals
        $conn = AIR2_DBManager::get_master_connection();
        $stats['total'] = $conn->fetchOne("select count(*) from bin_source $where", array(), 0);

        // insert
        $s = "select ?, bsrc_src_id, ? from bin_source $where";
        $q = "insert ignore into bin_source (bsrc_bin_id,bsrc_src_id,bsrc_notes) $s";
        $stats['insert'] += $conn->exec($q, array($bin->bin_id, $notes));
        $stats['duplicate'] += ($stats['total'] - $stats['insert']);

        // quietly insert any submissions
        $where = "where bsrs_bin_id=$from_id";
        $s = "select ?, bsrs_srs_id, bsrs_inq_id, bsrs_src_id from bin_src_response_set $where";
        $q = "insert ignore into bin_src_response_set (bsrs_bin_id,bsrs_srs_id,bsrs_inq_id,bsrs_src_id) $s";
        $conn->exec($q, array($bin->bin_id));
        return $stats;
    }


    /**
     * Add the results of a search (submissions or source) to a bin
     *
     * @param  User   $u
     * @param  Bin    $bin
     * @param  array  $params
     * @param  string $notes
     * @return array  $counts
     */
    public static function add_search($u, $bin, $params, $notes=null) {
        if (!isset($params['i']) || !isset($params['q']) || !isset($params['total'])) {
            throw new Exception("Invalid search parameters - req'd: i, q, total");
        }
        $i = $params['i'];
        $q = $params['q'];
        $M = isset($params['M']) ? $params['M'] : null;
        $total = $params['total'];

        // sanity check
        $valid_indexes = array(
            'sources',
            'active-sources',
            'primary-sources',
            'responses',
            'fuzzy-sources',
            'fuzzy-active-sources',
            'fuzzy-primary-sources',
            'fuzzy-responses',
            'strict-sources',
            'strict-active-sources',
            'strict-primary-sources',
            'strict-responses',
        );
        if (!in_array($i, $valid_indexes)) {
            throw new Exception("Invalid search type '$i'");
        }

        // make sure we have an auth tkt
        $tkt = isset($_COOKIE[AIR2_AUTH_TKT_NAME]) ? $_COOKIE[AIR2_AUTH_TKT_NAME] : null;
        if (!$tkt) {
            $airuser = new AirUser();
            $tkt = $airuser->get_tkt($u->user_username, $u->user_id);
            $tkt = $tkt[AIR2_AUTH_TKT_NAME];
        }

        // call the search server
        $proxy = new Search_Proxy(array(
            'url'         => sprintf("%s/%s/search", AIR2_SEARCH_URI, $i),
            'cookie_name' => AIR2_AUTH_TKT_NAME,
            'query'       => $q,
            'params'      => array('u' => 1, 'limit' => $total, 'M' => $M),
            'tkt'         => $tkt,
            'GET'         => true,
        ));
        $rsp = $proxy->response();
        //error_log(var_export($rsp, 1));
        $json = json_decode($rsp['json'], true);
        if (!$json['success']) {
            throw new Exception("Search server returned error: " . $json['error']);
        }

        // check the total against the expected total
        if ($json['total'] != $total) {
            throw new Exception("Search returned unexpected total! Expected ".$json['total'].
                ", got $rsp_total. Aborting operation!");
        }

        // add sources or responses
        if ($i == 'responses' || $i == 'fuzzy-responses' || $i == 'strict-responses') {
            return self::add_submissions($bin, $json['results'], $notes);
        }
        else {
            return self::add_sources($bin, $json['results'], $notes);
        }
    }


    /**
     * Remove sources from a bin, and any src_response_sets that happen
     * to be under those sources.
     *
     * @param  Bin    $bin
     * @param  array  $idents
     * @return array  $counts
     */
    public static function remove_sources($bin, $idents) {
        $stats = array('total', 'delete', 'duplicate', 'invalid');
        $where = self::get_where_condition($idents, $stats);
        if (!$where) return $stats;

        // delete
        $conn = AIR2_DBManager::get_master_connection();
        $s = "select src_id from source $where";
        $q = "delete from bin_source where bsrc_bin_id=? and bsrc_src_id in ($s)";
        $stats['delete'] = $conn->exec($q, array($bin->bin_id));
        $stats['invalid'] += ($stats['total'] - $stats['delete'] - $stats['duplicate']);

        // delete submissions, but don't record
        $q = "delete from bin_src_response_set where bsrs_bin_id=? and bsrs_src_id in ($s)";
        $conn->exec($q, array($bin->bin_id));
        return $stats;
    }


    /**
     * Remove all sources from a bin, and any src_response_sets that happen
     * to be under those sources.  Providing any idents will exclude those
     * sources from the delete
     *
     * @param  Bin    $bin
     * @param  array  $idents
     * @return array  $counts
     */
    public static function remove_all_sources($bin, $idents) {
        $stats = array('save', 'delete', 'duplicate', 'invalid');
        $where = self::get_where_condition($idents, $stats);

        // delete
        $conn = AIR2_DBManager::get_master_connection();
        $q = "delete from bin_source where bsrc_bin_id=?";
        if ($where) {
            $s = "select src_id from source $where";
            $q .= " and bsrc_src_id not in ($s)";
        }
        $stats['delete'] = $conn->exec($q, array($bin->bin_id));
        $count = 'select count(*) from bin_source where bsrc_bin_id=?';
        $stats['save'] = $conn->fetchOne($count, array($bin->bin_id), 0);
        $stats['invalid'] += ($stats['save'] - $stats['delete'] - $stats['duplicate']);

        // delete submissions, but don't record
        $leftovers = "select bsrc_src_id from bin_source where bsrc_bin_id=?";
        $q = "delete from bin_src_response_set where bsrs_bin_id=? and bsrs_src_id not in ($leftovers)";
        $conn->exec($q, array($bin->bin_id, $bin->bin_id));
        return $stats;
    }


    /**
     * Create new bins, with random content from an original bin
     *
     * @param  User   $u
     * @param  Bin    $bin
     * @param  array  $params
     * @return array  $counts
     */
    public static function randomize($u, $bin, $params) {
        $stats = self::init_stats($stats = array('total', 'insert', 'duplicate', 'invalid'));
        $stats['bin_uuids'] = array();
        $num = isset($params['num']) ? $params['num'] : 1;
        $size = isset($params['size']) ? $params['size'] : null;

        // sanity checking
        $conn = AIR2_DBManager::get_master_connection();
        $q = "select count(*) from bin_source where bsrc_bin_id = ?";
        $total = $conn->fetchOne($q, array($bin->bin_id), 0);
        if ($num < 0 || $num > 20 || $num > $total) {
            throw new Exception("Invalid num $num for randomize!");
        }
        if ($size && ($size < 1 || $size * $num > $total)) {
            throw new Exception("Invalid size $size for randomize (total=$total num=$num)!");
        }

        // calculate size of each bin
        $bin_sizes = array_fill(0, $num, $size ? $size : 0);
        if (!$size) {
            $sz_idx = 0;
            for ($i=0; $i < $total; $i++) {
                $bin_sizes[$sz_idx]++;
                $sz_idx = ($sz_idx + 1) % $num;
            }
        }

        // select in random order (mysql does this faster now than previous versions)
        $q = "select bsrc_src_id from bin_source where bsrc_bin_id = ? order by RAND()";
        if ($size) $q .= " limit ".($num * $size);
        $src_ids = $conn->fetchColumn($q, array($bin->bin_id), 0);

        // create bins, and insert items
        $curr_offset = 0;
        foreach ($bin_sizes as $bidx => $bsize) {
            $b = new Bin();
            $b->bin_user_id = $u->user_id;
            $b->bin_name = "{$bin->bin_name} - Random ".($bidx+1);
            $b->bin_desc = "Random output from bin: '{$bin->bin_name}'";
            $b->save();
            $stats['bin_uuids'][] = $b->bin_uuid;

            $add_ids = array_slice($src_ids, $curr_offset, $bsize);
            $curr_offset += $bsize;
            $bstats = AIR2Bin::add_sources($b, $add_ids);
            $stats['insert'] += $bstats['insert'];
            $stats['total'] += $bstats['total'];
        }
        return $stats;
    }


    /**
     * Tag sources in a bin (must have read-authz on the actual source)
     *
     * @param  User   $u
     * @param  Bin    $bin
     * @param  array  $params
     * @return array  $counts
     */
    public function tag_sources($u, $bin, $params) {
        $stats = self::init_stats($stats = array('total', 'insert', 'duplicate', 'invalid'));

        // validate params
        if (is_string($params) && strlen($params) > 0) {
            $tm_id = TagMaster::get_tm_id($params);
        }
        else if (is_array($params) || is_int($params)) {
            $tm_id = isset($params['tm_id']) ? $params['tm_id'] : $params;
            $tm = AIR2_Record::find('TagMaster', $tm_id);
            if (!$tm) throw new Exception("Invalid tm_id($tm_id)");
        }
        else {
            throw new Exception('Invalid params for bulk tagging');
        }

        // calculate total
        $conn = AIR2_DBManager::get_master_connection();
        $q = "select count(*) from bin_source where bsrc_bin_id = ?";
        $stats['total'] = $conn->fetchOne($q, array($bin->bin_id), 0);

        // duplicates
        $read_org_ids = $u->get_authz_str(ACTION_ORG_SRC_READ, 'soc_org_id');
        $cache = "select soc_src_id from src_org_cache where $read_org_ids";
        $where = "where bsrc_bin_id=? and bsrc_src_id in ($cache)";
        $src_ids = "select bsrc_src_id from bin_source $where";
        $tags = "tag_tm_id=$tm_id and tag_ref_type='S' and tag_xid in ($src_ids)";
        $q = "select count(*) from tag where $tags";
        $stats['duplicate'] = $conn->fetchOne($q, array($bin->bin_id), 0);

        // fast-sql insert
        $select = "select bsrc_src_id,'S',$tm_id,?,?,?,? from bin_source $where";
        $flds = 'tag_xid,tag_ref_type,tag_tm_id,tag_cre_user,tag_upd_user,tag_cre_dtim,tag_upd_dtim';
        $ins  = "insert ignore into tag ($flds) $select";
        $params = array($u->user_id, $u->user_id, air2_date(), air2_date(), $bin->bin_id);
        $stats['insert'] = $conn->exec($ins, $params);

        // invalid == no authz on source
        $stats['invalid'] = ($stats['total'] - $stats['insert'] - $stats['duplicate']);
        return $stats;
    }



    /**
     * Annotate sources in a bin (must have write-authz on the actual source)
     *
     * @param  User   $u
     * @param  Bin    $bin
     * @param  array  $note
     * @return array  $counts
     */
    public function annotate_sources($u, $bin, $note) {
        $stats = self::init_stats($stats = array('total', 'insert', 'duplicate', 'invalid'));

        // validate note
        $note = is_string($note) ? trim($note) : $note;
        if (!$note || !strlen($note)) {
            throw new Exception("Invalid annotation '$note'");
        }

        // calculate total
        $conn = AIR2_DBManager::get_master_connection();
        $q = "select count(*) from bin_source where bsrc_bin_id = ?";
        $stats['total'] = $conn->fetchOne($q, array($bin->bin_id), 0);

        // fast-sql insert
        $read_org_ids = $u->get_authz_str(ACTION_ORG_SRC_UPDATE, 'soc_org_id');
        $cache = "select soc_src_id from src_org_cache where $read_org_ids";
        $where = "where bsrc_bin_id=? and bsrc_src_id in ($cache)";
        $select = "select bsrc_src_id,?,?,?,?,? from bin_source $where";
        $flds = 'srcan_src_id,srcan_value,srcan_cre_user,srcan_upd_user,srcan_cre_dtim,srcan_upd_dtim';
        $ins  = "insert into src_annotation ($flds) $select";
        $params = array($note, $u->user_id, $u->user_id, air2_date(), air2_date(), $bin->bin_id);
        $stats['insert'] = $conn->exec($ins, $params);

        // invalid == no write-authz on source
        $stats['invalid'] = ($stats['total'] - $stats['insert'] - $stats['duplicate']);
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
