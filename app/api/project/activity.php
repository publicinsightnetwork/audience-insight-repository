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
 * Project/Activity API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Project_Activity extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'pa_dtim desc';
    protected $sort_valids    = array('pa_dtim');

    // metadata
    protected $ident = 'pa_id';
    protected $fields = array(
        'pa_id',
        'pa_actm_id',
        'pa_dtim',
        'pa_desc',
        'pa_notes',
        'pa_ref_type',
        'pa_cre_dtim',
        'pa_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
        'ActivityMaster' => array('actm_id', 'actm_name'),
        'Organization' => 'DEF::ORGANIZATION',
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

        $q = Doctrine_Query::create()->from('ProjectActivity pa');
        $q->where('pa.pa_prj_id = ?', $prj_id);
        $q->leftJoin('pa.ActivityMaster a');
        $q->leftJoin('pa.CreUser');
        ProjectActivity::joinRelated($q, 'pa');
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
        $q->andWhere('pa.pa_id = ?', $uuid);
        return $q->fetchOne();
    }


}
