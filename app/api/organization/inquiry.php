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
 * Organization/Inquiry API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Organization_Inquiry extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'inq_cre_dtim desc';
    protected $sort_valids    = array('inq_cre_dtim');

    // metadata
    protected $ident = 'inq_uuid';
    protected $fields = array(
        'DEF::INQUIRY',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $org_id = $this->parent_rec->org_id;
        $prjs = "select porg_prj_id from project_org where porg_org_id = $org_id";
        $inqs = "select pinq_inq_id from project_inquiry where pinq_prj_id in ($prjs)";

        $q = Doctrine_Query::create()->from('Inquiry i');
        $q->where("i.inq_id in ($inqs)");
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
        $q->andWhere('i.inq_uuid = ?', $uuid);
        return $q->fetchOne();
    }


}
