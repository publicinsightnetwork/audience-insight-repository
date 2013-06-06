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
 * Project API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Project extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'create', 'fetch', 'update', 'delete');
    protected $CREATE_DATA = array('org_uuid', 'inq_uuid', 'prj_name',
        'prj_display_name', 'prj_desc');
    protected $QUERY_ARGS  = array('status', 'org_uuid', 'excl_inq', 'excl_org',
        'excl_out');
    protected $UPDATE_DATA = array('prj_name', 'prj_display_name', 'prj_desc',
        'prj_status');

    // default paging/sorting
    protected $query_args_default = array('status' => 'AP');  // Active&Published
    protected $limit_default  = 10;
    protected $offset_default = 0;
    protected $sort_default   = 'prj_display_name asc';
    protected $sort_valids    = array('prj_display_name', 'prj_status', 'prj_cre_dtim');

    // metadata
    protected $ident = 'prj_uuid';
    protected $fields = array(
        'prj_uuid',
        'prj_name',
        'prj_display_name',
        'prj_desc',
        'prj_status',
        'prj_type',
        'prj_cre_dtim',
        'prj_upd_dtim',
        'ProjectOrg' => array('porg_status', 'Organization' => 'DEF::ORGANIZATION'),
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
        'inquiry_count',
    );

    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        $p = new Project();

        // org_uuid required
        if (!isset($data['org_uuid'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Project Organization uuid required!');
        }

        $org = AIR2_Record::find('Organization', $data['org_uuid']);
        if (!$org) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid Organization specified!');
        }
        $p->ProjectOrg[0]->porg_contact_user_id = $this->user->user_id;
        $p->ProjectOrg[0]->Organization = $org;

        // immediately add inquiry to project
        if (isset($data['inq_uuid'])) {
            $inq = AIR2_Record::find('Inquiry', $data['inq_uuid']);
            if (!$inq) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid Inquiry specified!');
            }
            if (!$inq->user_may_write($this->user)) {
                throw new Rframe_Exception(Rframe::BAD_AUTHZ, 'Invalid Inquiry authz!');
            }
            $p->ProjectInquiry[0]->Inquiry = $inq;
        }
        return $p;
    }


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('Project p');
        $q->leftJoin('p.ProjectOrg po');
        $q->leftJoin('po.Organization o');
        $q->leftJoin('p.CreUser c');
        $q->leftJoin('p.UpdUser u');

        // status
        if (isset($args['status'])) {
            air2_query_in($q, $args['status'], 'p.prj_status');
        }

        // with a certain member org
        if (isset($args['org_uuid'])) {
            $q->addWhere('o.org_uuid = ?', $args['org_uuid']);
        }

        // exclude an inquiry
        if (isset($args['excl_inq'])) {
            $inqq = "select inq_id from inquiry where inq_uuid = ?";
            $excl = "select pinq_prj_id from project_inquiry where pinq_inq_id = ($inqq)";
            $q->addWhere("p.prj_id not in ($excl)", $args['excl_inq']);
        }

        // exclude an organization
        if (isset($args['excl_org'])) {
            $orgq = "select org_id from organization where org_uuid = ?";
            $excl = "select porg_prj_id from project_org where porg_org_id = ($orgq)";
            $q->addWhere("p.prj_id not in ($excl)", $args['excl_org']);
        }

        // exclude an outcome
        if (isset($args['excl_out'])) {
            $outq = "select out_id from outcome where out_uuid = ?";
            $excl = "select pout_prj_id from prj_outcome where pout_out_id = ($outq)";
            $q->addWhere("p.prj_id not in ($excl)", $args['excl_out']);
        }

        // add query count
        $count = 'select count(*) from project_inquiry';
        $q->addSelect("($count where pinq_prj_id = p.prj_id) as inquiry_count");
        return $q;
    }


    /**
     * Fetch
     *
     * @param string $uuid
     * @param bool   $minimal
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid, $minimal=false) {
        if ($minimal) {
            $q = Doctrine_Query::create()->from('Project p');
        }
        else {
            $q = $this->air_query();
        }
        $q->where('p.prj_uuid = ?', $uuid);
        return $q->fetchOne();
    }


}
