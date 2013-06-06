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

require_once 'AIR2_Controller.php';

/**
 * Controller to route application-data requests to the API, and translate api
 * responses to http responses.
 *
 * @version 1
 * @author rcavis
 * @package default
 */
class AIR2_APIController extends AIR2_Controller {

    // map api code to http status
    public static $API_TO_STATUS = array(
        AIRAPI::BAD_PATH   => 404,
        AIRAPI::BAD_IDENT  => 404,
        AIRAPI::BAD_AUTHZ  => 403,
        AIRAPI::BAD_DATA   => 400,
        AIRAPI::BAD_METHOD => 405,
        AIRAPI::BAD_PATHMETHOD => 405,
        AIRAPI::ONE_EXISTS     => 405,
        AIRAPI::ONE_DNE        => 404,
        AIRAPI::UNKNOWN_ERROR  => 400, //not as extreme as regular exception
        AIRAPI::BGND_CREATE    => 202,
    );

    // json-decoded request radix
    protected $input_radix = array();


    /**
     * Json-decode any 'radix' parameter.
     */
    protected function decode_input() {
        parent::decode_input();
        if (isset($this->input_all['radix'])) {
            $r = $this->input_all['radix'];
            try {
                $this->input_radix = json_decode($r, true);
            }
            catch (Exception $err) {
                show_error("Json decode error: Bad record format in key 'radix'", 400);
            }
        }

        // TODO: how strict should RADIX checking be?
        // sanity check radix
        //$should_have_radix = $this->method == 'POST' || $this->method == 'PUT';
        //if ($should_have_radix && !$this->input_radix) {
        //    show_error("Error: Bad record format in key 'radix'", 400);
        //}

        // attach any "file input" to the radix, in the form of filepaths
        if (is_array($this->input_radix)) {
            foreach ($_FILES as $name => $def) {
                if (!isset($this->input_radix[$name])) {
                    $this->input_radix[$name] = $def;
                }
            }
        }
    }


    /**
     * Route an HTTP request through the AIR2 API, and map the response into
     * HTTP-land.
     */
    public function route_api() {
        $segments = func_get_args();
        $path = implode('/', $segments);
        $rs;

        // determine request type
        if ($this->method == 'GET') {
            unset($this->input_all['_dc']); //unset cache-busting
            $rs = $this->api->query_or_fetch($path, $this->input_all);
        }
        elseif ($this->method == 'POST') {
            $rs = $this->api->create($path, $this->input_radix);
        }
        elseif ($this->method == 'PUT') {
            $rs = $this->api->update($path, $this->input_radix);
        }
        elseif ($this->method == 'DELETE') {
            $rs = $this->api->delete($path);
        }
        else {
            throw new Exception("Unknown request method '$method'");
        }

        // map api-code to http status
        $status;
        $code = $rs['code'];
        if (array_key_exists($code, self::$API_TO_STATUS)) {
            $status = self::$API_TO_STATUS[$code];
        }
        elseif ($code >= AIRAPI::OKAY) {
            $status = 200;
        }
        else {
            throw new Exception("Unknown API code '$code'");
        }

        // redirect a successful proxy resource
        $metatype = isset($rs['meta']['type']) ? $rs['meta']['type'] : null;
        if ($status == 200 && $metatype == 'imageproxy') {
            $url = $rs['radix']['url'];
            $def = null;
            if ($rs['radix']['default']) {
                $def = air2_uri_for('css/img/'.$rs['radix']['default']);
            }
            air2_proxy_image($url, $def);
            exit;
        }
        if ($status == 200 && $metatype == 'fileproxy') {
            $path = $rs['radix']['path'];
            $name = $rs['radix']['name'];
            $size = $rs['radix']['size'];
            $type = $rs['radix']['type'];
            header("Content-Type: $type");
            header("Content-length: $size");
            header("Content-Disposition: attachment; filename=\"$name\"");
            readfile($path);
            exit;
        }

        // special handling for search resource
        if (isset($rs['api']) && $rs['api']['route'] == 'search') {
            $this->handle_search_resource($rs);
            exit;
        }

        // reject html requests (but show the right code)
        if ($this->view == 'html') {
            if ($code >= Rframe::OKAY) {
                show_error('Invalid request type', 415);
            }
            else {
                $msg = isset($rs['message']) ? $rs['message'] : 'Unknown error';
                show_error($msg, $status);
            }
        }

        // respond
        $this->response($rs, $status);
    }


    /**
     * Some special headers/other stuff for search responses
     *
     * @param array $rs
     */
    protected function handle_search_resource($rs) {
        if ($rs['code'] != AIRAPI::OKAY) {
            header('X-AIR2: server error', false, $rs['code']);
        }
        if ($rs['gzip']) {
            header("Content-Encoding: gzip");
        }

        // browsers seem to handle these differently.
        if (preg_match('/application\/json/', $this->input->server('HTTP_ACCEPT'))) {
            header("Content-Type: application/json; charset=utf-8");
        }
        else {
            header("Content-Type: text/javascript; charset=utf-8");
        }

        // return json (possibly compressed)
        echo $rs['json'];
    }

    /**
     * allows subclassess of Base_Controller to override to give an input a pass on xsscleaning
     *
     * @param sttring   $key
     */
    public function allow_through($key) {

        // give air client data an xss pass
        if ($key === 'radix') {
            return true;
        }

        return false;
    }

}
