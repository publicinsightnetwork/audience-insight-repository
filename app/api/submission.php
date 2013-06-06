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
 * Submission API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Submission extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'update');
    protected $QUERY_ARGS  = array('src_uuid');

    // default paging/sorting
    protected $query_args_default = array();
    protected $sort_default   = 'srs_date desc';
    protected $sort_valids    = array('srs_date');
    protected $UPDATE_DATA = array('srs_public_flag');


    // metadata
    protected $ident = 'srs_uuid';
    protected $fields = array(
        'srs_uuid',
        'srs_date',
        'srs_uri',
        'srs_type',
        'srs_public_flag',
        'srs_delete_flag',
        'srs_translated_flag',
        'srs_export_flag',
        'srs_conf_level',
        'srs_cre_dtim',
        'srs_upd_dtim',
        'publish_flags',
        'CreUser' => array(
            'DEF::USERSTAMP',
            'UserOrg' => array(
                'uo_uuid',
                'uo_home_flag',
                'uo_user_title',
                'Organization' => array(
                    'org_uuid',
                    'org_name',
                    'org_display_name',
                    'org_html_color',
                ),
            ),
        ),

        'Inquiry' => array(
            'DEF::INQUIRY',
            'ProjectInquiry' => array('Project'),
            'InqOrg' => array(
                'iorg_status',
                'iorg_org_id',
            ),
            'CreUser' => array(
                'DEF::USERSTAMP',
                'UserOrg' => 'DEF::USERORG'
            )
        ),

        'Source' => 'DEF::SOURCE',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('SrcResponseSet a');
        $q->leftJoin('a.CreUser cu');
        $q->leftJoin('cu.UserOrg cuo WITH cuo.uo_home_flag = true');
        $q->leftJoin('cuo.Organization o');
        $q->leftJoin('a.Inquiry i');
        $q->leftJoin('a.Source s');

        // restrict to a source
        if (isset($args['src_uuid'])) {
            $q->addWhere('s.src_uuid = ?', $args['src_uuid']);
        }
        return $q;
    }


    /**
     * Fetch
     *
     * @param string $uuid
     * @param boolean $minimal (optional)
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid, $minimal=false) {
        if ($minimal) {
            $q = Doctrine_Query::create()->from('SrcResponseSet a');
        }
        else {
            $q = $this->air_query();

            $q->leftJoin('i.ProjectInquiry ipi');
            $q->leftJoin('i.InqOrg iio');
            $q->leftJoin('i.CreUser icu');
            $q->leftJoin('icu.UserOrg icuuo');
        }
        $q->addSelect(" '' as publish_flags");
        $q->andWhere('a.srs_uuid = ?', $uuid);

        $rec = $q->fetchOne();

        if ($rec) {
            $rec->publish_flags = $rec->get_publish_state();
        }

        return $rec;
    }

    /**
     * Update
     *
     * @param Doctrine_Record $rec
     * @param array $data
     */
    protected function air_update($rec, $data) {
        $rec->srs_upd_user = $this->user->user_id;
        air2_touch_stale_record('src_response_set', $rec->srs_id);
    }
}
