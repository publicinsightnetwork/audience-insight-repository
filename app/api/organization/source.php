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
 * Organization/Source API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Organization_Source extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'so_cre_dtim desc';
    protected $sort_valids    = array('so_cre_dtim');

    // metadata
    protected $ident = 'so_uuid';
    protected $fields = array(
        'so_uuid',
        'so_effective_date',
        'so_home_flag',
        'so_lock_flag',
        'so_status',
        'so_cre_dtim',
        'so_upd_dtim',
        'Source' => array('DEF::SOURCE', 'src_cre_dtim'),
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $org_id = $this->parent_rec->org_id;

        $q = Doctrine_Query::create()->from('SrcOrg so');
        $q->where('so.so_org_id = ?', $org_id);
        $q->leftJoin('so.Source s');
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
        $q->andWhere('so.so_uuid = ?', $uuid);
        return $q->fetchOne();
    }


}
