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
 * Tag API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Tag extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $limit_default  = 10;
    protected $offset_default = 0;
    protected $sort_default   = 'usage desc';
    protected $sort_valids    = array('usage', 'tm_name', 'tm_cre_dtim');

    // metadata
    protected $ident = 'tm_id';
    protected $fields = array(
        'tm_id',
        'tm_type',
        'tm_name',
        'tm_cre_dtim',
        'tm_upd_dtim',
        'IptcMaster' => array('iptc_concept_code', 'iptc_name'),
        'usage',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('TagMaster t');
        $q->leftJoin('t.IptcMaster i');

        // add usage
        $usage = 'select count(*) from tag where tag_tm_id = t.tm_id';
        $q->addSelect("($usage) as usage");
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
        $q->where('t.tm_id = ?', $uuid);
        return $q->fetchOne();
    }


}
