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
 * Bin/ExportSource API
 *
 * Fetches bin sources for export.  Activities will be logged!
 *
 * @author rcavis
 * @package default
 */
class AAPI_Bin_ExportSource extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query');
    protected $QUERY_ARGS  = array('logging', 'allfacts', 'email');

    // metadata
    protected $ident = 'src_uuid';
    protected $output_all_facts = false;
    protected $limit_param = false;
    protected $offset_param = false;
    protected $sort_param = false;


    /**
     * Redirect to perl!
     *
     * @param  array $args
     * @return array $resp
     */
    public function rec_query($args) {
        $bid = $this->parent_rec->bin_id;
        $uid = $this->user->user_id;

        // max csv  export size - #4458
        $conn = AIR2_DBManager::get_connection();
        $num  = $conn->fetchOne("select count(*) from bin_source where bsrc_bin_id=$bid", array(), 0);
        if ($num > Bin::$MAX_CSV_EXPORT && !$this->user->is_system()) {
            $msg = "Can only CSV export up to ".Bin::$MAX_CSV_EXPORT." Sources";
            throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
        }

        // get options
        $cpx = (isset($args['allfacts']) && $args['allfacts']) ? 1 : 0;
        $log = 1; //default
        if (isset($args['logging']) && !$args['logging']) $log = 0;
        $notes = 0;
        if ($this->parent_rec->bin_status == Bin::$STATUS_ACTIVE_PROMPT_NOTES) {
            $notes = 1;
        }
        $opts = array(
            'complex_facts' => $cpx,
            'log_activity'  => $log,
            'bin_notes'     => $notes,
        );

        // download results, or email
        $data = array();
        if (isset($args['email']) && $args['email']) {
            // fix param names
            $extra = array();
            if ($opts['complex_facts']) $extra[] = 'complex_facts';
            if ($opts['log_activity'])  $extra[] = 'logging';
            if ($opts['bin_notes'])     $extra[] = 'notes';
            try {
                $this->parent_rec->queue_csv_export($this->user, $extra);
            }
            catch (Exception $e) {
                throw new Rframe_Exception(Rframe::BAD_DATA, $e->getMessage());
            }

            // success, but we want a non-200, so throw up!
            $msg = 'CSV export scheduled for background processing';
            throw new Rframe_Exception(Rframe::BGND_CREATE, $msg);
        }
        else {
            $r = CallPerl::exec('AIR2::CSVWriter->from_bin', $bid, $uid, $opts);
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


}
