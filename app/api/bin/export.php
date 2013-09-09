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
 * Bin/Export API
 *
 * Resource representing any SrcExports related to a bin.  Also allows
 * creating (scheduling) a new Lyris-export.
 *
 * @author rcavis
 * @package default
 */
class AAPI_Bin_Export extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create');
    protected $QUERY_ARGS  = array('type');
    protected $CREATE_DATA = array(
        // generic
        'se_type',
        // specific to type=L
        'prj_uuid', 'inq_uuid', 'org_uuid', 'strict_check', 'dry_run', 'no_export',
    );

    // default paging/sorting
    protected $query_args_default = array();
    protected $sort_default       = 'se_cre_dtim desc';
    protected $sort_valids        = array('se_cre_dtim', 'se_upd_dtim',
        'se_name', 'se_type');

    // metadata
    protected $ident = 'se_uuid';
    protected $fields = array(
        'se_uuid',
        'se_name',
        'se_type',
        'se_notes',
        'se_cre_dtim',
        'se_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
        'Inquiry' => 'DEF::INQUIRY',
        'Project' => 'DEF::PROJECT',
        'Email'   => 'DEF::EMAIL',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('SrcExport s');
        $q->addWhere('s.se_xid = ?', $this->parent_rec->bin_id);
        $q->addWhere('s.se_ref_type = ?', SrcExport::$REF_TYPE_BIN);
        $q->leftJoin('s.CreUser c');
        $q->leftJoin('s.UpdUser u');
        $q->leftJoin('s.Inquiry i');
        $q->leftJoin('s.Project p');
        $q->leftJoin('s.Email e');

        // type
        if (isset($args['type'])) {
            air2_query_in($q, $args['type'], 's.se_type');
        }
        return $q;
    }


    /**
     * Fetch
     *
     * @param string $uuid
     * @param bool   $minimal
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid, $minimal=false) {
        $q = $this->air_query();
        $q->where('s.se_uuid = ?', $uuid);

        return $q->fetchOne();
    }


    /**
     * Schedule an export
     *
     * @param array $data
     */
    protected function air_create($data) {
        $typ = isset($data['se_type']) ? $data['se_type'] : null;
        if ($typ == SrcExport::$TYPE_LYRIS) {
            return $this->schedule_lyris_export($data);
        }
        else {
            $msg = "Invalid se_type for export: '$typ'";
            throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
        }
    }


    /**
     * Attempt to schedule a Lyris export
     *
     * @param array $data
     */
    private function schedule_lyris_export($data) {
        $this->require_data($data, array('org_uuid'));

        // validate input
        $org = AIR2_Record::find('Organization', $data['org_uuid']);
        if (!$org) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid org_uuid');
        }
        $prj = $org->DefaultProject; //default
        if (isset($data['prj_uuid'])) {
            $prj = AIR2_Record::find('Project', $data['prj_uuid']);
        }
        if (!$prj) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid prj_uuid');
        }
        $inq = null;
        if (isset($data['inq_uuid'])) {
            $inq = AIR2_Record::find('Inquiry', $data['inq_uuid']);
            if (!$inq) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid inq_uuid');
            }
        }

        // extra params (and defaults)
        $strict = true;
        $dry = false;
        $no_exp = false;
        if (array_key_exists('strict_check', $data) && !$data['strict_check']) {
            $strict = false;
        }
        if (array_key_exists('dry_run', $data) && $data['dry_run']) {
            $dry = true;
        }
        if (array_key_exists('no_export', $data) && $data['no_export']) {
            $no_exp = true;
        }
        $extra = array('strict' => $strict, 'dry_run' => $dry, 'no_exp' => $no_exp);

        // params
        $params = array(
            'prj_uuid'  => $prj->prj_uuid,
            'org_uuid'  => $org->org_uuid,
            'strict'    => $strict,
            'dry_run'   => $dry,
            'no_export' => $no_exp,
        );
        if ($inq) {
            $params['inq_uuid'] = $inq->inq_uuid;
        }

        // punch it!
        try {
            $bin = $this->parent_rec;
            $bin->queue_lyris_export($this->user, $prj, $org, $inq, $extra);
        }
        catch (Exception $e) {
            throw new Rframe_Exception(Rframe::UNKNOWN_ERROR, $e->getMessage());
        }

        // success, but the resource doesn't exist yet, so throw up!
        $msg = 'Lyris export scheduled for background processing';
        throw new Rframe_Exception(Rframe::BGND_CREATE, $msg);
    }


}
