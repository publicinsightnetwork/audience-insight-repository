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

define('TESTSBPATH', realpath( dirname(__FILE__).'/../lib/shared/simpletest' ).'/');
define('TESTAUTHPATH', realpath( dirname(__FILE__).'/../app/libraries' ).'/');
require_once TESTSBPATH.'browser.php';
require_once TESTAUTHPATH.'AirUser.php';

/**
 * Do an HTTP request for testing the AIR2 API
 *
 * @author  Ryan Cavis
 * @package tests
 */
class AirHttpTest {
    /* instance of the simplebrowser */
    public $browser;

    /* base url to use */
    public $base_url;

    /* cookies to authenticate */
    public $cookies = array();

    /* MIME content type of requests */
    public $content_type;

    public static $JSON = 'application/json';
    public static $TEXT = 'text/plain';
    public static $HTML = 'text/html';
    public static $XML  = 'application/xml';
    public static $RSS  = 'application/rss+xml';

    /**
     * Constructor
     *
     * prefixed on any http request you make.
     *
     * @param unknown $base_url (optional)
     */
    public function AirHttpTest($base_url = '') {
        if (!strlen($base_url)) {
            if (getenv('AIR2_BASE_URL')) {
                $base_url = getenv('AIR2_BASE_URL');
            }
            elseif (defined('AIR2_BASE_URL')) {
                $base_url = AIR2_BASE_URL;
            }
            else {
                $base_url = 'http://localhost/';
            }
        }
        $this->base_url = $base_url;
        $this->browser = &new SimpleBrowser();
    }


    /**
     * Setup an authenticated AIR user for this request
     *
     * @param string|Doctrine_Record $user  the air user's name, or user object
     * @param array   $authz (optional) an associative array of organizations and permissions
     */
    public function set_user($user, $authz=null) {
        $usr = new AirUser();
        if (is_string($user)) {
            if ($authz != null) {
                $usr->set_authz($authz);
            }
            $typedef = array('user' => array('type' => 'S')); // make system user
            $tktarr = $usr->get_tkt($user, 1, $typedef); // 1=fake user ID
        }
        else {
            $tktarr = $usr->create_tkt($user, false);
        }

        foreach ($tktarr as $ckname => $ckval) {
            $this->browser->setcookie($ckname, $ckval);
            $this->cookies[$ckname] = $ckval;
        }
    }


    /**
     *
     */
    public function set_test_user() {
        $this->set_user('testuser');
    }


    /**
     * Change the requested content type (default is json)
     *
     * @param <type>  $type
     */
    public function set_content_type($type) {
        if ($this->content_type) {
            // need to create new browser to clear headers
            $this->browser = &new SimpleBrowser();
            foreach ($this->cookies as $ckname => $ckval) {
                $this->browser->setcookie($ckname, $ckval);
            }
        }
        $this->content_type = $type;
        $this->browser->addHeader('Accept: '.$type);
    }



    /**
     * HTTP HEAD request
     *
     * @param string  $url
     * @param array   $params (optional)
     * @return string $page_content
     */
    public function http_head($url, $params=array()) {
        $page = $this->browser->head( $this->base_url.$url, $params );

        // do some error checking... set to false if we get an error
        return $page;
    }


    /**
     * HTTP GET request (read/list/search)
     *
     * @param string  $url    the url to visit
     * @param array   $params (optional) associative array of GET params
     * @return string|false the page content if there was no error, else false
     */
    public function http_get($url, $params=array()) {
        $page = $this->browser->get( $this->base_url.$url, $params );

        // do some error checking... set to false if we get an error
        return $page;
    }


    /**
     * HTTP POST request (create)
     *
     * @param string  $url    the url to visit
     * @param array   $params (optional) associative array of POST params
     * @return string|false the page content if there was no error, else false
     */
    public function http_post($url, $params=array()) {
        $page = $this->browser->post( $this->base_url.$url, $params );

        // do some error checking... set to false if we get an error
        return $page;
    }


    /**
     * HTTP PUT request (update)
     *
     * @param string  $url    the url to visit
     * @param array   $params (optional) associative array of PUT params
     * @return string|false the page content if there was no error, else false
     */
    public function http_put($url, $params=array()) {
        $page = $this->browser->put( $this->base_url.$url, $params );

        // do some error checking... set to false if we get an error
        return $page;
    }


    /**
     * HTTP DELETE request (delete/remove)
     *
     * @param string  $url    the url to visit
     * @param array   $params (optional) associative array of DELETE params
     * @return string|false the page content if there was no error, else false
     */
    public function http_delete($url, $params=array()) {
        $page = $this->browser->delete( $this->base_url.$url, $params );

        // do some error checking... set to false if we get an error
        return $page;
    }


    /**
     * Gets the HTTP response code from the server's response
     *
     * @return number the response code returned by the server
     */
    public function resp_code() {
        return $this->browser->getResponseCode();
    }


    /**
     * Gets the mime type of the content returned as the server's response
     *
     * @return string the mime type
     */
    public function resp_content_type() {
        return $this->browser->getMimeType();
    }


    /**
     *
     *
     * @param unknown $usr
     * @param unknown $psw
     * @return unknown
     */
    public function login($usr, $psw) {
        $uri = "login.json";
        $resp = $this->http_post($uri, array(
                'username' => $usr,
                'password' => $psw,
            )
        );
        $json_resp = json_decode($resp, true);
        $this->cookies[AIR2_AUTH_TKT_NAME] = $json_resp[AIR2_AUTH_TKT_NAME];
        return $json_resp;
    }


}
