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

require_once 'HTTP_Accept.php';

/**
 * AIR2 Router
 *
 * Custom subclass of Router to allow the use of GET, POST, PUT, and DELETE
 * in routing.  Routes can now look like:
 *   $route['bin'] = array(
 *       'GET' => 'bin/findAll',
 *       'POST' => 'bin/create'
 *   );
 *   $route['bin/(:num)/sources'] = array(
 *       'GET' => 'bin/findAllSources/$1'
 *   );
 *
 * @author rcavis
 * @package default
 */
class AIR2_Router extends CI_Router {
    // separate routing for rest-api
    protected $api_class  = 'AIR2_APIController';
    protected $api_method = 'route_api';
    protected $api_routes = array();

    // AIR-specific config
    protected $ctrl_suffix = '_controller';
    protected $force_contenttype_var = 'air2_mismatch_content';

    // request method and formats
    public $http_method;
    public $http_format;
    public $http_view;

    // HTTP config
    protected static $METHODS = array('DELETE', 'GET', 'POST', 'PUT');
    protected static $DEFAULT = 'text/plain'; //config/formats.php
    protected static $FORMATS = array(); //config/formats.php
    protected static $VIEWS   = array(); //config/formats.php
    protected static $ALT_HDR = array(); //config/formats.php


    /**
     * Constructor
     */
    public function __construct() {
        $this->load_config();
        $this->detect_method();
        $fmt = $this->detect_format();
        $this->detect_view($fmt);
        parent::CI_Router();
    }


    /**
     * In many ways, the routing for AIR is simpler than CI's default routing.
     * So override it to detect routes to API-controllers, or otherwise do the
     * default 'something_controller/method' routing.
     *
     * @param array   $segments (optional)
     */
    public function _set_request($segments=array()) {
        if (count($segments) == 0) {
            return;
        }

        // determine a couple things
        $ctrl = $segments[0];
        $is_api = in_array($ctrl, $this->api_routes);
        $is_html = $this->http_view == 'html' || $this->http_view == 'phtml';
        $exists = file_exists(APPPATH."controllers/$ctrl".$this->ctrl_suffix.EXT);

        // (1) - non-api controller
        if ($exists && !$is_api) {
            $this->set_class($ctrl.$this->ctrl_suffix);
            $method = isset($segments[1]) ? $segments[1] : 'index';
            $this->set_method($method);
        }

        // (2) - api html controller
        elseif ($exists && $is_api && $is_html) {
            $this->set_class($ctrl.$this->ctrl_suffix);
            $this->set_method('index'); //ALWAYS index
            array_splice($segments, 1, 0, $ctrl);
            array_splice($segments, 1, 0, 'index');
        }

        // (3) - any remaining api route
        elseif ($is_api) {
            $this->set_directory('../libraries');
            $this->set_class($this->api_class);
            $this->set_method($this->api_method);
            array_splice($segments, 1, 0, $ctrl);
            array_splice($segments, 1, 0, $this->api_method);
        }

        // (4) - no route found
        else {
            show_404();
        }

        // set segments
        $this->uri->rsegments = $segments;
    }


    /**
     * Load configuration files necessary for the router, including the api
     * routes from 'config/routes.php', and the acceptable formats and views
     * from 'config/formats.php'.
     */
    protected function load_config() {
        // load api routes
        @include APPPATH.'config/routes'.EXT;
        if (isset($api_routes)) $this->api_routes = $api_routes;
        unset($api_routes);

        // load formats/views
        @include APPPATH.'config/formats'.EXT;
        if (isset($url_formats)) self::$FORMATS = $url_formats;
        unset($url_formats);
        if (isset($default_format)) self::$DEFAULT = $default_format;
        unset($default_format);
        if (isset($format_views)) self::$VIEWS = $format_views;
        unset($format_views);
        if (isset($alt_headers)) self::$ALT_HDR = $alt_headers;
        unset($alt_headers);
    }


    /**
     * Returns the content-type for $my_view. Shortcut to the config/formats.php values.
     *
     * @param string  $my_view
     * @return string $content_type
     */
    public function get_content_type_for_view($my_view) {
        return isset(self::$FORMATS[$my_view]) ? self::$FORMATS[$my_view] : null;
    }


