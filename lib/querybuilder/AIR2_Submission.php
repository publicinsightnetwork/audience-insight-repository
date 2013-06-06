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

require_once 'Encoding.php';
require_once 'AIR2_Utils.php';

class AIR2_Submission {

    public $is_ok       = false;
    public $errors      = null;
    public $meta        = null;
    public $srs         = null;
    public $query_uuid  = null;
    public $uuid        = null;
    public $gives_permission = false;
    public $has_files   = false;

    /**
     * new( $query_uuid, $params )
     *
     * @param string  $query_uuid
     * @param array   $params
     */
    public function __construct($query_uuid, $params) {
        $this->query_uuid = $query_uuid;
        $this->srs = $params;
        $this->uuid = air2_generate_uuid();
    }


    /**
     *
     *
     * @return unknown
     */
    public function ok() {
        return $this->is_ok;
    }


    /**
     *
     *
     * @return unknown
     */
    public function get_errors() {
        return $this->errors;
    }


    /**
     *
     *
     * @return unknown
     */
    public function write_file() {
        $path = $this->get_file_path();
        air2_mkdir(dirname($path));
        $params = $this->srs;
        $params['meta'] = $this->meta;

        // handle file uploads first, because we need to alter $params
        // to reflect target file name
        if ($this->has_files) {
            foreach ($params as $ques_uuid=>$param_value) {
                if (is_array($param_value) && isset($param_value['orig_name'])) {
                    $upload_dir = sprintf("%s/%s.uploads", dirname($path), $this->uuid);
                    $target_file = sprintf("%s/%s.%s", $upload_dir, $ques_uuid, $param_value['file_ext']);
                    air2_mkdir($upload_dir);
                    if (move_uploaded_file($param_value['tmp_name'], $target_file)) {
                        chmod($target_file, 0664);
                    }
                    $params[$ques_uuid]['tmp_name'] = $target_file;    // for reaper
                }
            }
        }

        $json = Encoding::json_encode_utf8($params);
        $bytes = file_put_contents($path, $json);

        return $bytes;
    }


    /**
     *
     *
     * @return unknown
     */
    public function get_file_path() {
        return sprintf("%s/%s/%s.json", AIR2_QUERY_INCOMING_ROOT, $this->query_uuid, $this->uuid);
    }


}
