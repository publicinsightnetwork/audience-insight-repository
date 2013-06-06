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
 * Bin/ExportSub API
 *
 * Fetches bin submissions for export.
 *
 * @author rcavis
 * @package default
 */
class AAPI_Bin_ExportSub extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('create');
    protected $QUERY_ARGS  = array();

    // metadata
    protected $ident = 'srs_uuid';
    protected $output_all_facts = false;
    protected $limit_param = false;
    protected $offset_param = false;
    protected $sort_param = false;


    /**
     * Schedule an export
     *
     * @param array $data
     */
    protected function air_create($data) {
        $bid = $this->parent_rec->bin_id;
        $uid = $this->user->user_id;

        // max export size
        $conn = AIR2_DBManager::get_connection();
        $q = "select count(*) from bin_src_response_set where bsrs_bin_id=$bid";
        $num  = $conn->fetchOne($q, array(), 0);
        if ($num > Bin::$MAX_CSV_EXPORT && !$this->user->is_system()) {
            $msg = "Can only CSV export up to ".Bin::$MAX_CSV_EXPORT." Submissions";
            throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
        }

        // email results
        try {
            $this->parent_rec->queue_xls_export($this->user);
        }
        catch (Exception $e) {
            throw new Rframe_Exception(Rframe::BAD_DATA, $e->getMessage());
        }

        // success, but we want a non-200, so throw up!
        $msg = 'Submissions export scheduled for background processing';
        throw new Rframe_Exception(Rframe::BGND_CREATE, $msg);
    }


}
