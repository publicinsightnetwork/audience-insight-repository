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
 * Source/Phone API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Source_Phone extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('sph_primary_flag', 'sph_context', 'sph_country', 'sph_number', 'sph_ext');
    protected $UPDATE_DATA = array('sph_primary_flag', 'sph_context', 'sph_country', 'sph_number', 'sph_ext');

    // default paging/sorting
    protected $sort_default   = 'sph_cre_dtim asc';
    protected $sort_valids    = array('sph_cre_dtim', 'sph_upd_dtim', 'sph_primary_flag');

    // metadata
    protected $ident = 'sph_uuid';
    protected $fields = array(
        'DEF::SRCPHONE',
        'sph_cre_dtim',
        'sph_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $src_id = $this->parent_rec->src_id;

        $q = Doctrine_Query::create()->from('SrcPhoneNumber p');
        $q->andWhere('p.sph_src_id = ?', $src_id);
        $q->leftJoin('p.CreUser cu');
        $q->leftJoin('p.UpdUser uu');
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
        $q->andWhere('p.sph_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record
     */
    protected function air_create($data) {
        $rec = new SrcPhoneNumber();
        $rec->Source = $this->parent_rec;
        return $rec;
    }


}
