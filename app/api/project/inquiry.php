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
 * Project/Inquiry API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Project_Inquiry extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('inq_uuid');

    // default paging/sorting
    protected $sort_default   = 'inq_cre_dtim desc';
    protected $sort_valids    = array('inq_cre_dtim');

    // metadata
    protected $ident = 'inq_uuid';
    protected $fields = array(
        'inq_uuid',
        'pinq_status',
        'pinq_cre_dtim',
        'pinq_upd_dtim',
        'Inquiry' => array(
            'DEF::INQUIRY',
            'inq_loc_id',
            'inq_expire_msg',
            'inq_expire_dtim',
            'inq_rss_status',
            'inq_rss_intro',
            'inq_intro_para',
            'inq_ending_para',
            'CreUser' => 'DEF::USERSTAMP',
        ),
        'sent_count',
        'recv_count',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $prj_id = $this->parent_rec->prj_id;

        $q = Doctrine_Query::create()->from('ProjectInquiry pi');
        $q->where('pi.pinq_prj_id = ?', $prj_id);

        $q->leftJoin('pi.Inquiry i');
        $q->leftJoin('i.CreUser u');
        $q->leftJoin('u.UserOrg uo WITH uo.uo_home_flag = true');
        $q->leftJoin('uo.Organization o');
        $q->addSelect('i.inq_uuid as inq_uuid');
        Inquiry::add_counts($q, 'i');

        // prevent record-wise limit (fixes limit subquery)
        $q->getRoot()->setAttribute(Doctrine_Core::ATTR_QUERY_LIMIT, Doctrine_Core::LIMIT_ROWS);
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
        $q->andWhere('i.inq_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array $data
     */
    protected function air_create($data) {
        if (!isset($data['inq_uuid'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "inq_uuid required");
        }
        $inq = AIR2_Record::find('Inquiry', $data['inq_uuid']);
        if (!$inq) {
            $u = $data['inq_uuid'];
            throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid inq_uuid '$u'");
        }
        if (!$inq->user_may_write($this->user)) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid Inquiry authz");
        }

        $pinq = new ProjectInquiry();
        $pinq->pinq_prj_id = $this->parent_rec->prj_id;
        $pinq->Inquiry = $inq;
        $pinq->mapValue('inq_uuid', $pinq->Inquiry->inq_uuid);
        return $pinq;
    }


}
