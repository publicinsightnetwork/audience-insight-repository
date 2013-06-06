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
 * Project/Organization API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Project_Organization extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('org_uuid', 'user_uuid');
    protected $UPDATE_DATA = array('user_uuid');

    // default paging/sorting
    protected $sort_default   = 'porg_cre_dtim desc';
    protected $sort_valids    = array('porg_cre_dtim', 'org_display_name');

    // metadata
    protected $ident = 'org_uuid';
    protected $fields = array(
        'porg_status',
        'porg_cre_dtim',
        'porg_upd_dtim',
        'Organization' => 'DEF::ORGANIZATION',
        'ContactUser' => array(
            'DEF::USERSTAMP',
            'UserEmailAddress' => array('uem_uuid', 'uem_address', 'uem_primary_flag'),
            'UserPhoneNumber' => array('uph_uuid', 'uph_country', 'uph_number', 'uph_ext', 'uph_primary_flag'),
        ),
        'org_uuid',
        'org_display_name',
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
        $prj_id = $this->parent_rec->prj_id;

        $q = Doctrine_Query::create()->from('ProjectOrg po');
        $q->where('po.porg_prj_id = ?', $prj_id);
        $q->leftJoin('po.Organization o');
        $q->leftJoin('po.ContactUser u');
        $q->leftJoin('u.UserEmailAddress e WITH e.uem_primary_flag = true');
        $q->leftJoin('u.UserPhoneNumber p WITH p.uph_primary_flag = true');

        // flatten some org fields
        $q->addSelect('o.org_display_name as org_display_name');
        $q->addSelect('o.org_uuid as org_uuid');
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
    protected function air_fetch($uuid, $minimal=false) {
        if ($minimal) {
            $q = Doctrine_Query::create()->from('ProjectOrg po');
            $q->leftJoin('po.Organization o');
            $q->where('po.porg_prj_id = ?', $this->parent_rec->prj_id);
        }
        else {
            $q = $this->air_query();
        }
        $q->andWhere('o.org_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array $data
     * @return ProjectOrg $rec
     */
    protected function air_create($data) {
        $this->require_data($data, array('org_uuid', 'user_uuid'));

        // validate
        $o = AIR2_Record::find('Organization', $data['org_uuid']);
        if (!$o) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid org_uuid');
        }
        $u = AIR2_Record::find('User', $data['user_uuid']);
        if (!$u) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid user_uuid');
        }

        // unique org
        foreach ($this->parent_rec->ProjectOrg as $porg) {
            if ($porg->porg_org_id == $o->org_id) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Organization already in Project');
            }
        }

        // user in org, and has W/M role
        $org_and_parents = Organization::get_org_parents($o->org_id);
        $org_and_parents[] = $o->org_id;
        $in_org = false;
        foreach ($u->UserOrg as $uo) {
            $r = $uo->AdminRole->ar_code;
            if (in_array($uo->uo_org_id, $org_and_parents)) {
                if ($r == 'W' || $r == 'M') {
                    $in_org = true;
                    break;
                }
            }
        }
        if (!$in_org) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'ContactUser not Writer/Manager for organization');
        }

        // create!
        $rec = new ProjectOrg();
        $rec->porg_prj_id = $this->parent_rec->prj_id;
        $rec->porg_org_id = $o->org_id;
        $rec->porg_contact_user_id = $u->user_id;
        $rec->mapValue('org_uuid', $o->org_uuid);
        return $rec;
    }


    /**
     * Update
     *
     * @param ProjectOrg $rec
     * @param array      $data
     */
    protected function air_update($rec, $data) {
        if (isset($data['user_uuid'])) {
            $u = AIR2_Record::find('User', $data['user_uuid']);
            if (!$u) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid user_uuid');
            }

            // user in org, and has W/M role
            $org_and_parents = Organization::get_org_parents($rec->porg_org_id);
            $org_and_parents[] = $rec->porg_org_id;
            $in_org = false;
            foreach ($u->UserOrg as $uo) {
                $r = $uo->AdminRole->ar_code;
                if (in_array($uo->uo_org_id, $org_and_parents)) {
                    if ($r == 'W' || $r == 'M') {
                        $in_org = true;
                        break;
                    }
                }
            }
            if (!$in_org) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'ContactUser not Writer/Manager for organization');
            }

            // set
            $rec->porg_contact_user_id = $u->user_id;
        }
    }


}
