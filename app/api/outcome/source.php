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
 * Outcome/Source API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Outcome_Source extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update', 'delete');
    protected $CREATE_DATA = array('src_uuid', 'sout_type', 'sout_notes');
    protected $UPDATE_DATA = array('sout_type', 'sout_notes');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'sem_email asc';
    protected $sort_valids    = array('src_first_name', 'src_last_name',
        'sem_email', 'sout_cre_dtim');

    // metadata
    protected $ident = 'src_uuid';
    protected $fields = array(
        // flattened fields
        'src_uuid',
        'src_username',
        'src_first_name',
        'src_last_name',
        'src_middle_initial',
        'src_pre_name',
        'src_post_name',
        'src_status',
        'src_has_acct',
        'src_channel',
        'SrcEmail' => 'DEF::SRCEMAIL',
        'SrcPhoneNumber' => 'DEF::SRCPHONE',
        'SrcMailAddress' => 'DEF::SRCMAIL',
        'SrcOrg' => array(
            'so_uuid',
            'so_home_flag',
            'Organization' => 'DEF::ORGANIZATION',
        ),
        // normal outcome fields
        'sout_status',
        'sout_type',
        'sout_notes',
        'sout_cre_dtim',
        'sout_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('SrcOutcome so');
        $q->where('so.sout_out_id = ?', $this->parent_rec->out_id);
        $q->leftJoin('so.Source s');
        $q->leftJoin('so.CreUser c');
        $q->leftJoin('s.SrcEmail e WITH e.sem_primary_flag = true');
        $q->leftJoin('s.SrcPhoneNumber p');
        $q->leftJoin('s.SrcMailAddress m WITH m.smadd_primary_flag = true');
        $q->leftJoin('s.SrcOrg sorg WITH sorg.so_home_flag = true');
        $q->leftJoin('sorg.Organization o');
        return $q;
    }


    /**
     * Flatten
     *
     * @param SrcOutcome $record
     */
    protected function format_radix(SrcOutcome $record) {
        foreach ($this->fields as $fld) {
            if (is_string($fld) && preg_match('/^src/', $fld)) {
                $record->mapValue($fld, $record->Source->$fld);
            }
        }
        $record->mapValue('SrcEmail', $record->Source->SrcEmail);
        $record->mapValue('SrcPhoneNumber', $record->Source->SrcPhoneNumber);
        $record->mapValue('SrcMailAddress', $record->Source->SrcMailAddress);
        $record->mapValue('SrcOrg', $record->Source->SrcOrg);
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
        $q->andWhere('s.src_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        $this->require_data($data, array('src_uuid'));

        // validate
        $s = AIR2_Record::find('Source', $data['src_uuid']);
        if (!$s) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid src_uuid');
        }
        foreach ($this->parent_rec->SrcOutcome as $sout) {
            if ($sout->sout_src_id == $s->src_id) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Outcome already includes Source');
            }
        }

        // create!
        $rec = new SrcOutcome();
        $rec->sout_out_id = $this->parent_rec->out_id;
        $rec->sout_src_id = $s->src_id;
        $rec->mapValue('src_uuid', $s->src_uuid);
        return $rec;
    }


}
