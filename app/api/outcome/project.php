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
 * Outcome/Project API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Outcome_Project extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'delete');
    protected $CREATE_DATA = array('prj_uuid', 'pout_type', 'pout_notes');
    protected $UPDATE_DATA = array('pout_type', 'pout_notes');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'prj_display_name asc';
    protected $sort_valids    = array('prj_display_name', 'prj_status', 'prj_cre_dtim');

    // metadata
    protected $ident = 'prj_uuid';
    protected $fields = array(
        // flattened fields
        'prj_uuid',
        'prj_name',
        'prj_display_name',
        'prj_desc',
        'prj_status',
        'prj_type',
        'ProjectOrg' => array('porg_status', 'Organization' => 'DEF::ORGANIZATION'),
        // normal outcome fields
        'pout_status',
        'pout_type',
        'pout_notes',
        'pout_cre_dtim',
        'pout_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
    );


    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('PrjOutcome po');
        $q->where('po.pout_out_id = ?', $this->parent_rec->out_id);
        $q->leftJoin('po.Project p');
        $q->leftJoin('po.CreUser c');
        $q->leftJoin('p.ProjectOrg porg');
        $q->leftJoin('porg.Organization o');
        return $q;
    }


    /**
     * Flatten
     *
     * @param PrjOutcome $record
     */
    protected function format_radix(PrjOutcome $record) {
        // flatten project
        foreach ($this->fields as $fld) {
            if (is_string($fld) && preg_match('/^prj/', $fld)) {
                $record->mapValue($fld, $record->Project->$fld);
            }
        }

        // project orgs
        $record->mapValue('ProjectOrg', $record->Project->ProjectOrg);
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
        $q->andWhere('p.prj_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * @param array $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        $this->require_data($data, array('prj_uuid'));

        // validate
        $p = AIR2_Record::find('Project', $data['prj_uuid']);
        if (!$p) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid prj_uuid');
        }
        foreach ($this->parent_rec->PrjOutcome as $pout) {
            if ($pout->pout_prj_id == $p->prj_id) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Outcome already includes Project');
            }
        }

        // create!
        $rec = new PrjOutcome();
        $rec->pout_out_id = $this->parent_rec->out_id;
        $rec->pout_prj_id = $p->prj_id;
        $rec->mapValue('prj_uuid', $p->prj_uuid);
        return $rec;
    }


}
