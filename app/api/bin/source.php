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
 * Bin/Source API
 *
 * The sources in a bin.  For a source to qualify as "in a bin", it MUST have
 * a bin_source record.  A bin_src_response_set alone just doesn't cut it.
 * On the other hand, authz for viewing bin_sources is calculated from both
 * the source and any submissions in that bin.  So it's possible that a source
 * would show up under this resource, to which you don't really have access;
 * you only have access to the submission.
 *
 * @author rcavis
 * @package default
 */
class AAPI_Bin_Source extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'update', 'create', 'delete');
    protected $QUERY_ARGS  = array();
    protected $CREATE_DATA = array('src_uuid');
    protected $UPDATE_DATA = array('bsrc_notes');

    // default paging/sorting
    protected $query_args_default = array();
    protected $sort_default       = 'src_first_name asc';
    protected $sort_valids        = array('src_first_name', 'src_last_name',
        'primary_email', 'primary_addr_city', 'added_dtim');

    // metadata
    protected $ident = 'src_uuid';
    protected $fields = array(
        // actually, this is the only real field here
        'bsrc_notes',
        // flattened stuff
        'src_uuid',
        'src_username',
        'src_first_name',
        'src_last_name',
        'src_middle_initial',
        'src_status',
        'src_cre_dtim',
        'src_upd_dtim',
        'primary_email',
        'primary_phone',
        'primary_addr_city',
        'primary_addr_state',
        'primary_addr_zip',
        'primary_org_uuid',
        'primary_org_name',
        'primary_org_display_name',
        'primary_org_html_color',
        // aggregates
        'subm_count',
    );


    /**
     * RESTful Create
     *
     * @param  array     $data
     * @return BinSource $rec
     */
    protected function air_create($data) {
        $this->require_data($data, array('src_uuid'));
        $src = AIR2_Record::find('Source', $data['src_uuid']);
        if (!$src) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid Source specified!');
        }

        $b = new BinSource();
        $b->Bin = $this->parent_rec;
        $b->Source = $src;
        $b->mapValue('src_uuid', $src->src_uuid);
        return $b;
    }


    /**
     * Query
     *
     * @param  array          $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('BinSource bs');
        $q->addWhere('bs.bsrc_bin_id = ?', $this->parent_rec->bin_id);

        // whole slew of joins
        $q->leftJoin('bs.Source s');
        $q->leftJoin('s.SrcEmail e WITH e.sem_primary_flag = true');
        $q->leftJoin('s.SrcPhoneNumber p WITH p.sph_primary_flag = true');
        $q->leftJoin('s.SrcMailAddress m WITH m.smadd_primary_flag = true');
        $q->leftJoin('s.SrcOrg so WITH so.so_home_flag = true');
        $q->leftJoin('so.Organization o');

        // flatten
        $q->addSelect('s.src_uuid as src_uuid');
        $q->addSelect('s.src_username as src_username');
        $q->addSelect('s.src_first_name as src_first_name');
        $q->addSelect('s.src_last_name as src_last_name');
        $q->addSelect('s.src_middle_initial as src_middle_initial');
        $q->addSelect('s.src_status as src_status');
        $q->addSelect('s.src_cre_dtim as src_cre_dtim');
        $q->addSelect('s.src_upd_dtim as src_upd_dtim');
        $q->addSelect('e.sem_email as primary_email');
        $q->addSelect('p.sph_number as primary_phone');
        $q->addSelect('m.smadd_city as primary_addr_city');
        $q->addSelect('m.smadd_state as primary_addr_state');
        $q->addSelect('m.smadd_zip as primary_addr_zip');
        $q->addSelect('o.org_uuid as primary_org_uuid');
        $q->addSelect('o.org_name as primary_org_name');
        $q->addSelect('o.org_display_name as primary_org_display_name');
        $q->addSelect('o.org_html_color as primary_org_html_color');

        // aggregates
        $bid = $this->parent_rec->bin_id;
        $srs = "select count(*) from bin_src_response_set where bsrs_bin_id=$bid "
             . "and bsrs_src_id=bs.bsrc_src_id";
        $q->addSelect("($srs) as subm_count");

        return $q;
    }


    /**
     * Fetch
     *
     * @param  string    $uuid
     * @return BinSource $rec
     */
    protected function air_fetch($uuid, $minimal=false) {
        if ($minimal) {
            $q = Doctrine_Query::create()->from('BinSource bs');
            $q->addWhere('bs.bsrc_bin_id = ?', $this->parent_rec->bin_id);
            $q->leftJoin('bs.Source s');
            $q->addSelect('s.src_uuid as src_uuid');
        }
        else {
            $q = $this->air_query();
        }
        $q->addWhere('s.src_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Custom delete procedure to cleanup bin_src_response_sets
     *
     * @throws Rframe_Exceptions
     * @param  BinSource $rec
     */
    protected function rec_delete(BinSource $rec) {
        $sid = $rec->bsrc_src_id;
        $bid = $rec->bsrc_bin_id;

        // normal delete stuff
        $this->check_authz($rec, 'delete');
        $rec->delete();
        $this->update_parent($rec);

        // delete any orphaned submissions
        $conn = AIR2_DBManager::get_master_connection();
        $conn->exec("delete from bin_src_response_set where bsrs_bin_id=$bid and bsrs_src_id=$sid");
    }


}
