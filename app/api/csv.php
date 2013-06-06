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
 * CSV (a type of tank) API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Csv extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update');
    protected $CREATE_DATA = array('csvfile', 'csv_delim', 'csv_encl');
    protected $QUERY_ARGS  = array('status');
    protected $UPDATE_DATA = array('csvfile', 'csv_delim', 'csv_encl',
        'org_uuid', 'prj_uuid', 'evdesc', 'evdtim', 'evtype', 'evdir');

    // default paging/sorting
    protected $sort_default   = 'tank_cre_dtim desc';
    protected $sort_valids    = array('tank_cre_dtim', 'tank_name');

    // metadata
    protected $ident = 'tank_uuid';
    protected $fields = array(
        'tank_uuid',
        'tank_name',
        'tank_notes',
        'tank_meta',
        'tank_type',
        'tank_status',
        'tank_cre_dtim',
        'tank_upd_dtim',
        'User' => 'DEF::USERSTAMP',
        'TankOrg' => array(
            'to_so_status',
            'to_so_home_flag',
            'Organization' => 'DEF::ORGANIZATION',
        ),
        'TankActivity' => array(
            'tact_id',
            'tact_type',
            'tact_dtim',
            'tact_desc',
            'tact_notes',
            'tact_ref_type',
            'Project' => 'DEF::PROJECT',
            'ActivityMaster' => array('actm_id', 'actm_name'),
        ),
        // flattened fields
        'user_uuid',
        'org_uuid',
        'prj_uuid',
        'evdesc',
        'evdtim',
        'evtype',
        'evdir',
        'count_total',
        'count_new',
        'count_conflict',
        'count_locked',
        'count_done',
        'count_error',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('Tank t');
        $q->addWhere('t.tank_type = ?', Tank::$TYPE_CSV);
        $q->leftJoin('t.User u');
        $q->leftJoin('t.TankOrg to');
        $q->leftJoin('to.Organization o');
        $q->leftJoin('t.TankActivity ta');
        $q->leftJoin('ta.ActivityMaster m');
        $q->leftJoin('ta.Project p');
        if (isset($args['status'])) {
            air2_query_in($q, $args['status'], 't.tank_status');
        }

        // add counts
        Tank::add_counts($q, 't');
        TankActivity::add_event_meta($q, 'ta');

        // add flattened and return
        $q->addSelect('u.user_uuid as user_uuid');
        $q->addSelect('o.org_uuid as org_uuid');
        $q->addSelect('p.prj_uuid as prj_uuid');
        return $q;
    }


    /**
     * Fetch
     *
     * @param string $uuid
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid) {
        $q = $this->air_query();
        $q->where('t.tank_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array $data
     */
    protected function air_create($data) {
        $this->require_data($data, array('csvfile'));

        // sanity-check file
        $file = $data['csvfile'];
        if (!preg_match('/\.csv$/', $file['name'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "Uploaded file must have the extension '.csv'");
        }

        $rec = new Tank();
        $rec->tank_uuid = air2_generate_uuid();
        $rec->tank_user_id = $this->user->user_id;
        $rec->tank_type = Tank::$TYPE_CSV;
        $rec->tank_status = Tank::$STATUS_CSV_NEW;
        $rec->tank_name = $file['name'];
        $rec->copy_file($file['tmp_name']);

        // save filesize in metadata
        $size_kb = number_format($file['size'] / 1024, 1);
        $rec->set_meta_field('file_size', "$size_kb KB");

        // meta delimiters (defaults)
        $del = isset($data['csv_delim']) ? $data['csv_delim'] : ',';
        $rec->set_meta_field('csv_delim', $del);
        $encl = isset($data['csv_encl']) ? $data['csv_encl'] : '"';
        $rec->set_meta_field('csv_encl', $encl);

        // setup submit errors and valids
        $rec->set_meta_field('submit_message', null);
        $rec->set_meta_field('submit_success', null);
        $rec->set_meta_field('valid_file', true);

        // use a CSVImporter to validate headers
        $imp = new CSVImporter($rec);
        $hdr_msg = $imp->validate_headers();
        $hdr_valid = ($hdr_msg === true) ? true : false;
        $rec->set_meta_field('valid_header', $hdr_valid);
        return $rec;
    }


    /**
     * Update
     *
     * @param Tank  $rec
     * @param array $data
     */
    protected function air_update($rec, $data) {
        $allow_update = array(Tank::$STATUS_CSV_NEW);
        if (!in_array($rec->tank_status, $allow_update)) {
            throw new Rframe_Exception(Rframe::BAD_METHOD, 'Invalid tank status for update');
        }

        // meta delimiters
        if (isset($data['csv_delim'])) {
            $rec->set_meta_field('csv_delim', $data['csv_delim']);
        }
        if (isset($data['csv_encl'])) {
            $rec->set_meta_field('csv_encl', $data['csv_encl']);
        }

        // new file
        if (isset($data['csvfile'])) {
            $file = $data['csvfile'];
            if ($file['name'] != $rec->tank_name) {
                $n = $rec->tank_name;
                $msg = "Error: you must upload the original file '$n', or start a new csv import.";
                throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
            }

            // change files
            $rec->copy_file($file['tmp_name']);
            $size_kb = number_format($file['size'] / 1024, 1);
            $rec->set_meta_field('file_size', "$size_kb KB");

            // setup submit errors and valids
            $rec->set_meta_field('submit_message', null);
            $rec->set_meta_field('submit_success', null);
            $rec->set_meta_field('valid_file', true);

            // use a CSVImporter to validate headers
            $imp = new CSVImporter($rec);
            $hdr_msg = $imp->validate_headers();
            $hdr_valid = ($hdr_msg === true) ? true : false;
            $rec->set_meta_field('valid_header', $hdr_valid);
        }

        // Org
        if (isset($data['org_uuid'])) {
            $org = AIR2_Record::find('Organization', $data['org_uuid']);
            if (!$org) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid org_uuid');
            }
            $rec->TankOrg[0]->to_org_id = $org->org_id;
        }

        // Activity
        $this->process_activity($rec, $data);
    }


    /**
     * Process activity/event input
     *
     * @param Tank  $rec
     * @param array $data
     */
    protected function process_activity($rec, $data) {
        $flds = array('prj_uuid', 'evdesc', 'evdtim', 'evtype', 'evdir');
        if (count(array_intersect_key(array_flip($flds), $data)) == 0) {
            return;
        }

        // if DNE, all must be present!
        if ($rec->TankActivity->count() == 0) {
            $this->require_data($data, $flds);
            $rec->TankActivity[0]->tact_type = TankActivity::$TYPE_SOURCE;
            $rec->TankActivity[0]->tact_desc = '{USER} imported source {SRC} in csv ' . $rec->tank_name;
            $rec->TankActivity[0]->tact_xid = $rec->tank_id;
            $rec->TankActivity[0]->tact_ref_type = SrcActivity::$REF_TYPE_TANK;
        }

        // validate event input
        if (isset($data['evtype']) || isset($data['evdir'])) {
            $t = $data['evtype'];
            $d = $data['evdir'];
            if (!$t || !$d) {
                throw new Rframe_Exception(Rframe::BAD_DATA, "Must pass both evtype and evdir");
            }
            if (!in_array($t, array('E', 'P', 'T', 'I', 'O'))) {
                throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid parameter evtype '$t'");
            }
            if (!in_array($d, array('I', 'O'))) {
                throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid parameter evdir '$d'");
            }
            $rec->TankActivity[0]->tact_actm_id = TankActivity::$ACTM_MAP[$t.$d];
        }
        if (isset($data['evdtim'])) {
            $dt = $data['evdtim'];
            if (!strtotime($dt)) {
                throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid parameter evdtim '$dt'");
            }
            $rec->TankActivity[0]->tact_dtim = $dt;
        }
        if (isset($data['evdesc'])) {
            $desc = $data['evdesc'];
            if (strlen($desc) < 1) {
                throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid parameter evdesc '$desc'");
            }
            $rec->TankActivity[0]->tact_notes = $desc;
        }
        if (isset($data['prj_uuid'])) {
            $prj = AIR2_Record::find('Project', $data['prj_uuid']);
            if (!$prj) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid prj_uuid');
            }
            $rec->TankActivity[0]->tact_prj_id = $prj->prj_id;
        }
    }


}
