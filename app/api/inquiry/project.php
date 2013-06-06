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
 * Inquiry/Project API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Inquiry_Project extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('prj_uuid');

    // default paging/sorting
    protected $sort_default   = 'pinq_cre_dtim desc';
    protected $sort_valids    = array('pinq_cre_dtim', 'prj_display_name', 'prj_name');

    // metadata
    protected $ident = 'prj_uuid';
    protected $fields = array(
        'pinq_status',
        'pinq_cre_dtim',
        'pinq_upd_dtim',
        'Project' => 'DEF::PROJECT',
        'CreUser' => 'DEF::USERSTAMP',
        'prj_uuid',
    );

    // update inq_upd_user/inq_upd_dtim from this resource
    protected $update_parent_stamps = true;


    /**
     * Query
     *
     * @param array   $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $inq_id = $this->parent_rec->inq_id;

        $q = Doctrine_Query::create()->from('ProjectInquiry pi');
        $q->where('pi.pinq_inq_id = ?', $inq_id);
        $q->leftJoin('pi.Project p');
        $q->leftJoin('pi.CreUser cu');
        $q->addSelect('p.prj_uuid as prj_uuid');
        return $q;
    }


    /**
     * Fetch
     *
     * @param string  $uuid
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
     * @param array   $data
     * @return unknown
     */
    protected function air_create($data) {
        if (!isset($data['prj_uuid'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "prj_uuid required");
        }
        $prj = AIR2_Record::find('Project', $data['prj_uuid']);
        if (!$prj) {
            $u = $data['prj_uuid'];
            throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid prj_uuid '$u'");
        }
        if (!$prj->user_may_write($this->user)) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid Project authz");
        }

        $pinq = new ProjectInquiry();
        $pinq->pinq_inq_id = $this->parent_rec->inq_id;
        $pinq->Project = $prj;
        $pinq->mapValue('prj_uuid', $pinq->Project->prj_uuid);

        // log activity
        $activity = new InquiryActivity();
        $activity->ia_inq_id = $this->parent_rec->inq_id;
        $activity->ia_actm_id = 49;
        $activity->ia_dtim = air2_date();
        $activity->ia_desc = sprintf('project %s added by {USER}', $prj->prj_name);
        $this->parent_rec->InquiryActivity[] = $activity;

        return $pinq;
    }





    /**
     *
     *
     * @return unknown
     * @param unknown $pinq
     */
    protected function air_delete($pinq) {

        $project = $pinq->Project;

        // log activity
        $activity = new InquiryActivity();
        $activity->ia_inq_id = $this->parent_rec->inq_id;
        $activity->ia_actm_id = 49;
        $activity->ia_dtim = air2_date();
        $activity->ia_desc = sprintf('project %s removed by {USER}', $project->prj_name);
        $activity->save();

    }


    /**
     * Mark inquiry as stale
     *
     * @param ProjectInquiry  $rec
     */
    protected function update_parent(ProjectInquiry $rec) {
        // raw sql update rather than calling parent_rec->save()
        // because nested objects cascade 
        $upd = 'update inquiry set inq_stale_flag=1 where inq_id = ?';
        AIR2_DBManager::get_master_connection()->exec($upd, array($rec->pinq_inq_id));
    }



}
