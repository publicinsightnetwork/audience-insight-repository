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
 * Resource that proxies a file
 *
 * @author rcavis
 * @package default
 */
abstract class AIRAPI_FileProxy extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch');

    // metadata
    protected $ident = 'id';
    protected $fields = array(
        'id',
        'path',
        'name',
        'size',
        'type',
    );

    // include proxy-type in response metadata
    protected $proxy_extra = array(
        'type' => 'fileproxy',
    );


    /**
     * Function to implement if you want your file available at a "query"
     * url (with no UUID).
     *
     * @return array $data
     */
    protected function file_query() {
        return false;
    }


    /**
     * Function to implement if you want your file available at a "fetch" url
     * (including UUID).
     *
     * @param string $uuid
     * @return array $data
     */
    protected function file_fetch($uuid) {
        return false;
    }


    /**
     * Check file return types
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
     * @param array $filedata
     * @return array $radix
     */
    protected function format_query_radix($filedata) {
        return $this->format_radix($filedata);
    }


    /**
     * Custom format
     *
     * @param array $filedata
     * @return array $radix
     */
    protected function format_radix($filedata) {
        return $this->_clean($filedata, $this->_fields);
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
            $filedata = $this->file_query();
            if (!$filedata) {
                throw new Rframe_Exception(Rframe::BAD_IDENT, 'File not found');
            }
            $this->sanity('rec_query', $filedata);
            return $this->format($filedata, 'query', null, $this->proxy_extra);
        }
        catch (Rframe_Exception $e) {
            return $this->format($e, 'query');
        }
    }


    /**
     * Fetch a proxied file
     *
     * @param string $uuid
     * @return array $response
     */
    public function fetch($uuid) {
        try {
            $this->check_method('fetch', $uuid);
            $filedata = $this->file_fetch($uuid);
            if (!$filedata) {
                throw new Rframe_Exception(Rframe::BAD_IDENT, 'File not found');
            }
            $this->sanity('rec_fetch', $filedata);
            $filedata['id'] = $uuid;
            return $this->format($filedata, 'fetch', $uuid, $this->proxy_extra);
        }
        catch (Rframe_Exception $e) {
            return $this->format($e, 'fetch', $uuid);
        }
    }


}