    /**
     * Detect the HTTP request method, set either through the server
     * REQUEST_METHOD header or tunneled with a POST variable.
     *
     * @return string $method
     */
    protected function detect_method() {
        $method = strtoupper($_SERVER['REQUEST_METHOD']);
        if ($method == 'POST' && isset($_POST[AIR2_X_TUNNELED_METHOD_NAME])) {
            $method = strtoupper($_POST[AIR2_X_TUNNELED_METHOD_NAME]);
            unset($_POST[AIR2_X_TUNNELED_METHOD_NAME]);
            $_SERVER['REQUEST_METHOD'] = $method;

            // make sure GET params get setup properly
            if ($method == 'GET') {
                $_GET = array_merge($_GET, $_POST);
            }
        }

        // a bit of extra error checking
        if (!in_array($method, self::$METHODS)) {
            header('Allow: '.implode(', ', self::$METHODS));
            show_error("Error: Unsupported request method: $method", 405);
        }
        $this->http_method = $method;
        return $method;
    }


    /**
     * Detect which response format the client has requested.  This is set
     * through the server HTTP_ACCEPT header, or tunneled with a POST variable,
     * or indicated by a '.format' string at the end of the URL.
     *
     * Valid format strings are found in config/formats.php.
     *
     * Forcing the content type with the POST variable DOES NOT change what
     * view will format the output... IT ONLY IMPACTS THE CONTENT-TYPE HEADER
     * WHICH IS RETURNED.
     *
     * @return string $format_for_view
     */
    protected function detect_format() {
        $acc = 'HTTP_ACCEPT';
        $format = isset($_SERVER[$acc]) ? $_SERVER[$acc] : self::$DEFAULT;

        // get the last segment of the path
        $path = isset($_SERVER['PATH_INFO']) ? $_SERVER['PATH_INFO'] : '';
        $path = trim($path, '/');
        if (preg_match('/\.\w+$/', $path, $matches)) {
            // format a new url without the .format
            $new_url = preg_replace('/\.\w+$/', '', $path);
            $new_url = trim($new_url, '/');
            $_SERVER['PATH_INFO'] = $new_url;

            // check the request format
            $url_format = substr(array_pop($matches), 1); //remove dot
            if (array_key_exists($url_format, self::$FORMATS)) {
                $format = self::$FORMATS[$url_format];
            }
            else {
                $format = "unknown/$url_format";
            }
            $_SERVER['HTTP_ACCEPT'] = $format;
        }

        // default format
        if (!$format || strlen($format) == 0) {
            $format = self::$DEFAULT;
        }

        // many browsers, including iPhone and IE7, send a */* meaning they
        // are hopelessly promiscuous.  Just send default format.
        if (strpos($format, '*/*') !== false) {
            $format = self::$DEFAULT;
        }

        // allow POST var to set content-type, no matter what the view
        if (isset($_POST[AIR2_X_FORCE_CONTENT_NAME])) {
            $this->http_format = $_POST[AIR2_X_FORCE_CONTENT_NAME];
        }

        // is there an alternate header for this format?
        elseif (isset(self::$ALT_HDR[$format])) {
            $this->http_format = self::$ALT_HDR[$format];
        }

        // default
        else {
            $this->http_format = $format;
        }
        return $format; //return detected, not forced, format
    }


    /**
     * Based on a requested mime type, attempts to find a view which can
     * display that type.  Valid views are configured in config/formats.php.
     *
     * @param string  $req_format
     * @return string $view
     */
    protected function detect_view($req_format) {
        $http_accept = new HTTP_Accept($req_format);

        // look for a supported format acceptable to the client
        foreach (self::$VIEWS as $fmt => $vw) {
            // check if this format is in the client's HTTP_ACCEPT
            if ($http_accept->isMatchExact($fmt)) {
                $this->http_view = $vw;
                return $vw;
            }
        }

        // no view found - 415
        $accepts = implode(', ', array_keys(self::$VIEWS));
        header("Accept: $accepts");
        show_error("Unsupported request format: $req_format!", 415);
    }


}
