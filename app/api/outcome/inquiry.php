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
 * Outcome/Inquiry API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Outcome_Inquiry extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'delete');
    protected $CREATE_DATA = array('inq_uuid', 'iout_type', 'iout_notes');
    protected $UPDATE_DATA = array('iout_type', 'iout_notes');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'inq_ext_title asc';
    protected $sort_valids    = array('inq_cre_dtim', 'ispub', 'inq_publish_dtim',
        'inq_ext_title');

    // metadata
    protected $ident = 'inq_uuid';
    protected $fields = array(
        // flattened fields
        'inq_uuid',
        'inq_title',
        'inq_ext_title',
        'inq_publish_dtim',
        'inq_deadline_dtim',
        'inq_desc',
        'inq_type',
        'inq_status',
        'inq_expire_msg',
        'inq_expire_dtim',
        'inq_cre_dtim',
        'inq_upd_dtim',
        'inq_ending_para',
        'inq_rss_intro',
        'inq_intro_para',
        'inq_rss_status',
        'inq_loc_id',
        'inq_url',
        'sent_count',
        'recv_count',
        'ispub',
        // normal outcome fields
        'iout_status',
        'iout_type',
        'iout_notes',
        'iout_cre_dtim',
        'iout_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('InqOutcome io');
        $q->where('io.iout_out_id = ?', $this->parent_rec->out_id);
        $q->leftJoin('io.Inquiry i');
        $q->leftJoin('io.CreUser c');
        Inquiry::add_counts($q, 'i');
        $q->addSelect('(i.inq_publish_dtim is not null) as ispub');
        return $q;
    }


    /**
     * Flatten
     *
     * @param InqOutcome $record
     */
    protected function format_radix(InqOutcome $record) {
        foreach ($this->fields as $fld) {
            if (is_string($fld) && preg_match('/^inq/', $fld)) {
                $record->mapValue($fld, $record->Inquiry->$fld);
            }
        }
        return parent::format_radix($record);
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


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        $this->require_data($data, array('inq_uuid'));

        // validate
        $i = AIR2_Record::find('Inquiry', $data['inq_uuid']);
        if (!$i) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid inq_uuid');
        }
        foreach ($this->parent_rec->InqOutcome as $iout) {
            if ($iout->iout_inq_id == $i->inq_id) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Outcome already includes Inquiry');
            }
        }

        // create!
        $rec = new InqOutcome();
        $rec->iout_out_id = $this->parent_rec->out_id;
        $rec->iout_inq_id = $i->inq_id;
        $rec->mapValue('inq_uuid', $i->inq_uuid);
        return $rec;
    }


}
