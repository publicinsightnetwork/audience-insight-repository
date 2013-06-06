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
 * Tank/Organization API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Tank_Organization extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch');
    protected $CREATE_DATA = array();
    protected $QUERY_ARGS  = array();
    protected $UPDATE_DATA = array();

    // default paging/sorting
    protected $sort_default   = 'org_display_name asc';
    protected $sort_valids    = array('org_display_name', 'org_name', 'org_cre_dtim');

    // metadata
    protected $ident = 'to_id';
    protected $fields = array(
        'to_id',
        'to_so_status',
        'to_so_home_flag',
        // flatten
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
        $q = Doctrine_Query::create()->from('TankOrg to');
        $q->addWhere('to.to_tank_id = ?', $this->parent_rec->tank_id);
        $q->leftJoin('to.Organization o');

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
        $q->where('to.to_id = ?', $uuid);
        return $q->fetchOne();
    }


}
