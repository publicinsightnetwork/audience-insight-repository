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
 * Submission/Response API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Submission_Response extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'update');
    protected $QUERY_ARGS  = array('notnull', 'minimal');
    protected $CREATE_DATA = array();
    protected $UPDATE_DATA = array('sr_mod_value', 'sr_public_flag');

    // default paging/sorting
    // NOTE that we custom sort responses since we want to mimic display order
    protected $sort_default   = 'ques_dis_seq asc';
    protected $sort_valids    = array('ques_dis_seq', 'sr_cre_dtim');

    // metadata
    protected $ident = 'sr_uuid';
    protected $fields = array(
        'sr_uuid',
        'sr_media_asset_flag',
        'sr_orig_value',
        'sr_mod_value',
        'sr_public_flag',
        'sr_status',
        'sr_cre_dtim',
        'sr_upd_dtim',
        'UpdUser'  => 'DEF::USERSTAMP',
        'Question' => array(
            'ques_uuid',
            'ques_dis_seq',
            'ques_status',
            'ques_type',
            'ques_value',
            'ques_choices',
            'ques_public_flag',
        ),
        'SrcResponseSet' => array(
            'srs_uuid',
            'srs_public_flag',
        ),
        'annot_count',
        'SrAnnotation' => array(
            'sran_value',
            'sran_upd_dtim',
            'CreUser' => array(
                'DEF::USERSTAMP',
                'UserUri' => array(
                    'uuri_value',
                ),
                'UserOrg' => 'DEF::USERORG',
            )
        ),
        'args',
    );



    /**
     * Override parent method to sort responses with air2_sort_responses_for_display().
     *
     * @param Doctrine results $list
     * @return array
     */
    protected function format_query_radix($list) {
        $radix = parent::format_query_radix($list);
        $sorted_radix = air2_sort_responses_for_display($radix);
        return $sorted_radix;
    }


    /**
     * Query
     *
     * @param array   $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $minimal = false;
        extract($args);

        $srs_id = $this->parent_rec->srs_id;

        $q = Doctrine_Query::create()->from('SrcResponse r');
        $q->andWhere('r.sr_srs_id = ?', $srs_id);
        $q->leftJoin('r.Question q');
        $q->leftJoin('r.SrcResponseSet srs');
        $q->leftJoin('r.UpdUser uu');

        // If not minimal, include annotations.
        if ($minimal == 'false') {
            $q->leftJoin('r.SrAnnotation ss');
            $q->leftJoin('ss.CreUser ssc');

            $q->leftJoin('ssc.UserOrg ssco');
            $q->leftJoin('ssco.Organization sscoo');
            $q->andWhere('ssco.uo_home_flag = true');

            // $q->leftJoin('ssc.UserUri sscu');
            // $q->andWhere('sscu.uuri_type = ?', UserUri::$TYPE_PHOTO);
        }

        if (isset($args['notnull']) && $args['notnull']) {
            $q->andWhere("r.sr_orig_value is not null");
            $q->andWhere("r.sr_orig_value != ''");
        }

        // annotation count
        $count = 'select count(*) from sr_annotation where sran_sr_id = r.sr_id';
        $q->addSelect("($count) as annot_count");

        return $q;
    }


    /**
     * Fetch
     *
     * @param string  $uuid
     * @param unknown $minimal
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid, $minimal) {

        $q = $this->air_query();
        $q->andWhere('(r.sr_uuid = ? or r.sr_id = ?)', array($uuid, $uuid));

        return $q->fetchOne();
    }


    /**
     * Update
     *
     * @param Doctrine_Record $rec
     * @param array   $data
     */
    protected function air_update($rec, $data) {
        $rec->sr_upd_user = $this->user->user_id;
        air2_touch_stale_record('src_response_set', $rec->sr_srs_id);
        // touch public_response just in case. if it isn't public, it will be skipped.
        air2_touch_stale_record('public_response', $rec->sr_srs_id);
    }


}
