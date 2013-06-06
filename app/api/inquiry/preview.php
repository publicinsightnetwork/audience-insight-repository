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

require_once 'rframe/AIRAPI_Resource.php';

/**
 * Inquiry/Preview API
 *
 * @author astevenson
 * @package default
 */
class AAPI_Inquiry_Preview extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query');
    protected $QUERY_ARGS  = array('inq_uuid');
    protected $CREATE_DATA = array();

    // metadata
    protected $ident = 'inq_uuid';
    protected $fields = array(
        'inq_uuid',
        'preview_json',
    );

    // importer data
    protected $preview_limit;
    protected $preview_extra = array();

    /**
     * Query
     *
     * @param array   $args
     * @return Doctrine_Query $q
     */
    protected function rec_query($args=array()) {
        return $this->parent_rec;
    }


    /**
     * Format preview in an API-ish way
     *
     * @param mixed   $rec
     * @return array
     */
    protected function format_query_radix($rec) {
        // create radix
        $radix = array();

        $radix['inq_uuid'] = $rec->inq_uuid;
        $radix['preview_json'] = $rec->get_preview('json');
        return $radix;
    }


    /**
     * This will always be 1
     *
     * @param mixed   $rec
     * @return string
     */
    protected function rec_query_total($rec) {
        return 1;
    }


    /**
     * Ignore
     *
     * @param string  $method
     * @param array   $return
     */
    protected function sanity($method, &$return) {}


    /**
     * Just record it
     *
     * @param mixed   $q
     * @param int     $limit
     * @param int     $offset
     */
    protected function rec_query_page($q, $limit, $offset) {
        $this->preview_limit = $limit;
    }


}
