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
 * User/Signature API
 *
 * @author rcavis
 * @package default
 */
class AAPI_User_Signature extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('usig_text', 'usig_status');
    protected $UPDATE_DATA = array('usig_text', 'usig_status');

    // default paging/sorting
    protected $sort_default   = 'usig_upd_dtim desc';
    protected $sort_valids    = array('usig_cre_dtim', 'usig_upd_dtim');

    // metadata
    protected $ident = 'usig_uuid';
    protected $fields = array(
        'usig_uuid',
        'usig_text',
        'usig_status',
        'usig_cre_dtim',
        'usig_upd_dtim',
        'usage_count',
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
        $user_id = $this->parent_rec->user_id;
        $q = Doctrine_Query::create()->from('UserSignature s');
        $q->andWhere('s.usig_user_id = ?', $user_id);
        $q->leftJoin('s.CreUser cu');
        $q->leftJoin('s.UpdUser uu');

        // include the number of emails using this signature
        $q->addSelect('(select count(*) from email where email_usig_id = s.usig_id) as usage_count');

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
        $q->andWhere('s.usig_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record
     */
    protected function air_create($data) {
        $rec = new UserSignature();
        $rec->User = $this->parent_rec;
        return $rec;
    }


}
