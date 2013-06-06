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

require_once 'AIR2_HTMLController.php';

/**
 * Source Controller
 *
 * @author rcavis
 * @package default
 */
class Source_Controller extends AIR2_HTMLController {


    /**
     * Load inline HTML
     *
     * @param type $uuid
     * @param type $base_rs
     */
    protected function show_html($uuid, $base_rs) {
        // Record visit by the current user against the current source. See UserVisit model.
        $source = AIR2_Record::find('Source', $uuid);
        $source->visit(
            array(
                'ip' => $this->input->ip_address(),
                'user' => $this->user,
            )
        );

        /**
         * Prep and display page.
         */
        $search_query = array('q' => "src_uuid=$uuid");
        $inline = array(
            // base data
            'UUID' => $base_rs['uuid'],
            'URL'  => air2_uri_for($base_rs['path']),
            'BASE' => $base_rs,
            // search url's
            'SUBMSRCH' => air2_uri_for('search/responses', $search_query),
            // related data
            'ORGDATA'   => $this->api->query("source/$uuid/organization", array('limit' => 5, 'sort' => 'so_home_flag desc,so_status asc,org_display_name asc')),
            'SUBMDATA'  => $this->api->query("source/$uuid/submission", array('limit' => 8, 'sort' => 'srs_date desc,srs_cre_dtim desc')),
            'FACTDATA'  => $this->api->query("source/$uuid/fact", array('limit' => 7, 'sort' => 'fact_id asc')),
            'ACTVDATA'  => $this->api->query("source/$uuid/activity", array('limit' => 5, 'sort' => 'sact_dtim desc')),
            'INTDATA'   => $this->api->query("source/$uuid/interest", array('limit' => 5)),
            'EXPDATA'   => $this->api->query("source/$uuid/experience", array('limit' => 5)),
            'ANNOTDATA' => $this->api->query("source/$uuid/annotation", array('limit' => 4, 'sort' => 'srcan_upd_dtim desc')),
            'TAGDATA'   => $this->api->query("source/$uuid/tag", array('limit' => 0)),
            'OUTDATA'   => $this->api->query("source/$uuid/outcome", array('limit' => 4)),
            'PREFDATA'  => $this->api->query("source/$uuid/preference", array('limit' => 4)),
            'STATSDATA' => $this->_stats_data($uuid),
            // TODO: move to afixture
            'FLDDATA'   => $this->api->query("fact", array('limit' => 0)),
            'PREFSDATA' => $this->api->query("preference", array('pt_identifier'=>'preferred_language','limit' => 0)),
        );

        // show page
        $uname = $base_rs['radix']['src_username'];
        $first = $base_rs['radix']['src_first_name'];
        $last = $base_rs['radix']['src_last_name'];
        $name = ($first && $last) ? "$first $last" : $uname;
        $title = "$name - ".AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'Source', $inline);
        $this->response($data);
    }


    /**
     * Show a special error for AUTHZ
     *
     * @param int $code
     * @param string $msg
     * @param array $rs
     */
    protected function show_html_error($code, $msg, $rs) {
        if ($code == AIRAPI::BAD_AUTHZ) {
            $heading = "403 Not Authorized to View Source";
            $message = "This source has not opted in to your newsroom.";
            $this->airoutput->write_error(403, $heading, $message);
        }
        else {
            return parent::show_html_error($code, $msg, $rs);
        }
    }


    /**
     * Get some raw statistics for a specific source.
     *
     * @param string $uuid
     * @return array
     */
    private function _stats_data($uuid) {
        $conn = AIR2_DBManager::get_connection();
        $id = "(select src_id from source where src_uuid='$uuid')";
        $radix = array('src_uuid' => $uuid);

        // exported in bin
        $q = "select count(*) from src_inquiry where si_src_id = $id";
        $radix['exp_count'] = $conn->fetchOne($q, array(), 0);

        // sent query
        $q = "$q and si_status = ?";
        $radix['sent_count'] = $conn->fetchOne($q, array(SrcInquiry::$STATUS_COMPLETE), 0);

        // responded
        $q = "select count(*) from src_response_set where srs_src_id = $id";
        $radix['resp_count'] = $conn->fetchOne($q, array(), 0);

        return array(
            'success' => true,
            'radix' => $radix,
            'meta'=> array(
                'identifier' => 'src_uuid',
                'fields' => array('src_uuid', 'exp_count', 'sent_count', 'resp_count'),
            ),
        );
    }
}
