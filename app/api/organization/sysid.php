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
 * Organization/SysId API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Organization_SysId extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('create', 'update', 'query', 'fetch', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('osid_type', 'osid_xuuid');
    protected $UPDATE_DATA = array('osid_xuuid');

    // default paging/sorting
    protected $sort_default   = 'osid_type desc';
    protected $sort_valids    = array('osid_type', 'osid_cre_dtim');

    // metadata
    protected $ident = 'osid_id';
    protected $fields = array(
        'osid_id',
        'osid_type',
        'osid_xuuid',
        'osid_cre_dtim',
        'osid_upd_dtim',
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
        $org_id = $this->parent_rec->org_id;

        $q = Doctrine_Query::create()->from('OrgSysId os');
        $q->where('os.osid_org_id = ?', $org_id);
        $q->leftJoin('os.CreUser cu');
        $q->leftJoin('os.UpdUser uu');
        return $q;
    }


    /**
     * Create
     *
     * @param array $data
     * @return UserOrg $rec
     */
    protected function air_create($data) {
        $this->require_data($data, array('osid_type', 'osid_xuuid'));
        if (!in_array($data['osid_type'], array('E', 'M'))) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "invalid osid_type");
        }

        // unique osid_type per organization
        $conn = AIR2_DBManager::get_master_connection();
        $q = 'select count(*) from org_sys_id where osid_org_id = ? and osid_type = ?';
        $p = array($this->parent_rec->org_id, $data['osid_type']);
        $n = $conn->fetchOne($q, $p, 0);
        if ($n > 0) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "osid_type already in use");
        }

        $os = new OrgSysId();
        $os->osid_org_id = $this->parent_rec->org_id;
        return $os;
    }


    /**
     * Fetch
     *
     * @param string $uuid
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid) {
        $q = $this->air_query();
        $q->andWhere('os.osid_id = ?', $uuid);
        return $q->fetchOne();
    }


}
