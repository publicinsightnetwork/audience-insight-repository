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
 * Source/Submission API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Source_Submission extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('prj_uuid', 'srs_date', 'manual_entry_type',
        'manual_entry_desc', 'manual_entry_text');

    // default paging/sorting
    protected $sort_default   = 'srs_date desc';
    protected $sort_valids    = array('srs_date', 'srs_cre_dtim');

    // metadata
    protected $ident = 'srs_uuid';
    protected $fields = array(
        'srs_uuid',
        'srs_date',
        'srs_uri',
        'srs_type',
        'srs_public_flag',
        'srs_delete_flag',
        'srs_translated_flag',
        'srs_export_flag',
        'srs_loc_id',
        'srs_conf_level',
        'srs_cre_dtim',
        'srs_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
        'Inquiry' => 'DEF::INQUIRY',
        'manual_entry_type',
        'manual_entry_desc',
        'manual_entry_text',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $src_id = $this->parent_rec->src_id;

        $q = Doctrine_Query::create()->from('SrcResponseSet s');
        $q->andWhere('s.srs_src_id = ?', $src_id);
        $q->leftJoin('s.Inquiry i');

        // be really sneaky and add type/desc of manual entries
        $qtmp = "select ques_id from question where ques_inq_id = i.inq_id ";
        $ques1 = "$qtmp and ques_dis_seq = 1 limit 1";
        $ques2 = "$qtmp and ques_dis_seq = 2 limit 1";
        $ques3 = "$qtmp and ques_dis_seq = 3 limit 1";
        $rtmp = "select sr_orig_value from src_response where sr_srs_id = ".
            "s.srs_id and s.srs_type = '".SrcResponseSet::$TYPE_MANUAL_ENTRY."'";
        $resp1 = "$rtmp and sr_ques_id = ($ques1) limit 1";
        $resp2 = "$rtmp and sr_ques_id = ($ques2) limit 1";
        $resp3 = "$rtmp and sr_ques_id = ($ques3) limit 1";
        $q->addSelect("($resp1) as manual_entry_type");
        $q->addSelect("($resp2) as manual_entry_desc");
        $q->addSelect("($resp3) as manual_entry_text");

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
        $q->andWhere('s.srs_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create (MANUAL-ENTRY ONLY)
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        // check for ALL keys
        $this->require_data($data, $this->CREATE_DATA);

        // validate data
        $prj = AIR2_Record::find('Project', $data['prj_uuid']);
        if (!$prj) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid Project specified");
        }
        if (!$prj->user_may_read($this->user)) {
            throw new Rframe_Exception(Rframe::BAD_AUTHZ, "Invalid Project specified");
        }
        if (!isset(Inquiry::$MANUAL_TYPES[$data['manual_entry_type']])) {
            $v = implode(', ', array_keys(Inquiry::$MANUAL_TYPES));
            throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid manual_entry_type.  Allowed: ($v)");
        }

        // write to parent (ignore src_lock)
        if (!$this->parent_rec->user_may_write($this->user, false)) {
            throw new Rframe_Exception(Rframe::BAD_AUTHZ, "Insufficient WRITE authz on Source");
        }

        // do it!
        $rec = $this->_create_manual_submission($prj, $data['manual_entry_type'],
            $data['manual_entry_desc'], $data['manual_entry_text']);
        return $rec;
    }


    /**
     * Create a manual-entry submission
     *
     * @param SrcResponseSet $rec
     * @param Project $prj
     * @param string  $dsc
     * @param string  $txt
     * @return Doctrine_Record $rec
     */
    private function _create_manual_submission($prj, $typ, $dsc, $txt) {
        $src_id = $this->parent_rec->src_id;
        $rec = new SrcResponseSet();
        $rec->srs_src_id = $src_id;

        // just-in-time inquiry (does NOT require the usual WRITE authz)
        $inq = $prj->get_manual_entry_inquiry();
        
        // debug help
        //$remote_user = air2_get_remote_user();
        //Carper::carp(sprintf("create manual submission for inquiry %s by user %s", $inq->inq_uuid, $remote_user->user_username));
        
        $rec->srs_inq_id = $inq->inq_id;
        $rec->srs_type = SrcResponseSet::$TYPE_MANUAL_ENTRY;

        // entry type (the answer to the first question)
        $def = Inquiry::$MANUAL_TYPES[$typ];
        $rec->SrcResponse[0]->sr_src_id = $src_id;
        $rec->SrcResponse[0]->sr_ques_id = $inq->Question[0]->ques_id;
        $rec->SrcResponse[0]->sr_orig_value = $def['label'];

        // entry description and text (the next 2 questions)
        $rec->SrcResponse[1]->sr_src_id = $src_id;
        $rec->SrcResponse[1]->sr_ques_id = $inq->Question[1]->ques_id;
        $rec->SrcResponse[1]->sr_orig_value = $dsc;
        $rec->SrcResponse[2]->sr_src_id = $src_id;
        $rec->SrcResponse[2]->sr_ques_id = $inq->Question[2]->ques_id;
        $rec->SrcResponse[2]->sr_orig_value = $txt;

        // setup to log a src_activity post-insert
        SrcResponseSet::$LOG_MANUAL_ENTRY = true;
        return $rec;
    }


}
