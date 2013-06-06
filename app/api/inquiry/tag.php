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
 * Inquiry/Tag API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Inquiry_Tag extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('tm_id', 'tm_name');

    // default paging/sorting
    protected $sort_default   = 'tag_upd_dtim desc';
    protected $sort_valids    = array('tag_cre_dtim', 'tag_upd_dtim');

    // metadata
    protected $ident = 'tag_tm_id';
    protected $fields = array(
        'tag_tm_id',
        'tm_id',
        'tm_type',
        'tm_name',
        'iptc_name',
        'tag_cre_dtim',
        'tag_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $inq_id = $this->parent_rec->inq_id;

        $q = Doctrine_Query::create()->from('TagInquiry t');
        $q->where('t.tag_xid = ?', $inq_id);
        $q->leftJoin('t.CreUser');
        $q->leftJoin('t.TagMaster m');
        $q->leftJoin('m.IptcMaster i');
        $q->addSelect('m.tm_id as tm_id');
        $q->addSelect('m.tm_type as tm_type');
        $q->addSelect('m.tm_name as tm_name');
        $q->addSelect('i.iptc_name as iptc_name');
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
        $q->andWhere('t.tag_tm_id = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        $name = isset($data['tm_name']) ? $data['tm_name'] : null;
        $tmid = isset($data['tm_id'])   ? $data['tm_id']   : null;
        if (!$name && !$tmid) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "Required data 'tm_name' or 'tm_id'");
        }

        // create tag
        $input = ($tmid) ? $tmid : $name;
        $use_id = ($tmid) ? true : false;
        $rec = Tag::create_tag('TagInquiry', $this->parent_rec->inq_id, $input, $use_id);
        if (!$rec) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "Invalid tm_id($tmid)");
        }
        if ($rec->exists()) {
            $rec->tag_upd_user = $this->user->user_id;
            $rec->tag_upd_dtim = air2_date();
        }
        return $rec;
    }


}
