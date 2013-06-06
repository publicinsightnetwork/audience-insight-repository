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

require_once 'AIR2_APIController.php';
require_once 'rframe/AIRAPI.php';

/**
 * Submission reader controller
 *
 * Displays a submissions-search result in a generic "inbox" interface,
 * which can be customized for specific search types.  (Like queries).
 *
 * @package default
 * @author rcavis
 **/
class Reader_Controller extends AIR2_Controller {

    protected $default_args = array(
        'lived' => 1,
        'o' => 0,
        'p' => 50,
        's' => 'score desc',
    );
    protected $html_title = 'Submissions Reader';


    /**
     * Index action - pulls search args out of the GET params and passes them
     * along to the search engine.
     */
    public function index() {
        $this->do_search($this->input_all);
    }


    /**
     * Same as index, but from "strict-responses" url.
     */
    public function strict() {
        $this->do_search($this->input_all, array(), true);
    }


    /**
     * Magic path to restrict search to a specific query
     *
     * @param string $inq_uuid
     */
    public function query($inq_uuid=null) {
        $this->search_with_query($inq_uuid, false);
    }


    /**
     * Same as query, but using the strict responses index
     *
     * @param string $inq_uuid
     */
    public function strict_query($inq_uuid=null) {
        $this->search_with_query($inq_uuid, true);
    }


    /**
     * Magic path to mark submissions as read
     *
     * @param string @srs_uuid
     */
    public function read($srs_uuid) {
        $conn = AIR2_DBManager::get_master_connection();
        $srsid = $conn->fetchOne('select srs_id from src_response_set where srs_uuid = ?', array($srs_uuid), 0);
        if (!$srsid) return;
        $now = air2_date();
        $flds  = "usrs_user_id, usrs_srs_id, usrs_read_flag, usrs_cre_dtim, usrs_upd_dtim";
        $ondup = "on duplicate key update usrs_read_flag=1,usrs_upd_dtim='$now'";
        $ins = "insert into user_srs ($flds) values (?,$srsid,1,'$now','$now') $ondup";
        $n = $conn->exec($ins, array($this->user->user_id));
    }


    /**
     * Magic path to mark submissions as unread
     *
     * @param string @srs_uuid
     */
    public function unread($srs_uuid) {
        $conn = AIR2_DBManager::get_master_connection();
        $srsid = $conn->fetchOne('select srs_id from src_response_set where srs_uuid = ?', array($srs_uuid), 0);
        if (!$srsid) return;
        $now = air2_date();
        $flds  = "usrs_user_id, usrs_srs_id, usrs_read_flag, usrs_cre_dtim, usrs_upd_dtim";
        $ondup = "on duplicate key update usrs_read_flag=0,usrs_upd_dtim='$now'";
        $ins = "insert into user_srs ($flds) values (?,$srsid,0,'$now','$now') $ondup";
        $n = $conn->exec($ins, array($this->user->user_id));
    }


    /**
     * Magic path to mark submissions as favorite
     *
     * @param string @srs_uuid
     */
    public function favorite($srs_uuid) {
        $conn = AIR2_DBManager::get_master_connection();
        $srsid = $conn->fetchOne('select srs_id from src_response_set where srs_uuid = ?', array($srs_uuid), 0);
        if (!$srsid) return;
        $now = air2_date();
        $flds  = "usrs_user_id, usrs_srs_id, usrs_favorite_flag, usrs_cre_dtim, usrs_upd_dtim";
        $ondup = "on duplicate key update usrs_favorite_flag=1,usrs_upd_dtim='$now'";
        $ins = "insert into user_srs ($flds) values (?,$srsid,1,'$now','$now') $ondup";
        $n = $conn->exec($ins, array($this->user->user_id));
        air2_touch_stale_record('src_response_set', $srsid);
    }


    /**
     * Magic path to mark submissions as unfavorite
     *
     * @param string @srs_uuid
     */
    public function unfavorite($srs_uuid) {
        $conn = AIR2_DBManager::get_master_connection();
        $srsid = $conn->fetchOne('select srs_id from src_response_set where srs_uuid = ?', array($srs_uuid), 0);
        if (!$srsid) return;
        $now = air2_date();
        $flds  = "usrs_user_id, usrs_srs_id, usrs_favorite_flag, usrs_cre_dtim, usrs_upd_dtim";
        $ondup = "on duplicate key update usrs_favorite_flag=0,usrs_upd_dtim='$now'";
        $ins = "insert into user_srs ($flds) values (?,$srsid,0,'$now','$now') $ondup";
        $n = $conn->exec($ins, array($this->user->user_id));
        air2_touch_stale_record('src_response_set', $srsid);
    }


    /**
     * Helper to run the search with an inq_uuid built-in.
     *
     * @param string  $inq_uuid the inquiry uuid
     * @param boolean $is_strict true to run a strict responses search
     */
    protected function search_with_query($inq_uuid, $is_strict) {
        $rs = $this->api->fetch("inquiry/$inq_uuid");
        if ($rs['code'] < Rframe::OKAY) {
            $status = AIR2_APIController::$API_TO_STATUS[$rs['code']];
            show_error($rs['message'], $status);
        }

        // munge the inq_uuid=1234 into the search query
        $params = $this->input_all;
        if (isset($params['q']) && strlen(trim($params['q'])) > 0) {
            $params['q'] .= " inq_uuid=$inq_uuid";
        }
        else {
            $params['q'] = "inq_uuid=$inq_uuid";
        }

        // default to sorting by received date
        if (!isset($params['s']) || strlen(trim($params['s'])) < 1) {
            $params['s'] = 'srs_date desc';
        }

        // search, adding the inquiry to the inline data
        $inline = array('INQUIRY' => $rs);
        $this->do_search($params, $inline, $is_strict);
    }


    /**
     * Helper function to execute a search, and return the proper
     * inline-html data that the view can understand.
     *
     * @param array $params the search parameters
     * @param array $inline extra inline data to include
     */
    protected function do_search($params, $inline=array(), $is_strict=false) {
        $params['i'] = $is_strict ? 'strict-responses' : 'responses'; //force

        // combine with default args and run the search query
        $params = array_merge($this->default_args, $params);
        $rs = $this->api->query('search', $params);

        // abort on search errors
        if ($rs['code'] < Rframe::OKAY) {
            //Carper::carp(var_export($rs,true));
            $status = AIR2_APIController::$API_TO_STATUS[$rs['code']];
            $err = 'Unknown error';
            if (isset($rs['json'])) {
                $json = json_decode($rs['json'], true);
                if ($json) {
                    $err = $json['error'];
                }
            }
            elseif (isset($rs['error'])) {
                $err = $rs['error'];
            }
            elseif (isset($rs['message'])) {
                $err = $rs['message'];
            }
            show_error($err, $status);
        }

        // attempt to json-decode the search response
        $json = json_decode($rs['json'], true);
        if (!$json) {
            show_error('json_decode error from search server', 500);
        }

        // fetch data about the remote user
        $uid = $this->user->user_uuid;
        $rs = $this->api->fetch("user/$uid");
        $self_user = $rs['radix'];

        // show page
        $inline['SEARCH'] = $json;
        $inline['ARGS'] = $params;
        $inline['USER'] = $self_user;
        $title = $this->html_title.' - '.AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'Reader', $inline);
        $this->response($data);
    }


}
