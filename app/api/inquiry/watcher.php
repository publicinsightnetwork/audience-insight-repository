<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
/**************************************************************************
 *
 *   Copyright 2013 American Public Media Group
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
 * Inquiry/Watcher API
 *
 * @package default
 */
class AAPI_Inquiry_Watcher extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('User');

    // default paging/sorting
    protected $sort_default   = 'u.user_last_name asc';
    protected $sort_valids    = array('iu_cre_dtim', 'u.user_username', 'u.user_first_name', 'u.user_last_name');

    // metadata
    protected $ident = 'iu_id';
    protected $fields = array(
        'iu_id',
        'iu_status',
        'iu_cre_dtim',
        'iu_upd_dtim',
        'User'    => 'DEF::USERSTAMP',
        'CreUser' => 'DEF::USERSTAMP',
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

        $q = Doctrine_Query::create()->from('InquiryWatcher iw');
        $q->addWhere('iw.iu_inq_id = ?', $inq_id);
        $q->addWhere('iw.iu_type = ?', InquiryUser::$TYPE_WATCHER);
        $q->leftJoin('iw.User u');
        $q->leftJoin('iw.CreUser cu');
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
        $q->addWhere('iw.iu_id = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array   $data
     * @return InquiryWatcher
     */
    protected function air_create($data) {
        if (!isset($data['User'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "User");
        }
        $user = null;
        if ($data['User']) {
            $user = AIR2_Record::find('User', $data['User']['user_uuid']);
            if (!$user) {
                $u = $data['User']['user_uuid'];
                throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid user_uuid '$u'");
            }
        }

        $iw = new InquiryWatcher();
        $iw->iu_inq_id = $this->parent_rec->inq_id;
        $iw->iu_user_id = $user->user_id;

        // log activity
        $activity = new InquiryActivity();
        $activity->ia_inq_id = $this->parent_rec->inq_id;
        $activity->ia_actm_id = 49;
        $activity->ia_dtim = air2_date();
        $activity->ia_desc = sprintf('watcher %s added by {USER}', $user->user_username);
        $this->parent_rec->InquiryActivity[] = $activity;

        return $iw;
    }





    /**
     *
     *
     * @return unknown
     * @param InquiryWatcher $iw
     */
    protected function air_delete($iw) {

        $user = $iw->User;

        // log activity
        $activity = new InquiryActivity();
        $activity->ia_inq_id = $this->parent_rec->inq_id;
        $activity->ia_actm_id = 49;
        $activity->ia_dtim = air2_date();
        $activity->ia_desc = sprintf('watcher %s removed by {USER}', $user->user_username);
        $this->parent_rec->InquiryActivity[] = $activity;

    }


    /**
     * Mark inquiry as stale
     *
     * @param InquiryWatcher $rec
     */
    protected function update_parent(InquiryWatcher $rec) {
        $this->parent_rec->inq_stale_flag = 1;
        parent::update_parent($rec);
    }



}
