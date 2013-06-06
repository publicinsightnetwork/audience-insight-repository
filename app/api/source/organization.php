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
 * Source/Organization API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Source_Organization extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('org_uuid', 'so_home_flag', 'so_status');
    protected $UPDATE_DATA = array('so_home_flag', 'so_status');

    // default paging/sorting
    protected $sort_default   = 'org_display_name asc';
    protected $sort_valids    = array('so_home_flag', 'so_status', 'org_display_name');

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
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
        'Organization' => 'DEF::ORGANIZATION',
        'org_uuid',
        'org_name',
        'org_display_name',
        'org_html_color',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $src_id = $this->parent_rec->src_id;

        $q = Doctrine_Query::create()->from('SrcOrg s');
        $q->andWhere('s.so_src_id = ?', $src_id);
        $q->leftJoin('s.CreUser cu');
        $q->leftJoin('s.UpdUser uu');
        $q->leftJoin('s.Organization o');

        // flatten
        $q->addSelect('o.org_uuid as org_uuid');
        $q->addSelect('o.org_name as org_name');
        $q->addSelect('o.org_display_name as org_display_name');
        $q->addSelect('o.org_html_color as org_html_color');
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
        $q->andWhere('s.so_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    protected function air_create($data) {
        if (!isset($data['org_uuid'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Must specify org_uuid');
        }
        $org = AIR2_Record::find('Organization', $data['org_uuid']);
        if (!$org) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid org_uuid');
        }

        $so = new SrcOrg();
        $so->Source = $this->parent_rec;
        $so->Organization = $org;
        return $so;
    }


}
