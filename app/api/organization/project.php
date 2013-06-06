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
 * Organization/Project API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Organization_Project extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update', 'delete');
    protected $CREATE_DATA = array('prj_uuid', 'user_uuid');
    protected $UPDATE_DATA = array('user_uuid');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'porg_cre_dtim desc';
    protected $sort_valids    = array('porg_cre_dtim', 'prj_display_name');

    // metadata
    protected $ident = 'prj_uuid';
    protected $fields = array(
        'porg_status',
        'porg_cre_dtim',
        'porg_upd_dtim',
        'Project' => 'DEF::PROJECT',
        'ContactUser' => array(
            'DEF::USERSTAMP',
            'UserEmailAddress' => array('uem_uuid', 'uem_address', 'uem_primary_flag'),
            'UserPhoneNumber' => array('uph_uuid', 'uph_country', 'uph_number', 'uph_ext', 'uph_primary_flag'),
        ),
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
        'prj_uuid',
        'prj_display_name',
        'user_username',
        'user_uuid',
        'inq_count',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $org_id = $this->parent_rec->org_id;

        $q = Doctrine_Query::create()->from('ProjectOrg po');
        $q->where('po.porg_org_id = ?', $org_id);
        $q->leftJoin('po.Project p');
        $q->leftJoin('po.ContactUser u');
        $q->leftJoin('po.CreUser poc');
        $q->leftJoin('po.UpdUser pou');
        $q->leftJoin('u.UserEmailAddress ue WITH ue.uem_primary_flag = true');
        $q->leftJoin('u.UserPhoneNumber up WITH up.uph_primary_flag = true');

        // flatten some org fields
        $q->addSelect('p.prj_display_name as prj_display_name');
        $q->addSelect('p.prj_uuid as prj_uuid');
        $q->addSelect('u.user_username as user_username');
        $q->addSelect('u.user_uuid as user_uuid');

        // add query count
        $count = 'select count(*) from project_inquiry';
        $q->addSelect("($count where pinq_prj_id = po.porg_prj_id) as inq_count");
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
        $q->andWhere('p.prj_uuid = ?', $uuid);
        return $q->fetchOne();
    }

    /**
     * Create
     *
     * @param array $data
     * @return ProjectOrg $rec
     */
    protected function air_create($data) {
        $this->require_data($data, array('prj_uuid'));

        // validate
        $p = AIR2_Record::find('Project', $data['prj_uuid']);
        if (!$p) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid prj_uuid');
        }
       
        // unique project
        foreach ($this->parent_rec->ProjectOrg as $porg) {
            if ($porg->porg_org_id == $p->prj_id) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Project already in Organization');
            }
        }

        $u = AIR2_Record::find('User', $data['user_uuid']);
        // user in org, and has W/M role
        $org_and_parents = Organization::get_org_parents($this->parent_rec->org_id);
        $org_and_parents[] = $this->parent_rec->org_id;
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
        $rec->porg_org_id = $this->parent_rec->org_id;
        $rec->porg_prj_id = $p->prj_id;
        $rec->porg_contact_user_id = $u->user_id;
        $rec->mapValue('prj_uuid', $p->prj_uuid);
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
            $rec->ContactUser = $u;
        }
    }


}
