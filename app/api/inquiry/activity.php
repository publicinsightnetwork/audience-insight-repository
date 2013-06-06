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
 * Inquiry/Activity API
 *
 * @package default
 */
class AAPI_Inquiry_Activity extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'ia_dtim desc';
    protected $sort_valids    = array('ia_dtim');

    // metadata
    protected $ident = 'ia_id';
    protected $fields = array(
        'ia_id',
        'ia_actm_id',
        'ia_dtim',
        'ia_desc',
        'ia_notes',
        'ia_cre_dtim',
        'ia_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
        'ActivityMaster' => array('actm_id', 'actm_name'),
    );


    /**
     * Query
     *
     * @param array   $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $inq_id = $this->parent_rec->inq_id;

        $q = Doctrine_Query::create()->from('InquiryActivity ia');
        $q->where('ia.ia_inq_id = ?', $inq_id);
        $q->leftJoin('ia.ActivityMaster a');
        $q->leftJoin('ia.CreUser');
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
        $q->andWhere('ia.ia_id = ?', $uuid);
        return $q->fetchOne();
    }


}
