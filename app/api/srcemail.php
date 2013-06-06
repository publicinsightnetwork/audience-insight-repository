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
 * Source API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Srcemail extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'update');
    protected $QUERY_ARGS  = array('status');
    protected $UPDATE_DATA = array('sem_email', 'sem_status');

    // default paging/sorting
    protected $query_args_default = array('status' => 'B');
    protected $limit_default  = 30;
    protected $sort_default   = 'sem_upd_dtim desc';
    protected $sort_valids    = array('sem_cre_dtim', 'sem_upd_dtim',
        'sem_email', 'src_first_name', 'src_last_name', 'src_status');

    // metadata
    protected $ident = 'sem_uuid';
    protected $fields = array(
        'sem_uuid',
        'sem_primary_flag',
        'sem_context',
        'sem_email',
        'sem_effective_date',
        'sem_expire_date',
        'sem_status',
        'sem_cre_dtim',
        'sem_upd_dtim',
        'Source' => array(
            'DEF::SOURCE',
            'SrcOrg' => array(
                'so_uuid',
                'so_home_flag',
                'Organization' => 'DEF::ORGANIZATION',
            ),
        ),
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('SrcEmail e');

        // only WRITE-able sources (#4462)
        $q->innerJoin('e.Source s');
        $q->leftJoin('s.SrcOrg so WITH so.so_home_flag = true');
        $q->leftJoin('so.Organization o');
        Source::query_may_write($q, $this->user, 's');

        // status
        if (isset($args['status'])) {
            air2_query_in($q, $args['status'], 'e.sem_status');
        }
        return $q;
    }


    /**
     * Custom search/filter
     *
     * @param Doctrine_query $q
     * @param string $str
     * @param string $root_tbl (optional)
     * @param string $root_alias (optional)
     */
    protected function apply_search($q, $str, $root_tbl=null, $root_alias=null) {
        $emls = "e.sem_email like '%$str%'";
        $srcs = "s.src_first_name like '$str%' OR s.src_last_name like '$str%'";
        $orgs = "o.org_name like '$str%' OR o.org_display_name like '$str%'";
        $q->addWhere("(($emls) OR ($srcs) OR ($orgs))");
    }


    /**
     * Fetch
     *
     * @param string $uuid
     * @param boolean $minimal (optional)
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid, $minimal=false) {
        $q = $this->air_query();
        $q->andWhere('e.sem_uuid = ?', $uuid);
        return $q->fetchOne();
    }


}
