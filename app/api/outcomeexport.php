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
require_once 'phperl/callperl.php';

/**
 * OutcomeExport API
 *
 * Allows various exporting of CSV-ish outcomes via the AIR API
 *
 * @author rcavis
 * @package default
 */
class AAPI_OutcomeExport extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query');
    protected $QUERY_ARGS  = array('email', 'sources', 'org_uuid',
        'prj_uuid', 'inq_uuid', 'start_date', 'end_date', 'count');

    // metadata
    protected $ident = 'out_uuid';
    protected $output_all_facts = false;
    protected $limit_param = false;
    protected $offset_param = false;
    protected $sort_param = false;

    // total returned from a "count" query
    private $cached_total;


    /**
     * Redirect to perl!
     *
     * @param  array $args
     * @return array $resp
     */
    public function rec_query($args) {
        $uid = $this->user->user_id;

        // get options
        $opts = array();
        if (isset($args['sources']) && $args['sources']) {
            $opts['sources'] = 1;
        }
        if (isset($args['org_uuid'])) {
            $org = AIR2_Record::find('Organization', $args['org_uuid']);
            if (!$org) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid org_uuid');
            }
            $opts['org_id'] = $org->org_id;
        }
        if (isset($args['prj_uuid'])) {
            $prj = AIR2_Record::find('Project', $args['prj_uuid']);
            if (!$prj) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid prj_uuid');
            }
            $opts['prj_id'] = $prj->prj_id;
        }
        if (isset($args['inq_uuid'])) {
            $inq = AIR2_Record::find('Inquiry', $args['inq_uuid']);
            if (!$inq) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid inq_uuid');
            }
            $opts['inq_id'] = $inq->inq_id;
        }
        if (isset($args['start_date'])) {
            if (strtotime($args['start_date']) === false) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid start_date');
            }
            $opts['start_date'] = $args['start_date'];
        }
        if (isset($args['end_date'])) {
            if (strtotime($args['end_date']) === false) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid end_date');
            }
            $opts['end_date'] = $args['end_date'];
        }

        # return just the count
        if (isset($args['count']) && $args['count']) {
            $opts['count'] = 1;
            $this->cached_total = CallPerl::exec('AIR2::OutcomeWriter->get_obj', $uid, $opts);
            return array();
        }

        // download results, or email
        $data = array();
        if (isset($args['email']) && $args['email']) {
            $opts['format'] = 'email';

            // build command
            $cmd = "PERL AIR2_ROOT/bin/outcome-export.pl --user_id=$uid";
            foreach ($opts as $key => $val) {
                if ($key == 'sources') $cmd .= " --$key";
                else $cmd .= " --$key=$val";
            }
            $job = new JobQueue();
            $job->jq_job = $cmd;
            $this->air_save($job);

            // success, but we want a non-200, so throw up!
            $msg = 'CSV export scheduled for background processing';
            throw new Rframe_Exception(Rframe::BGND_CREATE, $msg);
        }
        else {
            if (count($opts) == 0) $opts = null; //avoid hash vs array confusion
            $r = CallPerl::exec('AIR2::OutcomeWriter->get_obj', $uid, $opts);
            $this->fields = $r[0];
            $this->reset_fields();

            // unflatten ... yeah, I know this is inefficient
            // but it's backwards compatible
            for ($i=1; $i<count($r); $i++) {
                $data[$i-1] = array();
                foreach ($this->fields as $colnum => $name) {
                    $data[$i-1][$name] = $r[$i][$colnum];
                }
            }
        }
        return $data;
    }


    /**
     * Make sure array is returned
     *
     * @param string $method
     * @param array  $return
     */
    protected function sanity($method, &$return) {
        if ($method == 'rec_query'&& !is_array($return)) {
            throw new Exception("rec_query must return array of records");
        }
    }


    /**
     * Just count the array
     *
     * @param  array $data
     * @return int   $total
     */
    protected function rec_query_total($data) {
        if ($this->cached_total) {
            return $this->cached_total;
        }
        return count($data);
    }


    /**
     * No formatting necessary
     *
     * @param  array $data
     * @return array $data
     */
    protected function format_query_radix($data) {
        return $data;
    }


    /**
     * Add a title for the CSV file
     *
     * @param mixed   $mixed
     * @param string  $method
     * @param string  $uuid  (optional)
     * @param array   $extra (optional)
     * @return array  $response
     */
    protected function format($mixed, $method, $uuid=null, $extra=array()) {
        $resp = parent::format($mixed, $method, $uuid, $extra);
        $resp['filename'] = 'pinfluence_export.csv';
        return $resp;
    }


}
