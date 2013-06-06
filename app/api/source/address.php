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
 * Source/Address API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Source_Address extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('smadd_primary_flag', 'smadd_context', 'smadd_line_1',
        'smadd_line_2', 'smadd_city', 'smadd_state', 'smadd_county', 'smadd_cntry', 'smadd_zip');
    protected $UPDATE_DATA = array('smadd_primary_flag', 'smadd_context', 'smadd_line_1',
        'smadd_line_2', 'smadd_city', 'smadd_state', 'smadd_county', 'smadd_cntry', 'smadd_zip');

    // default paging/sorting
    protected $sort_default   = 'smadd_cre_dtim asc';
    protected $sort_valids    = array('smadd_cre_dtim', 'smadd_upd_dtim', 'smadd_primary_flag');

    // metadata
    protected $ident = 'smadd_uuid';
    protected $fields = array(
        'DEF::SRCMAIL',
        'smadd_cre_dtim',
        'smadd_upd_dtim',
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

        $q = Doctrine_Query::create()->from('SrcMailAddress m');
        $q->andWhere('m.smadd_src_id = ?', $src_id);
        $q->leftJoin('m.CreUser cu');
        $q->leftJoin('m.UpdUser uu');
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
        $q->andWhere('m.smadd_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record
     */
    protected function air_create($data) {
        $rec = new SrcMailAddress();
        $rec->Source = $this->parent_rec;
        return $rec;
    }


}
