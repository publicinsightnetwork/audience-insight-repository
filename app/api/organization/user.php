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
 * Organization/User API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Organization_User extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'update', 'create');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('user_uuid', 'uo_home_flag', 'uo_ar_id');
    protected $UPDATE_DATA = array('uo_home_flag', 'uo_ar_id');

    // default paging/sorting
    protected $sort_default   = 'user_first_name asc';
    protected $sort_valids    = array('user_status', 'user_first_name');

    // metadata
    protected $ident = 'uo_uuid';
    protected $fields = array(
        'uo_uuid',
        'uo_ar_id',
        'uo_home_flag',
        'uo_user_title',
        'uo_cre_dtim',
        'uo_upd_dtim',
        'AdminRole' => array(
            'ar_id',
            'ar_code',
            'ar_name',
        ),
        'User' => 'DEF::USERSTAMP',
        'user_username',
        'user_uuid',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $org_id = $this->parent_rec->org_id;

        $q = Doctrine_Query::create()->from('UserOrg uo');
        $q->where('uo.uo_org_id = ?', $org_id);
        $q->leftJoin('uo.User u');
        $q->leftJoin('uo.AdminRole ar');

        // flatten some user fields
        $q->addSelect('u.user_username as user_username');
        $q->addSelect('u.user_uuid as user_uuid');
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
        $q->andWhere('uo.uo_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array $data
     * @return UserOrg $rec
     */
    protected function air_create($data) {
        $uo = new UserOrg();
        $uo->uo_org_id = $this->parent_rec->org_id;

        // valid user
        if (!isset($data['user_uuid'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Must specify user_uuid');
        }
        $user = AIR2_Record::find('User', $data['user_uuid']);
        if (!$user) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid user_uuid');
        }
        $uo->User = $user;

        // unique user_uuid for org
        $q = Doctrine_Query::create()->from('UserOrg uo');
        $q->andWhere('uo_user_id = ?', $user->user_id);
        $q->andWhere('uo_org_id = ?', $this->parent_rec->org_id);
        if ($q->count() > 0) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'User already belongs to Organization');
        }

        // check for space in this Org
        if ($this->parent_rec->is_full()) {
            $n = $this->parent_rec->org_display_name;
            throw new Rframe_Exception(Rframe::BAD_DATA, "Max users for '$n' reached");
        }
        return $uo;
    }


    /**
     * Update
     *
     * @param UserOrg $uo
     * @param array $data
     */
    protected function air_update(UserOrg $uo, $data) {
        if (isset($data['uo_ar_id'])) {
            $uo->uo_ar_id = $data['uo_ar_id'];
            $uo->refreshRelated('AdminRole');
        }
    }


}
