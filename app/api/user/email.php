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
 * User/Email API
 *
 * @author rcavis
 * @package default
 */
class AAPI_User_Email extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'uem_primary_flag desc';
    protected $sort_valids    = array('uem_primary_flag', 'uem_address');

    // metadata
    protected $ident = 'uem_uuid';
    protected $fields = array(
        'uem_uuid',
        'uem_address',
        'uem_primary_flag',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $user_id = $this->parent_rec->user_id;

        $q = Doctrine_Query::create()->from('UserEmailAddress u');
        $q->where('u.uem_user_id = ?', $user_id);
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
        $q->andWhere('u.uem_uuid = ?', $uuid);
        return $q->fetchOne();
    }


}
