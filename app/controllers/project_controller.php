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
 * Project Controller
 *
 * @author rcavis
 * @package default
 */
class Project_Controller extends AIR2_HTMLController {


    /**
     * Load inline HTML
     *
     * @param type $uuid
     * @param type $base_rs
     */
    protected function show_html($uuid, $base_rs) {
        $search_query = array('q' => "prj_uuid=$uuid");
        $inline = array(
            // base data
            'UUID' => $base_rs['uuid'],
            'URL'  => air2_uri_for($base_rs['path']),
            'BASE' => $base_rs,
            // search url's
            'SUBMSRCH' => air2_uri_for('search/responses', $search_query),
            'INQSRCH'  => air2_uri_for('search/queries',   $search_query),
            'SRCSRCH'  => air2_uri_for('search/sources',   $search_query),
            // related data
            'SUBMDATA'  => $this->api->query("project/$uuid/submission", array('limit' => 4)),
            'INQDATA'   => $this->api->query("project/$uuid/inquiry", array('limit' => 5)),
            'ORGDATA'   => $this->api->query("project/$uuid/organization", array('limit' => 4)),
            'OUTDATA'   => $this->api->query("project/$uuid/outcome", array('limit' => 3)),
            'STATSDATA' => $this->_stats_data($uuid),
            'ANNOTDATA' => $this->api->query("project/$uuid/annotation", array('limit' => 3)),
            'ACTIVDATA' => $this->api->query("project/$uuid/activity", array('limit' => 5)),
            'TAGDATA'   => $this->api->query("project/$uuid/tag", array('limit' => 0)), //no limit
        );

        // show page
        $title = $base_rs['radix']['prj_display_name'].' - '.AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'Project', $inline);
        $this->response($data);
    }


    /**
     * Produce custom statistics for Project Dashboard
     *
     * TODO: move this to the API
     *
     * @param string $uuid
     * @return array $data
     */
    private function _stats_data($uuid) {
        // Sources and Submissions (stats) panel data
        $conn = AIR2_DBManager::get_connection();
        $id = "(select prj_id from project where prj_uuid='$uuid')";
        $sent = 0; //$conn->fetchOne(''); TODO: tie to src_activity log
        $recv = $conn->fetchOne("select count(*) from src_response_set where srs_inq_id in (select pinq_inq_id from project_inquiry where pinq_prj_id = $id)");
        $num_src = $conn->fetchOne("select count(distinct(srs_src_id)) from src_response_set where srs_inq_id in (select pinq_inq_id from project_inquiry where pinq_prj_id = $id)");
        $pin_total = $conn->fetchOne("select count(*) from source where src_status = 'A'");

        return array(
            'success' => true,
            'radix' => array(
                'prj_uuid' => $uuid,
                'SubmissionCount' => $recv,
                'SubmissionRate' => ($sent > 0) ? $recv/$sent : 'N/A',
                'SourceCount' => $num_src,
                'SourceRate' => ($pin_total > 0) ? $num_src/$pin_total : 'N/A',
            ),
            'meta' => array(
                'identifier' => 'prj_uuid',
                'fields' => array('prj_uuid', 'SubmissionCount', 'SubmissionRate', 'SourceCount', 'SourceRate'),
            ),
        );
    }


}
