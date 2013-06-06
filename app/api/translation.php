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
 * Translation API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Translation extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'update', 'create', 'delete');
    protected $QUERY_ARGS  = array('type', 'code');
    protected $CREATE_DATA = array('xm_fact_id', 'xm_xlate_from', 'xm_xlate_to_fv_id');
    protected $UPDATE_DATA = array('xm_xlate_from', 'xm_xlate_to_fv_id');

    // default paging/sorting
    protected $query_args_default = array('status' => 'B');
    protected $limit_default  = 30;
    protected $sort_default   = 'xm_xlate_from asc';
    protected $sort_valids    = array('xm_xlate_from', 'fv_value', 'xm_cre_dtim');

    // metadata
    protected $ident = 'xm_id';
    protected $fields = array(
        'xm_id',
        'xm_fact_id',
        'xm_xlate_from',
        'xm_xlate_to_fv_id',
        'xm_cre_dtim',
        'Fact' => array(
            'fact_id',
            'fact_uuid',
            'fact_name',
            'fact_identifier',
            'fact_fv_type',
        ),
        'FactValue' => array(
            'fv_id',
            'fv_seq',
            'fv_value',
        ),
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('TranslationMap t');
        $q->leftJoin('t.Fact f');
        $q->leftJoin('t.FactValue fv');

        // status
        if (isset($args['type']) && strlen($args['type'])) {
            $q->addWhere('f.fact_identifier = ?', $args['type']);
        }
        if (isset($args['code']) && strlen($args['code'])) {
            $q->addWhere('fv.fv_id = ?', $args['code']);
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
            $q = Doctrine_Query::create()->from('TranslationMap t');
        }
        else {
            $q = $this->air_query();
        }
        $q->andWhere('t.xm_id = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array $data
     */
    protected function air_create($data) {
        $rec = new TranslationMap();
        $this->require_data($data, array('xm_fact_id', 'xm_xlate_from', 'xm_xlate_to_fv_id'));
        $rec->xm_fact_id = $data['xm_fact_id'];
        $rec->xm_xlate_from = $data['xm_xlate_from'];
        $rec->xm_xlate_to_fv_id = $data['xm_xlate_to_fv_id'];
        $rec->xm_cre_dtim = air2_date();

        // verify uniqueness
        $this->check_translation($rec);
        return $rec;
    }


    /**
     * Update
     *
     * @param Doctrine_Record $rec
     * @param array $data
     */
    protected function air_update($rec, $data) {
        if (isset($data['xm_xlate_from'])) {
            $rec->xm_xlate_from = $data['xm_xlate_from'];
        }
        if (isset($data['xm_xlate_to_fv_id'])) {
            $rec->xm_xlate_to_fv_id = $data['xm_xlate_to_fv_id'];
        }

        // verify uniqueness
        $this->check_translation($rec);
    }


    /**
     * Make sure a record has unique from/to translation
     *
     * @param TranslationMap $rec
     */
    private function check_translation($rec) {
        $conn = AIR2_DBManager::get_master_connection();

        // build query
        $w = "xm_fact_id= ? and xm_xlate_from = ?";
        $q = "select count(*) from translation_map where $w";
        $params = array($rec->xm_fact_id, $rec->xm_xlate_from);
        if ($rec->xm_id) {
            $q .= " and xm_id != ?";
            $params[] = $rec->xm_id;
        }
        $n = $conn->fetchOne($q, $params, 0);
        if ($n > 0) {
            $s = "fact_id(".$rec->xm_fact_id.") - text(".$rec->xm_xlate_from.")";
            throw new Rframe_Exception("Non unique translation - $s");
        }
    }


}
