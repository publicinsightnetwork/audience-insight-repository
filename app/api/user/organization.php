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
 * User/Organization API
 *
 * @author rcavis
 * @package default
 */
class AAPI_User_Organization extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('uo_home_flag', 'uo_notify_flag',
        'uo_status', 'uo_ar_id', 'org_uuid');
    protected $UPDATE_DATA = array('uo_home_flag', 'uo_notify_flag',
        'uo_status', 'uo_ar_id');

    // default paging/sorting
    protected $sort_default   = 'org_display_name asc';
    protected $sort_valids    = array('org_display_name', 'uo_home_flag');

    // metadata
    protected $ident = 'uo_uuid';
    protected $fields = array(
        'uo_uuid',
        'uo_ar_id',
        'uo_user_title',
        'uo_status',
        'uo_notify_flag',
        'uo_home_flag',
        'uo_cre_dtim',
        'uo_upd_dtim',
        'Organization' => 'DEF::ORGANIZATION',
        'AdminRole' => array(
            'ar_id',
            'ar_code',
            'ar_name',
        ),
        'org_uuid',
        'org_display_name',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $user_id = $this->parent_rec->user_id;

        $q = Doctrine_Query::create()->from('UserOrg uo');
        $q->leftJoin('uo.Organization o');
        $q->leftJoin('uo.AdminRole r');
        $q->where('uo.uo_user_id = ?', $user_id);
        $q->addSelect('o.org_uuid as org_uuid');
        $q->addSelect('o.org_display_name as org_display_name');
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
        $uo->uo_user_id = $this->parent_rec->user_id;

        // valid org
        if (!isset($data['org_uuid'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Must specify org_uuid');
        }
        $org = AIR2_Record::find('Organization', $data['org_uuid']);
        if (!$org) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid org_uuid');
        }
        if ($org->is_full()) {
            $n = $org->org_display_name;
            throw new Rframe_Exception(Rframe::BAD_DATA, "Max users for '$n' reached");
        }
        $uo->Organization = $org;

        // unique org_uuid for user
        $q = Doctrine_Query::create()->from('UserOrg uo');
        $q->andWhere('uo_user_id = ?', $this->parent_rec->user_id);
        $q->andWhere('uo_org_id = ?', $org->org_id);
        if ($q->count() > 0) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'User already belongs to org_uuid');
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
