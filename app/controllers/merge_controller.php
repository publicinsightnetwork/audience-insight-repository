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

require_once 'AIR2_Controller.php';
require_once 'AIR2Merge.php';

/**
 * Merge Controller
 *
 * Provides the functionality to merge 2 sources in AIR2
 *
 * @package default
 */
class Merge_Controller extends AIR2_Controller {
    /* GET/POST parameter to pass in conflict-resolution options */
    public static $OPS_PARAM = 'ops';

    /* valid Models to merge */
    protected $valid_types = array(
        'source' => 'Source',
    );

    protected $radix_whitelist = array(
        'sf_fact_id', 'sf_fv_id', 'sf_src_fv_id',
    );

    /* merge data */
    protected $my_type;
    protected $my_model;
    protected $prime;
    protected $merge;
    protected $ops = array();
    protected $commit_on_success = false; //false runs a simulation


    /**
     * Public POST/GET interface for merging sources
     *
     * @param string $prime_uuid
     * @param string $merge_uuid
     */
    public function source($prime_uuid, $merge_uuid) {
        if ($this->view != 'json') {
            show_error('Only json allowed for merging', 415);
        }
        if (!$prime_uuid || !$merge_uuid) {
            show_error('Must provide primary and merge UUID', 404);
        }

        // preview or commit
        if ($this->method == 'GET') {
            $this->preview_merge('source', $prime_uuid, $merge_uuid);
        }
        elseif ($this->method == 'POST') {
            $this->commit_merge('source', $prime_uuid, $merge_uuid);
        }
        else {
            show_error('Only GET/POST allowed for merging', 405);
        }
    }


    /**
     * Preview a merge operation.
     *
     * @param string  $type
     * @param string  $prime_uuid
     * @param string  $merge_uuid
     */
    protected function preview_merge($type, $prime_uuid, $merge_uuid) {
        $this->initialize($type, $prime_uuid, $merge_uuid);
        $this->commit_on_success = false;

        // pre-fetch both objects, to include in the preview
        $data = array();
        if ($type == 'source') {
            $this->prime->SrcFact; // load
            $data['PrimeSource'] = $this->prime->toArray(true);
            air2_clean_radix($data['PrimeSource'], $this->radix_whitelist);
            $this->merge->SrcFact; // load
            $data['MergeSource'] = $this->merge->toArray(true);
            air2_clean_radix($data['MergeSource'], $this->radix_whitelist);
        }

        // run the merge
        $this->run($data);
    }


    /**
     * Perform a merge operation.
     *
     * @param string  $type
     * @param string  $prime_uuid
     * @param string  $merge_uuid
     */
    protected function commit_merge($type, $prime_uuid, $merge_uuid) {
        $this->initialize($type, $prime_uuid, $merge_uuid);
        $this->commit_on_success = true;

        // pre-fetch both objects, to include in the preview
        $data = array();
        if ($type == 'source') {
            $this->prime->SrcFact; // load
            $data['PrimeSource'] = $this->prime->toArray(true);
            air2_clean_radix($data['PrimeSource'], $this->radix_whitelist);
            $this->merge->SrcFact; // load
            $data['MergeSource'] = $this->merge->toArray(true);
            air2_clean_radix($data['MergeSource'], $this->radix_whitelist);
        }

        // run the merge
        $this->run($data);
    }


    /**
     * Initialize input data, showing errors when necessary.
     *
     * @param string  $type
     * @param string  $prime
     * @param string  $merge
     */
    protected function initialize($type, $prime, $merge) {
        // check for valid merge type
        if (!isset($this->valid_types[$type])) {
            $this->show_404();
        }
        $this->my_type = $type;
        $this->my_model = $this->valid_types[$type];

        // existence of prime and merge
        $this->prime = AIR2_Record::find($this->my_model, $prime);
        if (!$this->prime) {
            show_error("Invalid prime $type", 404);
        }
        $this->merge = AIR2_Record::find($this->my_model, $merge);
        if (!$this->merge) {
            show_error("Invalid merge $type", 404);
        }

        // check authz, ignoring src_has_acct (will check later)
        $usr = $this->airuser->get_user();
        if (!$this->prime->user_may_write($usr, false)) {
            show_error("No WRITE authz on prime $type", 403);
        }
        if (!$this->merge->user_may_write($usr, false)) {
            show_error("No WRITE authz on merge $type", 403);
        }
        // DELETE authz not needed - #2300
        //if (!$this->merge->user_may_delete($usr)) {
        //    $this->error_response("No DELETE authz on merge $type", 403);
        //}

        // check POST/GET params for merge options
        $input_ops = $this->input->get_post(self::$OPS_PARAM);
        if (is_string($input_ops)) {
            $json = json_decode($input_ops, true);
            if ($json) $input_ops = $json;
        }
        $this->ops = $input_ops;
    }


    /**
     * Run a merge using the AIR2Merge library.
     *
     * @param array   $response_data
     */
    protected function run($response_data=array()) {
        // turn off logging during the merge
        $was_logging_enabled = AIR2Logger::$ENABLE_LOGGING;
        AIR2Logger::$ENABLE_LOGGING = false;

        // run the merge and reset logging
        $type = $this->my_type;
        $errs = AIR2Merge::merge($this->prime, $this->merge, $this->ops, $this->commit_on_success);
        $result = AIR2Merge::get_result();
        AIR2Logger::$ENABLE_LOGGING = $was_logging_enabled;

        // what happened?
        $status = 200;
        if ($errs === true) {
            $response_data['success'] = true;
            $response_data['message'] = "Successfully merged {$type}s";

            // attach the "merged" object to data
            $response_data['ResultSource'] = $result['result'];
            air2_clean_radix($response_data['ResultSource'], $this->radix_whitelist);

            // attach ops used
            $response_data['op_prime'] = $result['prime'];
            $response_data['op_merge'] = $result['merge'];

            // log the merge
            if ($this->commit_on_success) {
                $this->log_activity($result, $response_data);
            }
        }
        elseif (is_string($errs)) {
            $response_data['success'] = false;
            $response_data['message'] = $errs;
            $status = 500;
        }
        else {
            $response_data['success'] = false;
            $response_data['message'] = "Unable to merge {$type}s";
            $response_data['errors'] = $errs;
            $status = 400;

            // attach ops used
            $response_data['op_prime'] = $result['prime'];
            $response_data['op_merge'] = $result['merge'];
        }

        // attach fact data
        $rs = AIR2_DBManager::get_connection()->fetchAll('select * from fact');
        $response_data['facts'] = array();
        foreach ($rs as $row) {
            $response_data['facts'][$row['fact_id']] = $row;
        }

        // respond with data
        $this->response($response_data, $status);
    }


    /**
     * Log a src_activity to indicate that we merged a source.
     *
     * @param array   $result_data
     * @param array   $response_data
     */
    protected function log_activity($result_data, $response_data) {
        $sa = new SrcActivity();
        $sa->sact_actm_id = ActivityMaster::SRCINFO_UPDATED;
        $sa->sact_src_id = $this->prime->src_id;
        $sa->sact_dtim = air2_date();
        $old_usr = $response_data['MergeSource']['src_username'];
        $sa->sact_desc = "{USER} merged source {SRC} with $old_usr";
        $sa->sact_notes = null; //TODO: something from result?
        $sa->save();
    }


}
