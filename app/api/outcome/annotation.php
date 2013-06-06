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
 * Outcome/Annotation API
 *
 * @author echristiansen
 * @package default
 */
class AAPI_Outcome_Annotation extends AIRAPI_Resource {
	// API definitions
    protected $ALLOWED = array('query', 'create', 'fetch', 'update', 'delete');
    protected $CREATE_DATA = array('oa_value');
    protected $UPDATE_DATA = array('oa_value');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'oa_cre_dtim desc';
    protected $sort_valids    = array('oa_cre_dtim');

    // metadata
    protected $ident = 'oa_id';
    protected $fields = array(
        'oa_id',
        'oa_value',
        'oa_cre_dtim',
        'oa_upd_dtim',
        'CreUser' => array(
            'DEF::USERSTAMP',
            'UserOrg' => 'DEF::USERORG',
        ),
    );

    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $out_id = $this->parent_rec->out_id;

        $q = Doctrine_Query::create()->from('OutAnnotation a');
        $q->where('a.oa_out_id = ?', $out_id);
        $q->leftJoin('a.CreUser u');
        return $q;
    }


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        $oa = new OutAnnotation();
        $oa->Outcome = $this->parent_rec;
        $oa->oa_cre_user = $this->user->user_id;
        $oa->oa_upd_user = $this->user->user_id;
        return $oa;
    }
    

    /**
     * Fetch
     *
     * @param string $uuid
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid) {
        $q = $this->air_query();
        $q->andWhere('a.oa_id = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Update
     *
     * @param Doctrine_Record $rec
     * @param array $data
     */
    protected function air_update($rec, $data) {
        $rec->oa_upd_user = $this->user->user_id;
    }

}