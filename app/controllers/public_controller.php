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
 * Publishing API controller.
 *
 * @package default
 */
class Public_Controller extends Base_Controller {

    /**
     * Getting the public responses to display
     *
     * @return void
     */
    public function about() {
        if ($this->airoutput->view == 'html') {
            $this->airoutput->view = 'json';
            $this->airoutput->format =
                $this->router->get_content_type_for_view($this->airoutput->view);
        }

        $version = "2.0.0";
        $attributes = array(
            "primary_city",
            "primary_country",
            "primary_county",
            "primary_lat",
            "primary_long",
            "primary_state",
            "primary_postal_code",
            "query_title",
            "query_uuid",
            "src_first_name",
            "src_last_name",
            "srs_upd_dtim",
            "srs_date",
            "questions",
            "responses",
            "lastmod"
        );
        $fields = array(
            "city",
            "country",
            "county",
            "latitude",
            "longitude",
            "state",
            "postal_codee",
            "src_first_name",
            "src_last_name",
            "response",
            "query_title",
            "query_uuid",
            "ques_uuid",
            "ques_value",
            "srs_date",
            "lastmod",
        );
        $params = array(
            'q' => 'query string',
            'a' => 'API key',
            't' => 'response format (JSON, XML, Tiny, ExtJS)',
        );
        $body = array(
            'name'                 => 'PIN Publishing API',
            'version'              => $version,
            'result_attributes'  => $attributes,
            'searchable_fields'    => $fields,
            'params'               => $params,
        );
        $this->response($body);
    }


    /**
     * Getting the public responses to display
     *
     * @return void
     * @param unknown $inq_uuid (optional)
     */
    public function search($inq_uuid=null) {
        $query_term   = $this->input->get('q');
        $resp_format  = $this->input->get('t');
        $api_key      = $this->input->get('a');
        if (!$resp_format) {
            $resp_format = 'JSON';
        }

        // "view" only used for errors
        // otherwise proxy response sets its own headers

        // we do not have any HTML view, so if that is detected,
        // it was the default. override with our local response format detection.
        if ($this->airoutput->view == 'html') {
            $this->airoutput->view = strtolower($resp_format);
            $this->airoutput->format =
                $this->router->get_content_type_for_view($this->airoutput->view);
        }

        // if t param was missing, use the non-default response
        // format from built-in detection.
        elseif (!$this->input->get('t')) {
            $resp_format = strtoupper($this->airoutput->view);
        }

        $api_key_rec = null;

        if (!strlen($api_key)) {
            $this->response(array('success'=>false, 'error'=>'API Key Required'), 401);
            return;
        }
        else {
            $api_key_rec = APIKey::find('APIKey', $api_key);
            if (!$api_key_rec || !$api_key_rec->ak_approved) {
                $this->response(array('success' => false, 'error' => 'Invalid API Key'), 403);
                return;
            }

            // ok key. log it.
            $ip_address = $this->input->server('REMOTE_ADDR');
            $api_stat = new APIStat();
            $api_stat->APIKey = $api_key_rec;
            $api_stat->as_ip_addr = $ip_address;
            $api_stat->save();
        }

        // validity checks
        if ($this->method != 'GET') {
            header('Allow: GET', true, 405);
            $this->response(array('success'=>false), 405);
            return;
        }

        if (!strlen($query_term)) {
            $this->response(array('success'=>false, 'error'=>'"q" param required'), 400);
            return;
        }

        if ($inq_uuid) {
            $query_term = "(".$query_term.") AND inq_uuid=$inq_uuid";
        }

        $airuser = new AirUser();
        $tkt = $airuser->get_tkt($api_key_rec->ak_email, 0);
        $tktname = null;
        $tktval  = null;
        foreach ($tkt as $k => $v) {
            $tktname = $k;
            $tktval  = $v;
        }

        $opts = array(
            "url"         => AIR2_SEARCH_URI . '/public-responses/search',
            "cookie_name" => $tktname,
            "params"      => array('t' => $resp_format),
            "tkt"         => $tktval,
            "query"       => $query_term,
            "GET"         => true,
        );
        $search_proxy = new Search_Proxy($opts);
        $response     = $search_proxy->response();
        $body         = $response['json'];

        $this->airoutput->format = $response['response']['content_type'];
        $this->airoutput->send_headers( $response['response']['http_code'] );

        // if JSONP requested, wrap response
        if ($this->input->get('callback')) {
            echo $this->input->get('callback') . '(' . $body . ');';
        }
        else {
            echo $body;
        }
    }


}
