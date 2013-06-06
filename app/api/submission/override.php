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
 * Submission/Response/Edit API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Submission_Override extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'create', 'fetch', 'update', 'delete');
    protected $CREATE_DATA = array('sr_orig_value');
    protected $UPDATE_DATA = array('sr_mod_value');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'sr_cre_dtim desc';
    protected $sort_valids    = array('sr_cre_dtim', 'sr_upd_dtim');

    // metadata
    protected $ident = 'sr_id';
    protected $fields = array(
        'sr_id',
        'sr_orig_value',
        'sr_mod_value',
        'sr_ques_id',
        'sr_cre_dtim',
        'sr_upd_dtim',
        'Question' => array(
            'ques_uuid',
            'ques_dis_seq',
            'ques_status',
            'ques_type',
            'ques_value',
            'ques_choices',
        ),
        'CreUser' => array(
            'DEF::USERSTAMP',
            'UserOrg' => 'DEF::USERORG',
            'Avatar'  => 'DEF::IMAGE',
        ),
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $sr_srs_id = $this->parent_rec->srs_id;

        $q = Doctrine_Query::create()->from('SrcResponse a');
        $q->leftJoin('a.Question q');
        $q->leftJoin('a.CreUser u');
        $q->leftJoin('u.UserOrg uo WITH uo.uo_home_flag = true');
        $q->leftJoin('uo.Organization o');
        $q->leftJoin("u.Avatar av WITH av.img_ref_type = ?", 'A');
        $q->andWhere('a.sr_srs_id = ?', $sr_srs_id);
        $q->andWhere('q.ques_type = ?', 'p');
        return $q;
    }


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        $sresp = new SrcResponse();
        $sresp->srs_cre_user = $this->user->user_id;
        $sresp->srs_upd_user = $this->user->user_id;
        return $sresp;
    }


    /**
     * Fetch
     *
     * @param string $uuid
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid) {
        $q = $this->air_query();
        $q->andWhere('a.sr_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Update
     *
     * @param Doctrine_Record $rec
     * @param array $data
     */
     protected function air_update($rec, $data) {
        $rec->sr_upd_user = $this->user->user_id;
        air2_touch_stale_record('src_response_set', $rec->sr_srs_id);
    }


}
