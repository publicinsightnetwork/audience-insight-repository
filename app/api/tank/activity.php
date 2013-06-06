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
 * Tank/Activity API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Tank_Activity extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch');
    protected $CREATE_DATA = array();
    protected $QUERY_ARGS  = array();
    protected $UPDATE_DATA = array();

    // default paging/sorting
    protected $sort_default   = 'tact_dtim asc';
    protected $sort_valids    = array('tact_dtim', 'tact_id');

    // metadata
    protected $ident = 'tact_id';
    protected $fields = array(
        'tact_id',
        'tact_type',
        'tact_dtim',
        'tact_desc',
        'tact_notes',
        'tact_ref_type',
        // flattened
        'prj_uuid',
        'prj_name',
        'prj_display_name',
        'actm_id',
        'actm_name',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('TankActivity a');
        $q->addWhere('a.tact_tank_id = ?', $this->parent_rec->tank_id);
        $q->leftJoin('a.Project p');
        $q->leftJoin('a.ActivityMaster m');

        // flatten
        $q->addSelect('p.prj_uuid as prj_uuid');
        $q->addSelect('p.prj_name as prj_name');
        $q->addSelect('p.prj_display_name as prj_display_name');
        $q->addSelect('m.actm_id as actm_id');
        $q->addSelect('m.actm_name as actm_name');
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
        $q->where('a.tact_id = ?', $uuid);
        return $q->fetchOne();
    }


}
