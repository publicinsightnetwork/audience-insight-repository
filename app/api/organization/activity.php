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
 * Organization/Activity API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Organization_Activity extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query');
    protected $QUERY_ARGS  = array();

    // metadata
    protected $ident = 'id';
    protected $fields = array(
        'id',
        'dtim',
        'type',
        'UserOrg' => array(
            'uo_ar_id',
            'uo_uuid',
            'uo_user_title',
            'uo_status',
            'uo_notify_flag',
            'uo_home_flag',
            'uo_cre_dtim',
            'uo_upd_dtim',
            'UpdUser' => 'DEF::USERSTAMP',
            'User' => 'DEF::USERSTAMP',
        ),
        'Organization' => array(
            'DEF::ORGANIZATION',
            'CreUser' => 'DEF::USERSTAMP',
            'UpdUser' => 'DEF::USERSTAMP',
        ),
        'ProjectOrg' => array(
            'porg_status',
            'porg_cre_dtim',
            'porg_upd_dtim',
            'CreUser' => 'DEF::USERSTAMP',
            'UpdUser' => 'DEF::USERSTAMP',
            'Project' => 'DEF::PROJECT',
        ),
    );

    /* configuration for org activity */
    protected $my_limit;
    protected $my_offset;
    protected $actv_config = array(
        // user added (TODO: removed)
        'U' => array(
            'model' => 'UserOrg',
            'join'  => array('UpdUser', 'User'),
            'id'    => 'uo_id',
            'dtim'  => 'uo_upd_dtim',
            'org'   => 'uo_org_id',
        ),
        // org created
        'C' => array(
            'model' => 'Organization',
            'join'  => array('CreUser'),
            'id'    => 'org_id',
            'dtim'  => 'org_cre_dtim',
            'org'   => 'org_id',
        ),
        // org updated
        'O' => array(
            'model' => 'Organization',
            'join'  => array('UpdUser'),
            'id'    => 'org_id',
            'dtim'  => 'org_upd_dtim',
            'org'   => 'org_id',
        ),
        // added to project
        //TODO: too incomplete to use... try ProjectOrg instead
        //'P' => array(
        //    'model' => 'ProjectActivity',
        //    'id'    => 'pa_id',
        //    'dtim'  => 'pa_dtim',
        //    'org'   => 'pa_xid',
        //    'where' => "pa_actm_id = 35 && pa_ref_type = 'O'",
        //),
        'P' => array(
            'model' => 'ProjectOrg',
            'join'  => array('CreUser', 'Project'),
            'id'    => 'porg_prj_id',
            'dtim'  => 'porg_cre_dtim',
            'org'   => 'porg_org_id',
        ),
    );


    /**
     * Override to allow returning raw strings
     *
     * @param string  $method
     * @param mixed   $return (reference)
     */
    protected function sanity($method, &$return) {
        if (!is_string($return)) {
            parent::sanity($method, $return);
        }
    }


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function rec_query($args=array()) {
        $org_id = $this->parent_rec->org_id;
        $qry = array();
        foreach ($this->actv_config as $code => $def) {
            $tbl = Doctrine::getTable($def['model'])->getTableName();
            $id = $def['id'];
            $dtim = $def['dtim'];
            $org = $def['org'];
            $where = isset($def['where']) ? $def['where'].' and ' : '';
            $qry[] = "(select '$code' as type, $dtim as dtim, $id as id from ".
                "$tbl where $where $org = $org_id)";
        }
        $qry = implode(' union ', $qry);
        return $qry;
    }


    /**
     * Get total from DB
     *
     * @param string $qry
     * @return int $total
     */
    protected function rec_query_total($qry) {
        $conn = AIR2_DBManager::get_connection();
        return $conn->fetchOne("select count(*) from ($qry) a", array(), 0);
    }


    /**
     * Record limit and offset, to be applied later
     *
     * @param string $qry
     * @param int $limit
     * @param int $offset
     */
    protected function rec_query_page($qry, $limit, $offset) {
        $this->my_limit = $limit;
        $this->my_offset = $offset;
    }


    /**
     * Execute query and format results
     *
     * @param string $qry
     * @return array $radix
     */
    protected function format_query_radix($qry) {
        $org_id = $this->parent_rec->org_id;
        $conn = AIR2_DBManager::get_connection();
        $limit = $this->my_limit;
        $offset = $this->my_offset;
        $all = $conn->fetchAll("$qry order by dtim desc limit $limit offset $offset");

        // get PK id's by type
        $ids_by_type = array();
        foreach ($all as $row) {
            $type = $row['type'];
            if (!isset($ids_by_type[$type])) {
                $ids_by_type[$type] = array();
            }
            $ids_by_type[$type][] = $row['id'];
        }

        // fetch all the types
        $fetched_in_order = array_fill(0, count($all), null);
        foreach ($ids_by_type as $type => $ids) {
            $model = $this->actv_config[$type]['model'];
            $idcol = $this->actv_config[$type]['id'];
            $q = AIR2_Query::create()->from("$model a");
            $q->whereIn("a.$idcol", $ids);
            if (isset($this->actv_config[$type]['join'])) {
                foreach ($this->actv_config[$type]['join'] as $join) {
                    $q->leftJoin("a.$join");
                }
            }
            if ($idcol == 'porg_prj_id') {
                $q->addWhere('a.porg_org_id = ?', $org_id);
            }
            $rs = $q->fetchArray();

            // put them back in the right order
            foreach ($rs as $object) {
                $my_id = $object[$idcol];
                foreach ($all as $idx => $row) {
                    if ($row['type'] == $type && $row['id'] == $my_id) {
                        $fetched_in_order[$idx] = array(
                            'type' => $type,
                            'dtim' => $row['dtim'],
                            'id'   => $type.$my_id,
                            $model => $object,
                        );
                        break;
                    }
                }
            }
        }

        // clean data
        foreach ($fetched_in_order as &$row) {
            $row = $this->_clean($row, $this->_fields);
        }
        return $fetched_in_order;
    }


}
