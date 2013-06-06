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

require_once 'AIRAPI_Resource.php';

/**
 * Resource that proxies an image
 *
 * @author rcavis
 * @package default
 */
abstract class AIRAPI_ImageProxy extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch');

    // metadata
    protected $ident = 'id';
    protected $fields = array(
        'id',
        'url',
        'default',
        'type',
    );

    // include proxy-type in response metadata
    protected $proxy_extra = array(
        'type' => 'imageproxy',
    );


    /**
     * Function to implement if you want your image available at a "query"
     * url (with no UUID).  Should return an array with keys 'url', 'default',
     * and 'type'.  Returning 'false' indicates that the resource was not
     * found, and the appropriate exception will be thrown.
     *
     * @return array $data
     */
    protected function img_query() {
        return false;
    }


    /**
     * Function to implement if you want your image available at a "fetch" url
     * (including UUID).  Should return an array with keys 'url', 'default',
     * and 'type'.  Returning 'false' indicates that the resource was not
     * found, and the appropriate exception will be thrown.
     *
     * @param string $uuid
     * @return array $data
     */
    protected function img_fetch($uuid) {
        return false;
    }


    /**
     * Check image return types
     *
     * @param string $method
     * @param mixed $return (reference)
     */
    protected function sanity($method, &$return) {
        if ($method == 'rec_query' || $method == 'rec_fetch') {
            if (!$this->is_assoc_array($return)) {
                throw new Exception("$method must return array");
            }
        }
        else {
            throw new Exception("$method not allowed");
        }
    }


    /**
     * Return an object-radix (instead of the usual list-radix)
     *
     * @param array $imgdata
     * @return array $radix
     */
    protected function format_query_radix($imgdata) {
        return $this->format_radix($imgdata);
    }


    /**
     * Custom format
     *
     * @param array $imgdata
     * @return array $radix
     */
    protected function format_radix($imgdata) {
        return $this->_clean($imgdata, $this->_fields);
    }


    /**
     * Query behaves like 'fetch' for proxy resources
     *
     * @param array $args
     * @return array $response
     */
    public function query($args) {
        try {
            $this->check_method('query');
            $imgdata = $this->img_query();
            if (!$imgdata) {
                throw new Rframe_Exception(Rframe::BAD_IDENT, 'Image not found');
            }
            $this->sanity('rec_query', $imgdata);
            return $this->format($imgdata, 'query', null, $this->proxy_extra);
        }
        catch (Rframe_Exception $e) {
            return $this->format($e, 'query');
        }
    }


    /**
     * Fetch a proxied image
     *
     * @param string $uuid
     * @return array $response
     */
    public function fetch($uuid) {
        try {
            $this->check_method('fetch', $uuid);
            $imgdata = $this->img_fetch($uuid);
            if (!$imgdata) {
                throw new Rframe_Exception(Rframe::BAD_IDENT, 'Image not found');
            }
            $this->sanity('rec_fetch', $imgdata);
            $imgdata['id'] = $uuid;
            return $this->format($imgdata, 'fetch', $uuid, $this->proxy_extra);
        }
        catch (Rframe_Exception $e) {
            return $this->format($e, 'fetch', $uuid);
        }
    }


}
