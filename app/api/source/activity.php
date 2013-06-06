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
 * Source/Activity API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Source_Activity extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'sact_dtim asc';
    protected $sort_valids    = array('sact_dtim');

    // metadata
    protected $ident = 'sact_id';
    protected $fields = array(
        'sact_id',
        'sact_dtim',
        'sact_desc',
        'sact_notes',
        'sact_ref_type',
        'sact_cre_dtim',
        'sact_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
        'ActivityMaster' => array('actm_name', 'actm_type', 'actm_table_type'),
        'Project' => 'DEF::PROJECT',
        // related by xid
        'SrcResponseSet' => array('srs_uuid', 'srs_date', 'srs_type'),
        'Tank' => 'DEF::TANK',
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
        $src_id = $this->parent_rec->src_id;

        $q = Doctrine_Query::create()->from('SrcActivity a');
        $q->andWhere('a.sact_src_id = ?', $src_id);
        $q->leftJoin('a.CreUser cu');
        $q->leftJoin('a.UpdUser uu');
        $q->leftJoin('a.ActivityMaster am');
        $q->leftJoin('a.Project p');
        SrcActivity::joinRelated($q, 'a');
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
        $q->andWhere('a.sact_id = ?', $uuid);
        return $q->fetchOne();
    }


}
