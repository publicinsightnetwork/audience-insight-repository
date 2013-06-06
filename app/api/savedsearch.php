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
 * SavedSearch API
 *
 * @author rcavis
 * @package default
 */
class AAPI_SavedSearch extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('ssearch_uuid', 'ssearch_name', 'ssearch_params', 'ssearch_shared_flag');
    protected $UPDATE_DATA = array('ssearch_name', 'ssearch_params', 'ssearch_shared_flag');

    // default paging/sorting
    protected $limit_default  = 10;
    protected $offset_default = 0;
    protected $sort_default   = 'ssearch_cre_dtim desc';
    protected $sort_valids    = array('ssearch_cre_dtim');

    // metadata
    protected $ident = 'ssearch_uuid';
    protected $fields = array(
        'ssearch_uuid',
        'ssearch_name',
        'ssearch_params',
        'ssearch_shared_flag',
        'ssearch_cre_dtim',
        'ssearch_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
    );


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        $p = new SavedSearch();
        return $p;
    }


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('SavedSearch ss');
        $q->leftJoin('ss.CreUser cu');
        $q->leftJoin('ss.UpdUser uu');
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
        $q->where('ss.ssearch_uuid = ?', $uuid);
        return $q->fetchOne();
    }


}
