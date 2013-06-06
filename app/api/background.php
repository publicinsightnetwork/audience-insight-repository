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
 * Background API
 *
 * Provides visibility into the job_queue table
 *
 * @author rcavis
 * @package default
 */
class AAPI_Background extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch');
    protected $QUERY_ARGS  = array('status', 'q');

    // default paging/sorting
    protected $query_args_default = array();
    protected $limit_default  = 20;
    protected $sort_default   = 'jq_cre_dtim desc';
    protected $sort_valids    = array('jq_cre_dtim', 'jq_start_dtim',
        'jq_complete_dtim', 'jq_status');

    // metadata
    protected $ident = 'jq_id';
    protected $fields = array(
        'jq_id',
        'jq_job',
        'jq_error_msg',
        'jq_cre_dtim',
        'jq_start_dtim',
        'jq_complete_dtim',
        'CreUser' => 'DEF::USERSTAMP',
        // fake fields
        'jq_status',
    );

    // status computation queries
    protected $status_queries = array(
        'Q' => "j.jq_start_dtim is null",
        'R' => "j.jq_start_dtim is not null and j.jq_complete_dtim is null",
        'C' => "j.jq_complete_dtim is not null and j.jq_error_msg is null",
        'E' => "j.jq_complete_dtim is not null and j.jq_error_msg is not null",
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('JobQueue j');
        $q->leftJoin('j.CreUser cu');
        $this->add_status($q);

        // since status isn't real, have to execute the actual queries
        if (isset($args['status'])) {
            $st = $args['status'];
            if (is_string($st) && strlen($st) && $st != '*') {
                $ins = str_split($st);
                $wherein = array();
                foreach ($ins as $code) {
                    if (isset($this->status_queries[$code])) {
                        $wherein[] = '('.$this->status_queries[$code].')';
                    }
                }
                $q->addWhere(implode(' or ', $wherein));
            }
        }

        // owner == cre_user_id
        if (isset($args['owner'])) {
            User::add_search_str($q, 'cu', $args['owner']);
        }

        // job search
        if (isset($args['q'])) {
            // also look at the owner
            $tmp = AIR2_Query::create();
            User::add_search_str($tmp, 'cu', $args['q']);
            $params = $tmp->getParams();
            $params = isset($params['where']) ? $params['where'] : array();
            $tmp = array_pop($tmp->getDqlPart('where'));

            // query job
            $params[] = '%'.$args['q'].'%';
            $q->addWhere("($tmp or j.jq_job like ?)", $params);
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
        $q->andWhere('j.jq_id = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create a "status" column based on job state
     *
     * @param Doctrine_Query $q
     */
    protected function add_status($q) {
        $sel = 'select case';
        foreach ($this->status_queries as $code => $query) {
            $sel .= " when $query then '$code'";
        }
        $sel .= " else 'U' end";
        $q->addSelect("($sel) as jq_status");
    }


}
