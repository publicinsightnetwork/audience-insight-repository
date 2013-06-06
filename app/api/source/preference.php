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
 * Source/Fact API
 *
 * @author echristiansen
 * @package default
 */
class AAPI_Source_Preference extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('ptv_uuid');
    protected $UPDATE_DATA = array('ptv_uuid');

    // default paging/sorting
    protected $sort_default   = 'pt_name asc';
    protected $sort_valids    = array('pt_name');

    // metadata
    protected $ident = 'sp_uuid';
    protected $fields = array(
        'pt_uuid',
        'pt_name',
        'pt_identifier',
        'ptv_uuid',
        'sp_uuid',
        'sp_ptv_id',
        'sp_lock_flag',
        'sp_cre_dtim',
        'sp_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
        'PreferenceTypeValue' => array('ptv_id', 'ptv_value', 'ptv_uuid'),
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $src_id = $this->parent_rec->src_id;

        $q = Doctrine_Query::create()->from('SrcPreference s');
        $q->andWhere('s.sp_src_id = ?', $src_id);
        $q->leftJoin('s.CreUser cu');
        $q->leftJoin('s.UpdUser uu');
        $q->leftJoin('s.PreferenceTypeValue ptv');
        $q->leftJoin('ptv.PreferenceType pv');
        $q->addSelect('pv.pt_uuid as pt_uuid');
        $q->addSelect('pv.pt_name as pt_name');
        $q->addSelect('pv.pt_identifier as pt_identifier');

        return $q;
    }


    /**
     * Fetch
     *
     * @param string $uuid
     * @param boolean $minimal
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid, $minimal) {
        if ($minimal) {
            $src_id = $this->parent_rec->src_id;
            $q = Doctrine_Query::create()->from('SrcPreference s');
            $q->leftJoin('s.PreferenceTypeValue ptv');
            $q->leftJoin('ptv.PreferenceType pv');
            $q->andWhere('s.sp_src_id = ?', $src_id);
        }
        else {
            $q = $this->air_query();
        }
        $q->andWhere('s.sp_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array $data
     * @return SrcPreference
     */
    protected function air_create($data) {

        if (!isset($data['ptv_uuid'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "ptv_uuid required");
        }
        $ptv_uuid = $data['ptv_uuid'];
        $preference = AIR2_Record::find('PreferenceTypeValue', $ptv_uuid);

        if (!$preference) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid ptv_id '$ptv_uuid'");
        }

        $sp = new SrcPreference();
        $sp->sp_ptv_id = $preference->ptv_id;
        $sp->Source = $this->parent_rec;
        $sp->PreferenceTypeValue = $preference;
        $sp->mapValue('ptv_uuid', $preference->ptv_uuid);
        return $sp;
    }

    /**
     * Update
     *
     * @param SrcPreference $rec
     * @param array $data
     */

    protected function air_update($rec, $data) {
        if (!isset($data['ptv_uuid'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "ptv_uuid required");
        }
        $ptv_uuid = $data['ptv_uuid'];
        $preference = AIR2_Record::find('PreferenceTypeValue', $ptv_uuid);

        if (!$preference) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid ptv_id '$ptv_uuid'");
        }

        $rec->sp_ptv_id = $preference->ptv_id;

    }

}
