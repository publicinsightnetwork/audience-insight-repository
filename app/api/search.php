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

require_once 'rframe/AIRAPI_Resource.php';
require_once 'Search_Proxy.php';

/**
 * Search API
 *
 * TODO: make this more standardized, and better describe()'d.
 *
 * @author rcavis
 * @package default
 */
class AAPI_Search extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query');
    protected $QUERY_ARGS  = array('gzip', 'i', 'q', 'F', 'o', 'p', 's',
        't', 'M', 'format', 'b', 'h', 'c', 'f', 'r', 'lived');
    protected $limit_param  = 'limit';
    protected $offset_param = 'start';
    protected $sort_param   = null;
    protected $ident = 'id'; //dummy


    // map status codes to API codes
    protected static $STAT_TO_API = array(
        200 => AIRAPI::OKAY,
        400 => AIRAPI::BAD_DATA,
        401 => AIRAPI::BAD_AUTHZ,
        403 => AIRAPI::BAD_AUTHZ,
        404 => AIRAPI::BAD_DATA,
        500 => AIRAPI::BAD_DATA,
    );


    /**
     * Don't allow the usual search/authz params
     *
     * @param Rframe_Parser $parser
     * @param array         $path
     * @param array         $inits
     */
    public function __construct($parser, $path=array(), $inits=array()) {
        parent::__construct($parser, $path, $inits);
        air2_array_remove($this->search_param, $this->QUERY_ARGS);
        air2_array_remove($this->authz_read_param, $this->QUERY_ARGS);
        air2_array_remove($this->authz_write_param, $this->QUERY_ARGS);
        air2_array_remove($this->authz_manage_param, $this->QUERY_ARGS);
    }


    /**
     * Just redirect to the search server
     *
     * @param array $args
     */
    public function query($args=array()) {
        $add_live_data = isset($args['lived']) && $args['lived'];
        unset($args['lived']);

        $idx = isset($args['i']) ? $args['i'] : 'active-sources';

        $opts = array(
            'url'         => sprintf("%s/%s/search", AIR2_SEARCH_URI, $idx),
            'cookie_name' => AIR2_AUTH_TKT_NAME,
            'params'      => $args,
            'GET'         => true,
        );
        $search_proxy = new Search_Proxy($opts);
        $rs = $search_proxy->response();

        // record zippyness
        // detect gzip magic bytes since we've already discarded the HTTP headers
        $zip = false;
        if (substr($rs['json'], 0, 2) == "\x1f\x8b") {
            $zip = true;
        }
        $rs['gzip'] = $zip;

        // set a code, based on response
        $code = AIRAPI::BAD_DATA;
        $htc = $rs['response']['http_code'];
        if (isset(self::$STAT_TO_API[$htc])) {
            $code = self::$STAT_TO_API[$htc];
        }

        // add live data to the search response
        if ($add_live_data && $code == AIRAPI::OKAY) {
            $index = isset($args['i']) ? $args['i'] : null;
            $this->add_live_data($rs['json'], $zip, $index);
        }

        /*
         * Add some extra 'AIRAPI'-ish data to response. Note that this won't make
         * it to the browser, because search results are handled specially by air2.
         */
        $rs['method'] = 'query';
        $rs['success'] = ($code == AIRAPI::OKAY);
        $rs['code'] = $code;
        $rs['api'] = $this->describe();
        return $rs;
    }


    /**
     * Add some live database data to the returning search response.
     *
     * Currently only enabled for the responses index.
     *
     * @param string $response_json
     * @param bool   $is_zipped
     * @param string $index
     */
    protected function add_live_data(&$response_json, $is_zipped, $index) {
        if ($index != 'responses' && $index != 'strict-responses') return;
        if (!$response_json) return;

        // unzip/decode - return on failure
        $json = $response_json;
        if ($is_zipped) {
            $json = gzinflate(substr($json, 10, -8));
        }
        $json = json_decode($json, true);
        if (!$json || $json['total'] == 0) return;

        // collect srs_id's (TODO: other index ids)
        $ids = array();
        foreach ($json['results'] as $row) {
            if (isset($row['srs_id'])) $ids[] = $row['srs_id'];
        }
        if (count($ids) == 0) return;

        // add stuff into it
        $this->_add_visits($json, $index, $ids);
        $this->_add_tags($json, $index, $ids);
        $this->_add_srsan_counts($json, $index, $ids);
        $this->_add_sran_counts($json, $index, $ids);

        // re-encode
        $json = json_encode($json);
        if ($is_zipped) {
            $json = gzencode($json);
        }
        $response_json = $json;
    }


    /**
     * Add live_read and live_favorite flags to search responses
     *
     * @param string $data
     * @param string $index
     * @param array  $ids
     */
    private function _add_visits(&$data, $index, $ids) {
        if ($index != 'responses' && $index != 'strict-responses') return;

        // params
        $user_id = $this->user->user_id;
        $xids = implode(',', $ids);

        // fetch user_srs
        $conn = AIR2_DBManager::get_connection();
        $whr = "usrs_user_id=$user_id and usrs_srs_id in ($xids)";
        $sel = "select * from user_srs where $whr";
        $visits = $conn->fetchAll($sel);

        // record any reads/favs
        $reads = array();
        $favs  = array();
        foreach ($visits as $v) {
            if ($v['usrs_read_flag']) $reads []= $v['usrs_srs_id'];
            if ($v['usrs_favorite_flag']) $favs []= $v['usrs_srs_id'];
        }

        // add back into the results
        foreach ($data['results'] as $idx => $row) {
            $srs_id = $row['srs_id'];
            $data['results'][$idx]['live_read'] = in_array($srs_id, $reads);
            $data['results'][$idx]['live_favorite'] = in_array($srs_id, $favs);
        }
        $data['fields'][] = 'live_read';
        $data['fields'][] = 'live_favorite';
        $data['metaData']['fields'][] = 'live_read';
        $data['metaData']['fields'][] = 'live_favorite';
    }


    /**
     * Add live_tags to search responses
     *
     * @param string $data
     * @param string $index
     * @param array  $ids
     */
    private function _add_tags(&$data, $index, $ids) {
        $cfg = array(
            'responses' => array('R', 'srs_id'),
            'strict-responses' => array('R', 'srs_id'),
        );
        if (!isset($cfg[$index])) return;

        // params
        $ref_type = $cfg[$index][0];
        $xids = implode(',', $ids);

        // fetch tags
        $conn = AIR2_DBManager::get_connection();
        $frm = "tag join tag_master on (tag_tm_id=tm_id) left join iptc_master on (tm_iptc_id=iptc_id)";
        $whr = "tag_ref_type='$ref_type' and tag_xid in ($xids)";
        $usg = "(select count(*) from tag t2 where t2.tag_tm_id=tm_id) as usage_count";
        $sel = "iptc_name, tm_name, tm_type, tm_id, tag_xid, $usg";
        $sel = "select $sel from $frm where $whr order by tag_cre_dtim asc";
        $tags = $conn->fetchAll($sel);

        // flip into a lookup hash
        $lookup = array();
        foreach ($tags as $t) {
            $xid  = $t['tag_xid'];
            if (isset($lookup[$xid])) {
                $lookup[$xid][] = $t;
            }
            else {
                $lookup[$xid] = array($t);
            }
        }

        // add back into the results
        foreach ($data['results'] as $idx => $row) {
            $data['results'][$idx]['live_tags'] = array();
            $srs_id = $row['srs_id'];
            if (isset($lookup[$srs_id])) {
                $data['results'][$idx]['live_tags'] = $lookup[$srs_id];
            }
        }
        $data['fields'][] = 'live_tags';
        $data['metaData']['fields'][] = 'live_tags';
    }


    /**
     * Add live_srsan_count to search responses
     *
     * @param string $data
     * @param string $index
     * @param array  $ids
     */
    private function _add_srsan_counts(&$data, $index, $ids) {
        $ids = implode(',', $ids);
        $fld = 'srs_id';
        $fk  = 'srsan_srs_id';
        $tbl = 'srs_annotation';

        // fetch counts
        $conn = AIR2_DBManager::get_connection();
        $sel = "select $fk, count(*) as num from $tbl where $fk in ($ids) group by $fk";
        $annots = $conn->fetchAll($sel);

        $lookup = array();
        foreach ($annots as $ann) {
            $lookup[$ann[$fk]] = $ann['num'];
        }

        // add back into the results
        foreach ($data['results'] as $idx => $row) {
            $data['results'][$idx]['live_srsan_count'] = 0;
            if (isset($lookup[$row[$fld]])) {
                $data['results'][$idx]['live_srsan_count'] = $lookup[$row[$fld]];
            }
        }
        $data['fields'][] = 'live_srsan_count';
        $data['metaData']['fields'][] = 'live_srsan_count';
    }


    /**
     * Add live_sran_counts to search responses
     *
     * @param string $data
     * @param string $index
     * @param array  $ids
     */
    private function _add_sran_counts(&$data, $index, $ids) {
        $ids = implode(',', $ids);
        $ids = "select sr_id from src_response where sr_srs_id in ($ids)";
        $fk  = 'sran_sr_id';
        $tbl = 'sr_annotation';

        // fetch counts
        $conn = AIR2_DBManager::get_connection();
        $sel = "select $fk, count(*) as num from $tbl where $fk in ($ids) group by $fk";
        $annots = $conn->fetchAll($sel);

        $lookup = array();
        foreach ($annots as $ann) {
            $lookup[$ann[$fk]] = $ann['num'];
        }

        // add back into the results
        foreach ($data['results'] as $idx => $row) {
            $data['results'][$idx]['live_sran_counts'] = array();

            $srids = explode(':', $row['sr_ids']);
            foreach ($srids as $sr_id) {
                $count = isset($lookup[$sr_id]) ? $lookup[$sr_id] : 0;
                $data['results'][$idx]['live_sran_counts'][] = $count;
            }
        }
        $data['fields'][] = 'live_sran_counts';
        $data['metaData']['fields'][] = 'live_sran_counts';
    }


}
