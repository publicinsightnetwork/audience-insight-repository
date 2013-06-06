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
require_once 'tank/CSVImporter.php';

/**
 * CSV Preview API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Csv_Preview extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $limit_default = 3;

    // metadata
    protected $ident = 'line';
    protected $fields = array(
        'line',
    );

    // importer data
    protected $preview_limit;
    protected $preview_extra = array();


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function rec_query($args=array()) {
        return new CSVImporter($this->parent_rec);
    }


    /**
     * Format csv preview in an API-ish way
     *
     * @param  mixed $importer
     * @return array
     */
    protected function format_query_radix($importer) {
        $prev_data = $importer->preview_file($this->preview_limit);

        // create headers
        $this->preview_extra['invalid_headers'] = array();
        $this->fields = array('line');
        $this->_fields = array('line' => true);
        foreach ($prev_data['header'] as $hdr) {
            $this->fields[] = $hdr['name'];
            $this->_fields[$hdr['name']] = true;

            if (!$hdr['valid']) {
                $this->preview_extra['invalid_headers'][] = $hdr['name'];
            }
        }

        // create radix
        $radix = array();
        foreach ($prev_data['lines'] as $idx => $line) {
            $line_radix = array('line' => $idx);
            foreach ($prev_data['header'] as $idx => $hdr) {
                $name = $hdr['name'];
                $line_radix[$name] = isset($line[$idx]) ? $line[$idx] : null;
            }
            $radix[] = $line_radix;
        }
        return $radix;
    }


    /**
     * Get the CSV line count total (or up to 1000, anyways)
     *
     * @param mixed $importer
     * @return string
     */
    protected function rec_query_total($importer) {
        $count = $importer->get_line_count(1000);
        if ($count === false) $count = 'Greater than 1000 lines';
        return $count;
    }


    /**
     * Ignore
     *
     * @param string $method
     * @param array  $return
     */
    protected function sanity($method, &$return) {}


    /**
     * Just record it
     *
     * @param mixed $q
     * @param int $limit
     * @param int $offset
     */
    protected function rec_query_page($q, $limit, $offset) {
        $this->preview_limit = $limit;
    }


    /**
     * Add extra data
     *
     * @param mixed   $mixed
     * @param string  $method
     * @param string  $uuid   (optional)
     * @param array   $extra (optional)
     * @return array $response
     */
    protected function format($mixed, $method, $uuid=null, $extra=array()) {
        $resp = parent::format($mixed, $method, $uuid, $extra);
        $resp['meta'] = array_merge($resp['meta'], $this->preview_extra);

        // include some header-validation data
        if (is_a($mixed, 'CSVImporter')) {
            $hdr_msg = $mixed->validate_headers();
            $hdr_valid = ($hdr_msg === true) ? true : false;
            if (!$hdr_valid) $resp['message'] = $hdr_msg;
            $this->parent_rec->set_meta_field('valid_header', $hdr_valid);
            $this->parent_rec->save();
        }
        return $resp;
    }


}
