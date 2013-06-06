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

require_once 'Search_Proxy.php';

/**
 * Dashboard Controller
 *
 * @author pkarman
 * @package default
 */
class Dashboard_Controller extends AIR2_Controller {


    /**
     * Public dashboard html page
     */
    public function index() {
        // only html
        if ($this->view != 'html') {
            show_error('Only HTML view available', 415);
        }

        $inline = array(
            'ORGDATA' => $this->get_all_orgs_by_uuid(),
        );

        // show page
        $title = "Dashboard - ".AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_inline($title, 'Dashboard', $inline);
        $this->response($data);
    }


    /**
     * Placeholder for single-org page
     */
    public function summary() {
        if ($this->response_view == 'html') {
            $this->show_415();
        }
        if ($this->response_view == 'json') {
            $this->response(array('foo' => 'bar'));
        }


    }


    /**
     * Get an associative-array of organizations, keyed by org_uuid
     *
     * @return array
     */
    private function get_all_orgs_by_uuid() {
        $q = Doctrine_Query::create()->from('Organization');
        $q->orderBy('org_display_name asc');
        if (!$this->user->is_system()) {
            $org_ids = array_keys($this->user->get_authz());
            $q->andWhereIn('org_id', $org_ids);
        }
        $related_orgs = $q->fetchArray();

        // fetch each org by itself
        $orgs = array();
        foreach ($related_orgs as $org) {
            $uuid = $org['org_uuid'];
            $orgs[] = $this->api->fetch("organization/$uuid");
        }
        return $orgs;
    }


    /**
     * Get stats data for an organization
     *
     * @param string $org_uuid
     */
    public function get_org_stats($org_uuid) {
        if ($this->view != 'json') {
            $this->show_415();
        }

        $org = AIR2_Record::find('Organization', $org_uuid);
        if (!$org) {
            show_404();
        }

        // we do our own "view" here since we are just proxying for search server.
        $search_proxy = new Search_Proxy(array(
                'url'           =>  AIR2_SEARCH_URI . '/report/org',
                'cookie_name'   =>  AIR2_AUTH_TKT_NAME,
                'params'        => array(
                    'org_name' => $org->org_name,
                ),
            )
        );
        $response = $search_proxy->response();

        // set headers
        if ($response['response']['http_code'] != 200) {
            header('X-AIR2: server error', false, $response['response']['http_code']);
        }
        if ($this->input->get_post('gzip')) {
            header("Content-Encoding: gzip");
        }
        if (preg_match('/application\/json/', $this->input->server('HTTP_ACCEPT'))) {
            header("Content-Type: application/json; charset=utf-8");
        }
        else {
            header("Content-Type: text/javascript; charset=utf-8");
        }

        // respond
        echo $response['json'];
    }


}
