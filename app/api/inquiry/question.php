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
require_once 'querybuilder/AIR2_QueryBuilder.php';

/**
 * Inquiry/Question API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Inquiry_Question extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('resequence', 'ques_template', 'duplicate',
        'ques_value', 'ques_choices', 'ques_public_flag', 'ques_resp_opts',
        'ques_status', 'ques_dis_seq', );
    protected $UPDATE_DATA = array('resequence', 'ques_value', 'ques_choices',
        'ques_public_flag', 'ques_resp_opts', 'ques_status', 'ques_dis_seq', 'ques_type', );

    // default paging/sorting
    protected $sort_default   = 'ques_dis_seq asc';
    protected $sort_valids    = array('ques_dis_seq', 'ques_cre_dtim');

    // metadata
    protected $ident = 'ques_uuid';
    protected $fields = array(
        'ques_uuid',
        'ques_dis_seq',
        'ques_status',
        'ques_type',
        'ques_value',
        'ques_choices',
        'ques_cre_dtim',
        'ques_upd_dtim',
        'ques_locks',
        'ques_public_flag',
        'ques_resp_type',
        'ques_resp_opts',
        'ques_template',
        'ProfileMap' => array('pmap_id', 'pmap_name', 'pmap_display_name'),
    );

    // update inq_upd_user/inq_upd_dtim from this resource
    protected $update_parent_stamps = true;


    /**
     * Query
     *
     * @param array   $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $inq_id = $this->parent_rec->inq_id;

        $q = Doctrine_Query::create()->from('Question q');
        $q->where('q.ques_inq_id = ?', $inq_id);
        $q->andWhereIn('q.ques_status', Question::get_active_status());
        $q->leftJoin('q.ProfileMap pm');
        return $q;
    }


    /**
     * Fetch
     *
     * @param string  $uuid
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid) {
        $q = $this->air_query();
        $q->andWhere('q.ques_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array   $data
     * @return Question $q
     */
    protected function air_create($data) {
        if (!isset($data['ques_template']) && !isset($data['duplicate'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "Missing required param: ques_template OR duplicate");
        }

        $q = new Question();
        $q->ques_inq_id = $this->parent_rec->inq_id;

        // rethrow as api exceptions
        try {
            if (isset($data['ques_template'])) {
                AIR2_QueryBuilder::make_question($q, $data['ques_template']);
            }
            elseif (isset($data['duplicate'])) {
                AIR2_QueryBuilder::copy_question($q, $data['duplicate']);
            }
        }
        catch (Exception $e) {
            throw new Rframe_Exception(RFrame::BAD_DATA, $e->getMessage());
        }

        // optionally fix the whole sequence
        if (isset($data['resequence'])) {
            $this->_fix_sequence($q, $data['resequence']);
        }

        return $q;
    }


    /**
     * Make sure updates don't break the record locks
     *
     * @param Question $rec
     * @param array   $data
     */
    protected function air_update(Question $rec, $data) {
        $locks = json_decode($rec->ques_locks, true);
        $locks = $locks ? $locks : array();

        // look for updates to locked columns
        $bad_updates = array();
        foreach ($data as $key => $val) {
            if (in_array($key, $locks)) $bad_updates[] = $key;
        }

        // look for updates to locked options
        if (isset($data['ques_resp_opts'])) {

            // get original values
            $orig_opts = json_decode($rec->ques_resp_opts, true);
            $orig_opts = $orig_opts ? $orig_opts : array();

            // get updated vals
            $new_opts = json_decode($data['ques_resp_opts'], true);
            $new_opts = $new_opts ? $new_opts : array();

            // merge non-locked updated vals with original vals
            // in order to preserve locked vals
            foreach ($new_opts as $key => $val) {
                if (!in_array($key, $locks)) {
                    $orig_opts[$key] = $val;
                }
            }

            // reset merged data into update
            $data['ques_resp_opts'] = json_encode($orig_opts);
        }

        // throw combined exception
        if (count($bad_updates)) {
            $col = implode(', ', $bad_updates);
            $msg = "Invalid updates to locked columns: $col";
            throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
        }

        // resequence other questions
        if (isset($data['resequence'])) {
            $this->_fix_sequence($rec, $data['resequence']);
        }

    }


    /**
     * Ensure question is not required.
     * Check for responses, and fix sequence AFTER deleting a question
     *
     * @param Question $rec
     */
    protected function rec_delete(Question $rec) {
        if ($rec->user_may_delete($this->user)) {
            if (in_array(
                $rec->ques_template,
                array(
                    Question::$TKEY_FIRSTNAME,
                    Question::$TKEY_LASTNAME,
                    Question::$TKEY_EMAIL,
                    Question::$TKEY_ZIP
                )
            )){
                $msg = 'Unable to delete question: ' . $rec->ques_value . ' is required!';
                throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
            }

            $conn = AIR2_DBManager::get_master_connection();
            $q = 'select count(*) from src_response where sr_ques_id = ?';
            $n = $conn->fetchOne($q, array($rec->ques_id), 0);
            if ($n > 0) {
                $msg = 'Unable to delete question: responses exist!';
                throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
            }
        }

        parent::rec_delete($rec);
        $this->_fix_sequence();
    }


    /**
     * Fix the question sequence numbers for this query, given the question
     * that has changed, and its new sequence number.
     *
     * @param Question $ques
     * @param int     $seq
     */
    protected function _fix_sequence(Question $ques=null, $seq=null) {
        if ($ques) {
            if (!is_int($seq) || $seq < 1) {
                throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid sequence '$seq'");
            }
            $ques->ques_dis_seq = $seq;
        }

        // get all existing questions
        $q = Doctrine_Query::create()->from('Question q');

//         $q->setConnection(AIR2_DBManager::get_master_connection());
        $q->where('q.ques_inq_id = ?', $this->parent_rec->inq_id);
        if ($ques && $ques->ques_id) {
            $q->addWhere('q.ques_id != ?', $ques->ques_id);
        }
        $q->orderBy('q.ques_dis_seq asc');
        $rs = $q->execute();

        $current_seq_num = 1;
        foreach ($rs as $idx => $rec) {
            if ($current_seq_num == $seq) {
                $current_seq_num++;
            }

            // update and save
            $rec->ques_dis_seq = $current_seq_num;

            // compensate for doctrines agressive caching
            if ($rec->exists()) {
                $rec->save();
            }
            else {
                Carper::carp("tried to reorder a non-existant question " .
                "ques_uuid:{$rec->ques_uuid} ques_id:{$rec->ques_id} " .
                "ques_value:{$rec->ques_value} of inquery $rec->ques_inq_id");
            }

            $current_seq_num++;
        }
    }


    /**
     * Mark inquiry as stale
     *
     * @param Question $rec
     */
    protected function update_parent(Question $rec) {
        $upd = 'update inquiry set inq_stale_flag=1 where inq_id = ?';
        AIR2_DBManager::get_master_connection()->exec($upd, array($rec->ques_inq_id));
    }


}
