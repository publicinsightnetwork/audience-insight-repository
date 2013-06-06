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
 * Search Controller
 *
 * @author pkarman
 * @package default
 */
class Search_Controller extends AIR2_Controller {

    // okay parameters to propogate
    protected $PARAMS = array('q', 'F', 'o', 'p', 's', 'd', 'format', 'b', 'start',
        'limit', 'M', 't', 'h', 'c', 'f', 'r');

    // map search-index url to payload data
    protected $IDX = array(
        'sources' => array(
            'view'  => 'search/sources',
            'title' => 'All Sources',
            'idx'   => 'sources',
            'label' => 'All Sources',
        ),
        'active-sources' => array(
            'view'  => 'search/sources',
            'title' => 'Available Sources',
            'idx'   => 'active-sources',
            'label' => 'Available Sources',
        ),
        'primary-sources' => array(
            'view'  => 'search/sources',
            'title' => 'Primary Sources',
            'idx'   => 'primary-sources',
            'label' => 'Primary Sources',
        ),
        'fuzzy-sources' => array(
            'view'  => 'search/sources',
            'title' => 'All Sources',
            'idx'   => 'fuzzy-sources',
            'label' => 'All Sources',
        ),
        'fuzzy-active-sources' => array(
            'view'  => 'search/sources',
            'title' => 'Available Sources',
            'idx'   => 'fuzzy-active-sources',
            'label' => 'Available Sources',
        ),
        'fuzzy-primary-sources' => array(
            'view'  => 'search/sources',
            'title' => 'Primary Sources',
            'idx'   => 'fuzzy-primary-sources',
            'label' => 'Primary Sources',
        ),
        'strict-sources' => array(
            'view'  => 'search/sources',
            'title' => 'All Sources',
            'idx'   => 'strict-sources',
            'label' => 'All Sources',
        ),
        'strict-active-sources' => array(
            'view'  => 'search/sources',
            'title' => 'Available Sources (strict)',
            'idx'   => 'strict-active-sources',
            'label' => 'Available Sources (strict)',
        ),
        'strict-primary-sources' => array(
            'view'  => 'search/sources',
            'title' => 'Primary Sources',
            'idx'   => 'strict-primary-sources',
            'label' => 'Primary Sources',
        ),
        'inquiries' => array(
            'view'     => 'search/inquiries',
            'title'    => 'Queries',
            'idx'      => 'inquiries',
            'all_orgs' => true,
            's'        => 'inq_publish_date DESC',
        ),
        'outcomes' =>  array(
            'view'     => 'search/outcomes',
            'title'    => 'PINfluence',
            'idx'      => 'outcomes',
            'all_orgs' => true,
        ),
        'projects' => array(
            'view'     => 'search/projects',
            'title'    => 'Projects',
            'idx'      => 'projects',
            'all_orgs' => true,
        ),
        'responses' => array(
            'view'  => 'search/responses',
            'title' => 'Submissions',
            'idx'   => 'responses',
        ),
        'fuzzy-responses' => array(
            'view'  => 'search/responses',
            'title' => 'Submissions',
            'idx'   => 'fuzzy-responses',
        ),
        'strict-responses' => array(
            'view'  => 'search/responses',
            'title' => 'Submissions',
            'idx'   => 'strict-responses',
        ),
        'help' => array(
            'view'  => 'search/help',
            'title' => 'Help',
        ),
    );


    /**
     * Public starting point for any calls to this controller
     *
     * (Similar to AIR2_HTML_Controller... TODO: merge them)
     */
    public function index() {
        $args = func_get_args();
        if (count($args) == 1) {
            redirect($this->uri_for("search/sources", $_GET));
        }

        // any path with more than a single uuid is invalid
        if (count($args) != 2) {
            show_404();
        }

        // redirect old url's
        $idx = $args[1];
        if ($idx == 'activesources') {
            redirect($this->uri_for("search/active-sources", $_GET));
        }
        if ($idx == 'primarysources') {
            redirect($this->uri_for("search/primary-sources", $_GET));
        }

        // check for valid index
        if (!isset($this->IDX[$idx])) {
            show_404();
        }

        // only html
        if ($this->view != 'html') {
            show_error('Only HTML view available', 415);
        }
        $this->show_html($this->IDX[$idx]);
    }


