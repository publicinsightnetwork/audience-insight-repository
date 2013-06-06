<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
/**************************************************************************
 *
 *   Copyright 2013 American Public Media Group
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

require_once 'AIR2_Submission.php';

/**
 * AIR2_PublishedQuery middleware
 *
 * Static class (not fronting a db table) for manipulating Inquiry forms that
 * have been published.
 *
 * @package default
 */
class AIR2_PublishedQuery {

    public $uuid;

    /**
     *
     *
     * @param unknown $inq_uuid
     */
    public function __construct($inq_uuid) {
        $this->uuid = $inq_uuid;

    }





    /**
     * Returns the path to the cached .json file.
     *
     * @return string path
     */
    public function get_json_path() {
        return sprintf("%s/%s.json", AIR2_QUERY_DOCROOT, $this->uuid);
    }


    /**
     * Returns cached .json file as PHP object.
     *
     * @return object
     */
    public function get_json() {
        $buf = file_get_contents($this->get_json_path());
        $json = json_decode($buf);
        return $json;
    }


    /**
     * Validate input params, returning AIR2_Submission object.
     *
     * @param array   $params
     * @param unknown $meta
     * @return AIR2_Submission $submission
     */
    public function validate($params, $meta) {

        // load query .json file
        $json = $this->get_json();

        // turn questions into hash by uuid
        $questions = array();
        $permission_given = false;
        $has_files = false;
        foreach ($json->questions as $q) {
            $questions[$q->ques_uuid] = $q;
            if (strtolower($q->ques_type) == 'p') {
                $perm_value = '';
                if (isset($params[$q->ques_uuid])) {
                    if (is_array($params[$q->ques_uuid])) {
                        $perm_value = $params[$q->ques_uuid][0];
                    }
                    else {
                        $perm_value = $params[$q->ques_uuid];
                    }
                }
                if (preg_match('/^(y|yes|si)$/i', $perm_value)) {
                    $permission_given = true;
                }
            }
        }

        // validate params
        $errors = array();

        //Carper::carp(var_export($params, true));

        foreach ($params as $ques_uuid=>$param_value) {

            if (!isset($questions[$ques_uuid])) {
                $errors[] = array(
                    'msg'       => 'Invalid question',
                    'question'  => $ques_uuid,
                );
                continue;
            }

            $question = $questions[$ques_uuid];

            $ques_values = array();
            if (is_array($param_value)) {
                $ques_values = $param_value;
            }
            else {
                $ques_values = array($param_value);
            }

            foreach ($ques_values as $ques_value) {

                // basic response type check
                switch ($question->ques_resp_type) {

                case 'F':
                    // file type should be an array with reserved keys
                    // handle special below
                    break;

                case 'S':
                    // looks like string
                    if (!is_string($ques_value) && !is_numeric($ques_value)) {
                        $errors[] = array(
                            'msg' => 'Not a string',
                            'question' => $ques_uuid,
                        );
                    }
                    break;

                case 'N':
                    // looks like number
                    if (strlen($ques_value) && !is_numeric($ques_value)) {
                        $errors[] = array(
                            'msg' => 'Not a number',
                            'question' => $ques_uuid,
                        );
                    }
                    break;

                case 'Y':
                    // looks like a 4 digit year
                    if (strlen($ques_value) && !preg_match('/^[0-9]{4,}$/', $ques_value)) {
                        $errors[] = array(
                            'msg' => 'Not a 4 digit year',
                            'question' => $ques_uuid,
                        );
                    }
                    break;

                case 'D':
                    if (strlen($ques_value)) {
                        // looks like date
                        $date = strtotime($ques_value);
                        if ($date === false) {
                            $errors[] = array(
                                'msg' => 'Not a date',
                                'question' => $ques_uuid,
                            );
                        }
                    }
                    break;

                case 'T':
                    if (strlen($ques_value)) {
                        // looks like datetime
                        $date = strtotime($ques_value);
                        if ($date === false) {
                            $errors[] = array(
                                'msg' => 'Not a datetime',
                                'question' => $ques_uuid,
                            );
                        }
                    }
                    break;

                case 'E':
                    // looks like email
                    if (strlen($ques_value) && !air2_valid_email($ques_value)) {
                        $errors[] = array(
                            'msg' => 'Not an email',
                            'question' => $ques_uuid,
                        );
                    }
                    break;

                case 'U':
                    // looks like URL
                    if (strlen($ques_value) && !air2_valid_url($ques_value)) {
                        $errors[] = array(
                            'msg' => 'Not a URL',
                            'question' => $ques_uuid,
                        );
                    }
                    break;

                case 'P':
                    // looks like phone number
                    if (strlen($ques_value) && !air2_valid_phone_number($ques_value)) {
                        $errors[] = array(
                            'msg' => 'Not a phone number',
                            'question' => $ques_uuid,
                        );
                    }
                    break;

                case 'Z':
                    // looks like postal code
                    if (strlen($ques_value) && !air2_valid_postal_code($ques_value)) {
                        $errors[] = array(
                            'msg' => 'Not a postal code',
                            'question' => $ques_uuid,
                        );
                    }
                    break;

                default:
                    $errors[] = array(
                        'msg'       => 'Unknown response type: ' . $question->ques_resp_type,
                        'question'  => $ques_uuid
                    );

                }

                // specific constraint checks
                if ($question->ques_resp_opts) {
                    $opts = null;
                    if (is_string($question->ques_resp_opts)) {
                        $opts = json_decode($question->ques_resp_opts);
                    }
                    else {
                        $opts = $question->ques_resp_opts;
                    }

                    $ques_len = strlen($ques_value);
                    if ($opts && isset($opts->maxlen) && intval($opts->maxlen) > 0) {
                        if ($opts->maxlen < $ques_len) {
                            $errors[] = array(
                                'msg' => sprintf("Response is too long: %s chars, maxlen %s", $ques_len, $opts->maxlen),
                                'question' => $ques_uuid,
                            );
                        }
                    }
                    if ($opts
                        && isset($ques_value)
                        && strlen($ques_value)
                        && isset($opts->startyearoffset)
                        && isset($opts->endyearoffset)
                    ) {

                        $start_year = date('Y', strtotime('-' . $opts->startyearoffset . 'years'));
                        $end_year = date('Y', strtotime('-' . $opts->endyearoffset . 'years'));
                        $start_time = strtotime($start_year);
                        $end_time = strtotime($end_year);
                        $ques_time = strtotime($ques_value);

                        if ($ques_time < $start_time || $ques_time > $end_time) {
                            $errors[] = array(
                                'msg' => sprintf("Response '%s' is outside range: %s to %s",
                                    $ques_value, $start_year, $end_year),
                                'question' => $ques_uuid,
                            );
                        }
                    }
                    if ($opts && isset($opts->require) && $opts->require) {
                        if (!$ques_len || !preg_match('/\S/', $ques_value)) {
                            $errors[] = array(
                                'msg' => "Required",
                                'question' => $ques_uuid,
                            );
                        }
                    }
                }

            }

            // if question is a file upload type,
            // validate the array
            if ($question->ques_type == Question::$TYPE_FILE) {

                // if file was not uploaded, skip it
                if (!$param_value) {
                    // no-op
                }
                elseif (!is_array($param_value)) {
                    $errors[] = array(
                        'msg' => 'Invalid file upload value.',
                        'question' => $ques_uuid
                    );
                }
                else {
                    if (!isset($param_value['orig_name'])) {
                        $errors[] = array(
                            'msg' => "Internal error parsing file upload name.",
                            'question' => $ques_uuid,
                        );
                    }
                    elseif (!isset($param_value['tmp_name'])) {
                        $errors[] = array(
                            'msg' => "Internal error parsing file upload tmp name.",
                            'question' => $ques_uuid,
                        );
                    }
                    elseif (!isset($param_value['file_ext'])) {
                        $errors[] = array(
                            'msg' => "Internal error parsing file upload extension.",
                            'question' => $ques_uuid,
                        );
                    }
                    elseif (strlen($param_value['file_ext'])
                         && !in_array(strtolower($param_value['file_ext']), array('jpg', 'jpeg', 'gif', 'png', 'pdf'))
                    ) {
                        $errors[] = array(
                            'msg' => 'Unsupported file type: ' . $param_value['file_ext'],
                            'question' => $ques_uuid,
                        );
                    }
                    else {
                        $has_files = true;
                    }
                }
            }

        }


        // return Submission object
        $submission = new AIR2_Submission($this->uuid, $params);
        $submission->is_ok = count($errors) ? false : true;
        $submission->errors = $errors;
        $submission->meta = $meta;
        $submission->gives_permission = $permission_given;
        $submission->has_files = $has_files;

        return $submission;
    }


}
