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
 * Submission/Response/Annotation API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Submission_Response_Annotation extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'create', 'fetch', 'update', 'delete');
    protected $CREATE_DATA = array('sran_value');
    protected $UPDATE_DATA = array('sran_value');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'sran_cre_dtim desc';
    protected $sort_valids    = array('sran_cre_dtim', 'sran_upd_dtim');

    // metadata
    protected $ident = 'sran_id';
    protected $fields = array(
        'sran_id',
        'sran_value',
        'sran_cre_dtim',
        'sran_upd_dtim',
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
        $sr_id = $this->parent_rec->sr_id;

        $q = Doctrine_Query::create()->from('SrAnnotation a');
        $q->where('a.sran_sr_id = ?', $sr_id);
        $q->leftJoin('a.CreUser u');
        $q->leftJoin('u.UserOrg uo WITH uo.uo_home_flag = true');
        $q->leftJoin('uo.Organization o');
        $q->leftJoin("u.Avatar av WITH av.img_ref_type = ?", 'A');
        return $q;
    }


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        $sran = new SrAnnotation();
        $sran->SrcResponse = $this->parent_rec;
        $sran->sran_cre_user = $this->user->user_id;
        $sran->sran_upd_user = $this->user->user_id;
        return $sran;
    }


    /**
     * Fetch
     *
     * @param string $uuid
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid) {
        $q = $this->air_query();
        $q->andWhere('a.sran_id = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Update
     *
     * @param Doctrine_Record $rec
     * @param array $data
     */
    protected function air_update($rec, $data) {
        $rec->sran_upd_user = $this->user->user_id;
    }


}
