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
 * Inquiry/Organization API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Inquiry_Organization extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('org_uuid');

    // default paging/sorting
    protected $sort_default   = 'iorg_cre_dtim asc';
    protected $sort_valids    = array('iorg_cre_dtim', 'org_name', 'org_display_name');

    // metadata
    protected $ident = 'org_uuid';
    protected $fields = array(
        'iorg_status',
        'iorg_cre_dtim',
        'iorg_upd_dtim',
        'Organization' => 'DEF::ORGANIZATION',
        'CreUser'      => 'DEF::USERSTAMP',
        'org_uuid',
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

        $q = Doctrine_Query::create()->from('InqOrg io');
        $q->addWhere('io.iorg_inq_id = ?', $inq_id);
        $q->leftJoin('io.Organization o');
        $q->leftJoin('io.CreUser cu');
        $q->addSelect('o.org_uuid as org_uuid');
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
        $q->addWhere('o.org_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array   $data
     * @return unknown
     */
    protected function air_create($data) {
        if (!isset($data['org_uuid'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "org_uuid required");
        }
        $org = AIR2_Record::find('Organization', $data['org_uuid']);
        if (!$org) {
            $u = $data['org_uuid'];
            throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid org_uuid '$u'");
        }
        if (!$this->parent_rec->user_may_write($this->user)) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "You do not appear to have access to modify this Inquiry (Invalid Inquiry authz)");
        }

        $iorg = new InqOrg();
        $iorg->iorg_inq_id = $this->parent_rec->inq_id;
        $iorg->Organization = $org;
        $iorg->mapValue('org_uuid', $iorg->Organization->org_uuid);

        // log activity
        $activity = new InquiryActivity();
        $activity->ia_inq_id = $this->parent_rec->inq_id;
        $activity->ia_actm_id = 49;
        $activity->ia_dtim = air2_date();
        $activity->ia_desc = sprintf('org %s added by {USER}', $org->org_name);
        $this->parent_rec->InquiryActivity[] = $activity;

        return $iorg;
    }





    /**
     *
     *
     * @return unknown
     * @param unknown $iorg
     */
    protected function air_delete($iorg) {

        $org = $iorg->Organization;

        // log activity
        $activity = new InquiryActivity();
        $activity->ia_inq_id = $this->parent_rec->inq_id;
        $activity->ia_actm_id = 49;
        $activity->ia_dtim = air2_date();
        $activity->ia_desc = sprintf('org %s removed by {USER}', $org->org_name);
        $activity->save();

    }


    /**
     * Mark inquiry as stale
     *
     * @param InqOrg  $rec
     */
    protected function update_parent(InqOrg $rec) {
        // raw sql update rather than calling parent_rec->save()
        // because nested objects cascade
        $upd = 'update inquiry set inq_stale_flag=1 where inq_id = ?';
        AIR2_DBManager::get_master_connection()->exec($upd, array($rec->iorg_inq_id));
    }



}
