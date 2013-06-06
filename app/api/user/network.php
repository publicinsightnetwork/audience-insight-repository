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
 * User/Network API
 *
 * @author rcavis
 * @package default
 */
class AAPI_User_Network extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('uuri_type', 'uuri_value', 'uuri_feed', 'uuri_handle');
    protected $UPDATE_DATA = array('uuri_type', 'uuri_value', 'uuri_feed', 'uuri_handle');

    // default paging/sorting
    protected $sort_default   = 'uuri_type asc';
    protected $sort_valids    = array('uuri_type', 'uuri_value', 'uuri_handle');

    // metadata
    protected $ident = 'uuri_uuid';
    protected $fields = array(
        'uuri_uuid',
        'uuri_type',
        'uuri_value',
        'uuri_feed',
        'uuri_upd_int',
        'uuri_handle',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $user_id = $this->parent_rec->user_id;

        $q = Doctrine_Query::create()->from('UserUri u');
        $q->where('u.uuri_user_id = ?', $user_id);
        $q->andWhere('u.uuri_type != "?"');
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
        $q->andWhere('u.uuri_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array $data
     * @return UserOrg $rec
     */
    protected function air_create($data) {
        $this->require_data($data, array('uuri_type', 'uuri_value'));
        $uu = new UserUri();
        $uu->uuri_user_id = $this->parent_rec->user_id;
        return $uu;
    }


}
