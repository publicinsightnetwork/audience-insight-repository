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
 * Bin/SrcSub API
 *
 * A similar resource to bin/source, except that this returns an array of submissions
 * under each source.  Can take quite a bit longer to load.
 *
 * READ-ONLY!
 *
 * @author rcavis
 * @package default
 */
class AAPI_Bin_SrcSub extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'update');
    protected $QUERY_ARGS  = array();
    protected $UPDATE_DATA = array('bsrc_notes');

    // default paging/sorting
    protected $sort_default = 'src_first_name asc';
    protected $sort_valids  = array('src_first_name', 'src_last_name', 'primary_email',
        'primary_address_city', 'added_dtim');

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
        // submissions
        'SrcResponseSet' => array(
            'srs_uuid',
            'srs_date',
            'srs_uri',
            'srs_type',
            'srs_cre_dtim',
            'srs_upd_dtim',
            'Inquiry' => 'DEF::INQUIRY',
            'SrcResponse' => array(
                'sr_uuid',
                'sr_orig_value',
                'sr_mod_value',
                'Question' => array(
                    'ques_uuid',
                    'ques_dis_seq',
                    'ques_status',
                    'ques_type',
                    'ques_value',
                    'ques_choices',
                ),
            ),
        ),
        // aggregate count (no authz applied)
        'subm_count',
    );


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

        // manual srs-authz
        // ugh... try to work around doctrines lousy join WITH restrictions (anger!!!)
        $bid = $this->parent_rec->bin_id;
        $srs_ids  = "select bsrs.bsrs_srs_id from BinSrcResponseSet bsrs where bsrs.bsrs_bin_id=$bid";
        $read_org_ids = $this->user->get_authz_str(ACTION_ORG_PRJ_INQ_SRS_READ, 'porg_org_id', true);
        $prj_ids  = "select porg_prj_id from project_org where $read_org_ids";
        $inq_ids  = "select pinq.pinq_inq_id from ProjectInquiry pinq where pinq.pinq_prj_id in ($prj_ids)";

        // submission stuff
        $q->leftJoin("s.SrcResponseSet srs WITH srs.srs_id in ($srs_ids) and srs.srs_inq_id in ($inq_ids)");
        $q->leftJoin('srs.Inquiry srsi');
        $q->leftJoin('srs.SrcResponse sr');
        $q->leftJoin('sr.Question srq');

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

        // aggregate count
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
    protected function air_fetch($uuid) {
        $q = $this->air_query();
        $q->addWhere('s.src_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Move SrcResponseSet before cleaning
     *
     * @param mixed $record
     */
    protected function format_radix($record) {
        $radix = $record->toArray();
        $radix['SrcResponseSet'] = $radix['Source']['SrcResponseSet'];
        $radix = $this->_clean($radix, $this->_fields);
        return $radix;
    }


    /**
     * Custom query string (searches sources and responses)
     *
     * @param Doctrine_query $q
     * @param string $str
     * @param string $root_tbl (optional)
     * @param string $root_alias (optional)
     */
    protected function apply_search($q, $str, $root_tbl=null, $root_alias=null) {
        $left = "'".addslashes($str)."%'";
        $both = "'%".addslashes($str)."%'";
        $wheres = array(
            "(bs.bsrc_notes like $both)",
            "(s.src_first_name like $left or s.src_last_name like $left)",
            "(e.sem_email like $left)",
            "(srsi.inq_ext_title like $both)",
        );
        $q->addWhere('('.implode(' or ', $wheres).')');
    }

}
