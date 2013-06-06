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
require_once 'querybuilder/AIR2_QueryBuilder.php';

/**
 * Query Controller
 *
 * @author rcavis
 * @package default
 */
class Query_Controller extends AIR2_HTMLController {

    // this is actually a view on the 'inquiry' resource
    protected $alt_resource_name = 'inquiry';

    /**
     * Load inline HTML
     *
     * @param type    $uuid
     * @param type    $base_rs
     */
    protected function show_html($uuid, $base_rs) {
    
        $inq = AIR2_Record::find('Inquiry', $uuid);
    
        // redmine #7794 adminstrative queries disallowed for non-system users
        if (!$this->user->is_system()) { 
            if ($inq && $inq->inq_type == Inquiry::$TYPE_MANUAL_ENTRY) {
                $this->airoutput->write_error(403, 'Query for internal use only', 'This query is for internal use only');
                return;
            }
        }

        $search_query = array('q' => "inq_uuid=$uuid");

        $inline = array(
            // base data
            'UUID' => $base_rs['uuid'],
            'URL'  => air2_uri_for($base_rs['path']),
            'BASE' => $base_rs,
            // related data
            'QUESDATA'  => $this->api->query("inquiry/$uuid/question", array('limit' => 0, 'sort' => 'ques_dis_seq asc')),
            'QUESTPLS'  => AIR2_QueryBuilder::get_defs(),
            'QUESURL'   => air2_uri_for("inquiry/$uuid/question"),
            'ORGDATA'   => $this->api->query("inquiry/$uuid/organization", array('sort' => 'org_display_name asc')),
            'PROJDATA'  => $this->api->query("inquiry/$uuid/project", array('sort' => 'prj_display_name asc')),
            'OUTDATA'   => $this->api->query("inquiry/$uuid/outcome", array('limit' => 4)),
            'OUTSRCH'   => air2_uri_for('search/outcomes', $search_query),
            'ANNOTDATA' => $this->api->query("inquiry/$uuid/annotation", array('limit' => 3, 'sort' => 'inqan_cre_dtim desc')),
            'TAGDATA'   => $this->api->query("inquiry/$uuid/tag", array('limit' => 0)),
            'STATSDATA' => $this->_stats_data($inq),
            'SUBMDATA'  => $this->api->query("inquiry/$uuid/submission", array('limit' => 5)),
            'SUBMSRCH'  => air2_uri_for("reader/query/$uuid"),
            'ACTIVDATA' => $this->api->query("inquiry/$uuid/activity", array('limit' => 5)),
            'AUTHORDATA' => $this->api->query("inquiry/$uuid/author", array('limit' => 5)),
            'WATCHERDATA' => $this->api->query("inquiry/$uuid/watcher", array('limit' => 5)),
        );

        // show page
        $title = $base_rs['radix']['inq_ext_title'].' - '.AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'Inquiry', $inline);
        $this->response($data);
    }


    /**
     * Get some raw statistics for a specific inquiry.
     *
     * @param string  $uuid
     * @return array
     */
    private function _stats_data($inquiry) {
        $conn = AIR2_DBManager::get_connection();
        $id = $inquiry->inq_id;
        $radix = array('inq_uuid' => $inquiry->inq_uuid);
        $status = array(
            SrcInquiry::$STATUS_COMPLETE,
            SrcInquiry::$STATUS_AIR1
        );

        // find when the inquiry was sent, and by whom
        $select = 'select user_first_name, user_last_name, user_username, ' .
            'user_type, DATE(si_cre_dtim) as sent_date, count(*) as sent_count';
        $from = 'from src_inquiry join user on (si_cre_user = user_id)';
        $group = 'group by si_inq_id, si_cre_user, sent_date';
        $order = 'order by sent_date desc';
        $q = "$select $from where si_inq_id = $id and si_status in (?, ?, ?) $group $order";
        $radix['SentBy'] = $conn->fetchAll($q, $status);

        // submission total
        $q = "select count(*) from src_response_set where srs_inq_id = ($id)";
        $radix['recv_count'] = $conn->fetchOne($q, array(), 0);

        // published submissions total
        $radix['published_submissions_count'] = $inquiry->has_published_submissions();

        // emails sent total
        $q = "select count(*) from src_inquiry where si_inq_id = $id and si_status in (?, ?, ?)";
        $radix['sent_count'] = $conn->fetchOne($q, $status, 0);

        return array(
            'success' => true,
            'radix' => $radix,
            'meta'=> array(
                'identifier' => 'inq_uuid',
                'fields' => array('inq_uuid', 'SentBy', 'published_submissions_count', 'recv_count', 'sent_count'),
            ),
        );
    }


}
