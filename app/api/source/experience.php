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
 * Source/Experience API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Source_Experience extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('sv_seq', 'sv_origin', 'sv_conf_level',
        'sv_lat', 'sv_long', 'sv_start_date', 'sv_end_date', 'sv_value', 'sv_basis');
    protected $UPDATE_DATA = array('sv_status', 'sv_conf_level', 'sv_lat',
        'sv_long', 'sv_start_date', 'sv_end_date', 'sv_value', 'sv_basis');

    // default paging/sorting
    protected $sort_default   = 'sv_seq asc';
    protected $sort_valids    = array('sv_seq', 'sv_cre_dtim');

    // metadata
    protected $ident = 'sv_uuid';
    protected $fields = array(
        'sv_uuid',
        'sv_seq',
        'sv_type',
        'sv_status',
        'sv_origin',
        'sv_conf_level',
        'sv_lock_flag',
        'sv_lat',
        'sv_long',
        'sv_start_date',
        'sv_end_date',
        'sv_value',
        'sv_basis',
        'sv_cre_dtim',
        'sv_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $src_id = $this->parent_rec->src_id;

        $q = Doctrine_Query::create()->from('SrcVita v');
        $q->andWhere('v.sv_src_id = ?', $src_id);
        $q->andWhere('v.sv_type = ?', SrcVita::$TYPE_EXPERIENCE);
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
        $q->andWhere('v.sv_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        $rec = new SrcVita();
        $rec->Source = $this->parent_rec;
        $rec->sv_type = SrcVita::$TYPE_EXPERIENCE;
        return $rec;
    }

    /**
     * Update
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_update($rec, $data) {
        if($data['sv_end_date'] == ''){
            $rec['sv_end_date'] = null;
        }
        return $rec;
    }

}
