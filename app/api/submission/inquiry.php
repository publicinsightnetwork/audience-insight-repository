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
 * Submission/Inquiry API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Submission_Inquiry extends AIRAPI_Resource {

    // single resource
    protected static $REL_TYPE = self::ONE_TO_ONE;

    // API definitions
    protected $ALLOWED = array('fetch');

    // metadata
    protected $ident = 'inq_uuid';
    protected $fields = array(
        'DEF::INQUIRY',
        'SrcInquiry' => array('si_status', 'si_sent_by', 'si_cre_dtim'),
        'ProjectInquiry' => array(
            'pinq_status',
            'pinq_cre_dtim',
            'pinq_upd_dtim',
            'Project' => 'DEF::PROJECT',
        ),
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
        'sent_count',
        'recv_count',
    );


    /**
     * Fetch
     *
     * @param string $uuid
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid) {
        $q = Doctrine_Query::create()->from('Inquiry i');
        $q->andWhere('i.inq_id = ?', $this->parent_rec->srs_inq_id);

        // some more stuff
        $q->leftJoin('i.CreUser icu');
        $q->leftJoin('icu.UserOrg icuo WITH icuo.uo_home_flag = true');
        $q->leftJoin('icuo.Organization o');
        $q->leftJoin('i.ProjectInquiry pi');
        $q->leftJoin('pi.Project');
        Inquiry::add_counts($q, 'i');
        return $q->fetchOne();
    }


}