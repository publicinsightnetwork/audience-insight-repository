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
 * CSV Submit API
 *
 * This is a single-resource, and all you can do is 'create' it
 *
 * @author rcavis
 * @package default
 */
class AAPI_Csv_Submit extends Rframe_Resource {

    // single resource
    protected static $REL_TYPE = self::ONE_TO_ONE;

    // API definitions
    protected $ALLOWED = array('create', 'fetch');
    protected $CREATE_DATA = array('nojob');


    /**
     * In this case, fetch just checks to see if the CSV Tank has been submitted
     * to the discriminator successfully or not.
     *
     * @return array
     */
    protected function rec_fetch() {
        $check = array(Tank::$STATUS_CSV_NEW);
        $stat = $this->parent_rec->tank_status;
        if (in_array($stat, $check)) {
            // also check tank_meta, in case it was JUST submitted
            $s = $this->parent_rec->get_meta_field('submit_success');
            if (!$s) {
                throw new Rframe_Exception(Rframe::ONE_DNE, 'tank not yet submitted');
            }
        }
        return array('submitted' => true);
    }


    /**
     * Attempt to submit a CSV Tank for discrimination
     *
     * @param array $data
     * @return null
     */
    protected function rec_create($data) {
        $rec = $this->parent_rec;

        // check column headers
        $imp = new CSVImporter($rec);
        $valid = $imp->validate_headers();
        if ($valid !== true) {
            throw new Rframe_Exception(Rframe::BAD_DATA, $valid);
        }

        // check for extra data (project/activity/org/etc)
        if (!$rec->TankOrg->count() > 0) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Must define organization');
        }
        if (!$rec->TankActivity->count() > 0) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Must define activity');
        }
        if (!$rec->TankActivity[0]->tact_prj_id) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Must define project');
        }

        // import in foreground... TODO: param for bg processing
        $n = $imp->import_file();
        if (is_string($n)) {
            $rec->set_meta_field('submit_message', $n);
            $rec->set_meta_field('submit_success', false);
            $rec->save();
            throw new Rframe_Exception(Rframe::BAD_DATA, $n);
        }

        // success!
        $rec->set_meta_field('submit_message', "Successfully imported $n rows");
        $rec->set_meta_field('submit_success', true);
        $rec->save();

        // add to job_queue
        if (!isset($data['nojob'])) {
            $this->queue_discriminator($rec->tank_id);
        }
        return '1';
    }


    /**
     * Format a "existing" submit
     *
     * @param array $record
     */
    protected function format_radix($record) {
        return $record;
    }


    /**
     * Put an entry in the JobQueue to run the discriminator on this tank_id.
     *
     * @param int     $tank_id
     */
    protected function queue_discriminator($tank_id) {
        $jq = new JobQueue();
        $jq->jq_job = "PERL AIR2_ROOT/bin/run-discriminator $tank_id";
        $jq->save();
    }


}