    /**
     * Show an html search page
     *
     * @param array $def
     */
    protected function show_html($def) {
        // build payload
        $payload = array();
        if (isset($def['idx'])) {
            $payload['search_idx'] = $def['idx'];
        }
        if (isset($def['label'])) {
            $payload['search_label'] = $def['label'];
        }
        if (isset($def['all_orgs'])) {
            $payload['all_orgs'] = $this->get_all_orgs_by_uuid();
        }
        $payload['c'] = $this;
        $payload['org_names'] = $this->get_organization_names();
        $payload['org_uuids'] = $this->get_organization_uuids();
        $payload['act_names'] = $this->get_activity_names();
        $payload['prj_names'] = $this->get_project_names();
        //$payload['inq_names'] = $this->get_inquiry_names(); // TODO might need to fetch these as needed.
        $payload['use_gzip'] = preg_match('/gzip/', $_SERVER['HTTP_ACCEPT_ENCODING']);

        // params (propagate to search server)
        $payload['params'] = array();
        foreach ($this->PARAMS as $p) {
            // explicitly set default
            if (isset($def[$p])) {
                $payload['params'][$p] = $def[$p];
            }
            // GET param
            if (isset($this->input_all[$p])) {
                $payload['params'][$p] = $this->input_all[$p];
            }
            // set no matter what
            if (!isset($payload['params'][$p])) {
                $payload['params'][$p] = null;
            }
        }
        $payload['q'] = $payload['params']['q'];

        // query (q + F, with explicit AND)
        $payload['query'] = $payload['q'];
        if ($payload['params']['F'] !== null) {
            $payload['query'] .= implode(' ', $payload['params']['F']);
        }

        // show page
        $title = "Search: {$def['title']} - ".AIR2_SYSTEM_DISP_NAME;
        $data = $this->airhtml->get_deprecated_inline($title, $payload, $def['view']);
        $this->response($data);
    }


    /**
     * Parse QUERY_STRING to allow for duplicate values on a single param name.
     *
     * @return array
     */
    private function _parse_query_string() {
        $params = array();
        $qstr = $this->input->server('QUERY_STRING');
        if (!isset($qstr) || !strlen($qstr)) {
            return $params;
        }
        $query  = explode('&', $qstr);
        if (!count($query)) {
            return $params;
        }

        foreach ( $query as $param ) {
            list($name, $value) = explode('=', $param);
            $params[urldecode($name)][] = urldecode($value);
        }

        // single values are not in an array
        foreach ( $params as $key=>$p ) {
            if (count($p) == 1) {
                $params[$key] = $p[0];
            }
        }
        return $params;
    }


    /**
     *
     *
     * @return unknown
     */
    private function get_activity_names() {
        $q = AIR2_Query::create();
        $q->from('ActivityMaster');
        $result = $q->execute(array(), Doctrine_Core::HYDRATE_ON_DEMAND);
        $acts = array();
        foreach ($result as $actm) {
            $acts[$actm->actm_id] = htmlspecialchars($actm->actm_name);
        }
        return $acts;
    }


    /**
     *
     *
     * @return unknown
     */
    private function get_organization_names() {
        $q = AIR2_Query::create();
        $q->from('Organization');   // TODO security filter?
        $q->orderBy('org_display_name ASC');
        $result = $q->execute(array(), Doctrine_Core::HYDRATE_ON_DEMAND);
        $orgs = array();
        foreach ($result as $org) {
            $orgs[$org->org_id] = array(
                'org_display_name' => $org->org_display_name,
                'org_name'  => $org->org_name,
                'org_uuid'  => $org->org_uuid,
                'org_html_color' => $org->org_html_color,
            );
        }
        return $orgs;
    }


    /**
     *
     *
     * @return unknown
     */
    private function get_organization_uuids() {
        $q = AIR2_Query::create();
        $q->from('Organization');   // TODO security filter?
        $result = $q->execute(array(), Doctrine_Core::HYDRATE_ON_DEMAND);
        $orgs = array();
        foreach ($result as $org) {
            $orgs[$org->org_uuid] = $org->org_display_name;
        }
        return $orgs;
    }


    /**
     *
     *
     * @return unknown
     */
    private function get_project_names() {
        $q = AIR2_Query::create();
        $q->from('Project');   // TODO security filter?
        $result = $q->execute(array(), Doctrine_Core::HYDRATE_ON_DEMAND);
        $projects = array();
        foreach ($result as $prj) {
            $projects[$prj->prj_uuid] = htmlspecialchars($prj->prj_display_name);
        }
        return $projects;


    }


    /**
     *
     *
     * @return unknown
     */
    private function get_inquiry_names() {
        $q = AIR2_Query::create();
        $q->from('inquiry');   // TODO security filter?
        $result = $q->execute(array(), Doctrine_Core::HYDRATE_ON_DEMAND);
        $inqs = array();
        foreach ($result as $inq) {
            $inqs[$inq->inq_uuid] = htmlspecialchars($inq->inq_ext_title);
        }
        return $inqs;
    }


    /**
     *
     *
     * @return unknown
     */
    private function get_all_orgs_by_uuid() {
        $q = AIR2_Query::create()->from("Organization");
        $res = $q->execute(array(), Doctrine_Core::HYDRATE_ON_DEMAND);
        $orgs = array();
        foreach ($res as $o) {
            $orgs[$o->org_uuid] = $o->toArray();
        }
        return $orgs;
    }


}
