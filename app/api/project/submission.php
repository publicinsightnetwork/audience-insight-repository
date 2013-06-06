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
 * Project/Submission API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Project_Submission extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'srs_date desc';
    protected $sort_valids    = array('srs_date');

    // metadata
    protected $ident = 'srs_uuid';
    protected $fields = array(
        'srs_uuid',
        'srs_date',
        'srs_uri',
        'srs_xuuid',
        'srs_type',
        'srs_public_flag',
        'srs_delete_flag',
        'srs_translated_flag',
        'srs_export_flag',
        'srs_loc_id',
        'srs_conf_level',
        'srs_cre_dtim',
        'srs_upd_dtim',
        'SrcResponse' => array('sr_uuid','sr_orig_value'),
        'Source' => 'DEF::SOURCE',
        'Inquiry' => 'DEF::INQUIRY',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $prj_id = $this->parent_rec->prj_id;
        $inq_ids = "select pinq_inq_id from project_inquiry where pinq_prj_id = $prj_id";

        $q = Doctrine_Query::create()->from('SrcResponseSet s');
        $q->where("s.srs_inq_id in ($inq_ids)");
        $q->leftJoin('s.SrcResponse r');
        $q->leftJoin('s.Source');
        $q->leftJoin('s.Inquiry i');
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
        $q->andWhere('s.srs_uuid = ?', $uuid);
        return $q->fetchOne();
    }


}
