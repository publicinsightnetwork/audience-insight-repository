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
 * Tank API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Tank extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'delete');
    protected $CREATE_DATA = array();
    protected $QUERY_ARGS  = array('type', 'status');
    protected $UPDATE_DATA = array();

    // default paging/sorting
    protected $limit_default  = 10;
    protected $offset_default = 0;
    protected $sort_default   = 'tank_cre_dtim desc';
    protected $sort_valids    = array('tank_cre_dtim', 'tank_name');

    // metadata
    protected $ident = 'tank_uuid';
    protected $fields = array(
        'tank_uuid',
        'tank_name',
        'tank_notes',
        'tank_meta',
        'tank_type',
        'tank_status',
        'tank_cre_dtim',
        'tank_upd_dtim',
        'User' => 'DEF::USERSTAMP',
        'TankOrg' => array(
            'to_so_status',
            'to_so_home_flag',
            'Organization' => 'DEF::ORGANIZATION',
        ),
        'TankActivity' => array(
            'tact_id',
            'tact_type',
            'tact_dtim',
            'tact_desc',
            'tact_notes',
            'tact_ref_type',
            'Project' => 'DEF::PROJECT',
            'ActivityMaster' => array('actm_id', 'actm_name'),
        ),
        'count_total',
        'count_new',
        'count_conflict',
        'count_locked',
        'count_done',
        'count_error',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('Tank t');
        $q->leftJoin('t.User u');
        $q->leftJoin('t.TankOrg to');
        $q->leftJoin('to.Organization o');
        $q->leftJoin('t.TankActivity ta');
        $q->leftJoin('ta.Project p');
        $q->leftJoin('ta.ActivityMaster m');

        if (isset($args['type'])) {
            air2_query_in($q, $args['type'], 't.tank_type');
        }
        if (isset($args['status'])) {
            air2_query_in($q, $args['status'], 't.tank_status');
        }

        // add flattened and return
        Tank::add_counts($q, 't');
        TankActivity::add_event_meta($q, 'ta');
        $q->addSelect('u.user_uuid as user_uuid');
        $q->addSelect('o.org_uuid as org_uuid'); //TODO: not really flat
        $q->addSelect('p.prj_uuid as prj_uuid'); //TODO: not really flat
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
        $q->where('t.tank_uuid = ?', $uuid);
        return $q->fetchOne();
    }


}
