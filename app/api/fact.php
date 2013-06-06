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
 * Fact API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Fact extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch');
    protected $QUERY_ARGS  = array('status', 'type');

    // default paging/sorting
    protected $query_args_default = array('status' => 'A');
    protected $sort_default   = 'fact_name asc';
    protected $sort_valids    = array('fact_name', 'fact_identifier');

    // metadata
    protected $ident = 'fact_uuid';
    protected $fields = array(
        'fact_id',
        'fact_uuid',
        'fact_name',
        'fact_identifier',
        'fact_status',
        'fact_fv_type',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('Fact f');
        if (isset($args['status'])) {
            air2_query_in($q, $args['status'], 'f.fact_status');
        }
        if (isset($args['type'])) {
            air2_query_in($q, $args['type'], 'f.fact_fv_type');
        }
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
        $q->andWhere('f.fact_uuid = ?', $uuid);
        return $q->fetchOne();
    }


}
