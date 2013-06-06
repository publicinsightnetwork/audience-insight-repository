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
 * @author rcavis
 * @package default
 */
class AAPI_Source_Fact extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('fact_uuid', 'sf_fv_id', 'sf_src_fv_id',
        'sf_src_value');
    protected $UPDATE_DATA = array('sf_fv_id', 'sf_src_fv_id', 'sf_src_value');

    // default paging/sorting
    protected $sort_default   = 'sf_cre_dtim asc';
    protected $sort_valids    = array('sf_cre_dtim', 'sf_upd_dtim',
        'fact_id', 'fact_name');

    // metadata
    protected $ident = 'fact_uuid';
    protected $fields = array(
        'fact_uuid',
        'fact_name',
        'fact_identifier',
        'sf_src_value',
        'sf_fv_id',
        'sf_src_fv_id',
        'sf_lock_flag',
        'sf_public_flag',
        'sf_cre_dtim',
        'sf_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
        'Fact' => array('fact_uuid', 'fact_name', 'fact_identifier', 'fact_fv_type'),
        'AnalystFV' => 'DEF::FACTVALUE',
        'SourceFV' => 'DEF::FACTVALUE',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $src_id = $this->parent_rec->src_id;

        $q = Doctrine_Query::create()->from('SrcFact s');
        $q->andWhere('s.sf_src_id = ?', $src_id);
        $q->leftJoin('s.CreUser cu');
        $q->leftJoin('s.UpdUser uu');
        $q->leftJoin('s.Fact f');
        $q->leftJoin('s.AnalystFV afv');
        $q->leftJoin('s.SourceFV sfv');
        $q->addSelect('f.fact_uuid as fact_uuid');
        $q->addSelect('f.fact_name as fact_name');
        $q->addSelect('f.fact_identifier as fact_identifier');
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
            $q = Doctrine_Query::create()->from('SrcFact s');
            $q->andWhere('s.sf_src_id = ?', $src_id);
            $q->leftJoin('s.Fact f');
        }
        else {
            $q = $this->air_query();
        }
        $q->andWhere('f.fact_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array $data
     * @return SrcFact
     */
    protected function air_create($data) {
        if (!isset($data['fact_uuid'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "fact_uuid required");
        }
        $fact = AIR2_Record::find('Fact', $data['fact_uuid']);
        if (!$fact) {
            $u = $data['fact_uuid'];
            throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid fact_uuid '$u'");
        }

        $sf = new SrcFact();
        $sf->Source = $this->parent_rec;
        $sf->Fact = $fact;
        $sf->mapValue('fact_uuid', $fact->fact_uuid);
        return $sf;
    }


}
