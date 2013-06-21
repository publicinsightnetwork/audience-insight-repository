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
 * Inquiry API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Inquiry extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'fetch', 'create', 'update', 'delete');
    protected $CREATE_DATA = array('inq_title', 'inq_ext_title', 'inq_rss_intro', 'loc_key', 'org_uuid', 'prj_uuid', 'source_query_uuid');
    protected $QUERY_ARGS  = array('status', 'excl_prj', 'type', 'prj_uuid',
        'excl_out');
    protected $UPDATE_DATA = array(
        // identifiers
        'inq_title', 'inq_ext_title',
        // text fields
        'inq_desc', 'inq_intro_para', 'inq_rss_intro', 'inq_ending_para', 'inq_confirm_msg',
        // meta
        'inq_rss_status', 'loc_key', 'inq_url', 'inq_tpl_opts', 'logo',
        // events
        'inq_publish_dtim', 'inq_deadline_msg', 'inq_deadline_dtim', 'inq_expire_msg', 'inq_expire_dtim',
        // actions
        'do_publish', 'do_deactivate', 'do_expire', 'do_schedule', 'do_unschedule');

    // default paging/sorting
    protected $query_args_default = array('type' => 'FQ');  // Formbuilder&Querymaker
    protected $limit_default  = 10;
    protected $offset_default = 0;
    protected $sort_default   = 'inq_cre_dtim asc';
    protected $sort_valids    = array('inq_cre_dtim', 'ispub', 'inq_publish_dtim',
        'inq_ext_title', 'inq_title');

    // metadata
    protected $ident = 'inq_uuid';
    protected $fields = array(
        // identifiers
        'inq_uuid',
        'inq_title',
        'inq_ext_title',
        // text
        'inq_desc',
        'inq_intro_para',
        'inq_rss_intro',
        'inq_ending_para',
        'inq_confirm_msg',
        //meta
        'inq_type',
        'inq_status',
        'inq_stale_flag',
        'inq_rss_status',
        'inq_loc_id',
        'inq_xid',
        'inq_url',
        'inq_tpl_opts',
        'inq_cre_dtim',
        'inq_upd_dtim',
        'inq_cache_dtim',
        //events
        'inq_publish_dtim',
        'inq_deadline_msg',
        'inq_deadline_dtim',
        'inq_expire_msg',
        'inq_expire_dtim',
        //stamps
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
        'CacheUser' => 'DEF::USERSTAMP',
        'Logo'    => 'DEF::IMAGE',
        'Locale'  => 'DEF::LOCALE',
        'InqOrg' => array(
            'iorg_status',
            'Organization' => 'DEF::ORGANIZATION',
            'OrgLogo' => 'DEF::IMAGE',
        ),
        'ProjectInquiry' => array(
            'pinq_status',
            'Project' => 'DEF::PROJECT',
        ),
        //aggregate data
        'sent_count',
        'recv_count',
        'ispub',
    );


    /**
     * Create
     *
     * @param array   $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {

        if (isset($data['source_query_uuid'])) {
            return $this->duplicate_query($data['source_query_uuid']);
        }

        $i = new Inquiry();
        $i->inq_type = Inquiry::$TYPE_QUERYBUILDER;
        $i->inq_status = Inquiry::$STATUS_DRAFT;
        $this->require_data($data, array('inq_ext_title', 'inq_rss_intro', 'loc_key', 'org_uuid', 'prj_uuid'));

        // default to url-ified title
        if (!isset($data['inq_title'])) {
            $i->inq_title = ' ';
        }

        if ($data['loc_key']) {

            $tbl = Doctrine::getTable('Locale');
            $col = 'loc_key';
            $locale = $tbl->findOneBy($col, $data['loc_key']);

            if ($locale) {
                $i->inq_loc_id = $locale->loc_id;
            }
        }
        if ($data['org_uuid']) {
            $org = AIR2_Record::find('Organization', $data['org_uuid']);
            if ($org) {
                $iorg = new InqOrg();
                $iorg->iorg_org_id = $org->org_id;
                $i->InqOrg[] = $iorg;
            }
        }
        if ($data['prj_uuid']) {
            $prj = AIR2_Record::find('Project', $data['prj_uuid']);
            if ($prj) {
                $pinq = new ProjectInquiry();
                $pinq->pinq_prj_id = $prj->prj_id;
                $i->ProjectInquiry[] = $pinq;
            }
        }
        return $i;
    }


    /**
     * Query
     *
     * @param array   $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('Inquiry i');
        $q->leftJoin('i.CreUser ic');
        $q->leftJoin('i.UpdUser iu');
        $q->leftJoin('i.CacheUser cu');
        $q->leftJoin('i.Locale l');
        $q->leftJoin('i.InqOrg io');
        $q->leftJoin('io.Organization o');
        $q->leftJoin('i.ProjectInquiry pi');
        $q->leftJoin('pi.Project p');
        $q->leftJoin("i.Logo ilg WITH ilg.img_ref_type = ?", 'Q');
        $q->leftJoin("io.OrgLogo iol WITH iol.img_ref_type = ?", 'L');
        Inquiry::add_counts($q, 'i');
        $q->addSelect('(inq_publish_dtim is not null) as ispub');

        // status and type
        if (isset($args['status'])) {
            air2_query_in($q, $args['status'], 'i.inq_status');
        }
        if (isset($args['type'])) {
            air2_query_in($q, $args['type'], 'i.inq_type');
        }

        // only within a project
        if (isset($args['prj_uuid'])) {
            $q->addWhere('p.prj_uuid = ?', $args['prj_uuid']);
        }

        // exclude project
        if (isset($args['excl_prj'])) {
            $prjq = "select prj_id from project where prj_uuid = ?";
            $excl = "select pinq_inq_id from project_inquiry where pinq_prj_id = ($prjq)";
            $q->addWhere("i.inq_id NOT IN ($excl)", $args['excl_prj']);
        }

        // exclude an outcome
        if (isset($args['excl_out'])) {
            $outq = "select out_id from outcome where out_uuid = ?";
            $excl = "select iout_inq_id from inq_outcome where iout_out_id = ($outq)";
            $q->addWhere("i.inq_id not in ($excl)", $args['excl_out']);
        }
        return $q;
    }


    /**
     * Fetch
     *
     * @param string  $uuid
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid) {
        $q = $this->air_query();
        $q->where('i.inq_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Override the base rec_update, to handle potential cache-writes
     *
     * @param Inquiry $rec
     * @param array   $data
     */
    protected function rec_update(Inquiry $rec, $data) {

        $rec->inq_stale_flag = true; //mark as stale

        // validate actions
        if (isset($data['do_deactivate'])) {
            if ($rec->is_published()) {
                $msg = 'Cannot deactivate a published query';
                throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
            }
            if ($rec->inq_status == Inquiry::$STATUS_INACTIVE) {
                $msg = 'Cannot deactivate an inactive query';
                throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
            }
        }
        if (isset($data['do_deactivate']) && isset($data['do_publish'])) {
            $msg = 'Cannot deactivate AND publish a query';
            throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
        }


        //TODO: lots of error checking needed
        if (isset($data['do_schedule'])) {
            $rec->inq_status = Inquiry::$STATUS_SCHEDULED;
        }
        if (isset($data['do_unschedule'])) {
            $rec->inq_status = Inquiry::$STATUS_DRAFT;
        }

        if (isset($data['loc_key'])) {

            $tbl = Doctrine::getTable('Locale');
            $col = 'loc_key';
            $locale = $tbl->findOneBy($col, $data['loc_key']);

            if ($locale) {
                $rec->inq_loc_id = $locale->loc_id;
            }
        }

        if (isset($data['logo'])) {
            try {
                if (!$rec->Logo) $rec->Logo = new ImageInqLogo();
                $rec->Logo->set_image($data['logo']);
            }
            catch (Exception $e) {
                throw new Rframe_Exception(RFrame::BAD_DATA, $e->getMessage());
            }
        }

        // delete logo if null is passed
        if (array_key_exists('logo', $data) && !$data['logo']) {
            if ($rec->Logo) {
                $rec->Logo->delete();
                $rec->clearRelated('Logo');
            }
        }
        // update columns
        foreach ($data as $key => $val) {
            if ($rec->getTable()->hasColumn($key)) {
                $rec->$key = $val;
            }
        }

        // authz
        $this->check_authz($rec, 'write');
        $this->air_save($rec);

        // actions!
        if (isset($data['do_publish'])) {
            $rec->do_publish();
        }
        if (isset($data['do_deactivate'])) {
            $rec->do_deactivate();
        }
        if (isset($data['do_expire'])) {
            $rec->do_expire();
        }

    }


    /**
     * Check status before delete
     *
     * @param Inquiry $rec
     */
    protected function air_delete(Inquiry $rec) {
        if ($rec->inq_status != Inquiry::$STATUS_DRAFT) {
            $msg = 'Unable to delete a non-draft query';
            throw new Rframe_Exception(Rframe::BAD_METHOD, $msg);
        }
    }

    /**
     * Make a new query based on the contents of an existing one.
     *
     * @param string $uuid the uuid of the query to duplicate
     *
     * @return Inquiry $new_inquiry
     */
    protected function duplicate_query($uuid) {

        $rec = $this->air_fetch($uuid);

        $home_org = $this->user->get_home_org();

        $new_data = $rec->toArray(true);

        $new_data['loc_key'] = $new_data['Locale']['loc_key'];
        $new_data['org_uuid'] = $home_org->org_uuid;
        $new_data['prj_uuid'] = $home_org->DefaultProject->prj_uuid;

        $reset_keys = array(
            'inq_id',
            'inq_uuid',
            'CreUser',
            'UpdUser',
            'InqOrg',
            'Locale',
            'ProjectInquiry',
            'inq_type',
            'inq_status',
            'inq_upd_dtim',
            'inq_expire_dtim',
            'inq_cache_dtim',
            'inq_publish_dtim',
            'inq_deadline_dtim',
            'inq_cre_user',
            'inq_upd_user',
            'inq_cache_user',
            'inq_cre_dtim',
            'inq_org_id',
            'inq_title',
            'inq_url',
        );

        foreach ($reset_keys as $reset_key) {
            $new_data[$reset_key] = NULL;
            unset($new_data[$reset_key]);
        }

        $new_data['inq_ext_title'] = $new_data['inq_ext_title'] . ' copy';

        if (! isset($new_data['inq_rss_intro'])) {
            $new_data['inq_rss_intro'] = 'PLEASE ENTER A SHORT DESCRIPTION';
        }

        // make the new query. catch exceptions and still try to duplicate the
        // questions to validate those as well. (no "suprise" errors after the
        // query is cleaned up)
        try {
            $new_inquiry_uuid = $this->rec_create($new_data);
        } catch(exception $outer_e) {
            $feaux_intro = 'This query was created to validate question ' .
            ' copying after an query failed to duplicate. It should have been '.
            ' cleaned up automatically. Please report this to support.';

            $feaux_data = array(
                'inq_ext_title' => 'air2-question-duping-temp-inquiry',
                'loc_key' => $new_data['loc_key'],
                'org_uuid' => $home_org->org_uuid,
                'prj_uuid' => $home_org->DefaultProject->prj_uuid,
                'inq_rss_intro' => $feaux_intro,
            );

            $feaux_inquiry_uuid = $this->rec_create($feaux_data);
            $feaux_inquiry = $this->air_fetch($feaux_inquiry_uuid);

            try {
                $this->duplicate_questions($rec, $feaux_inquiry);
            } catch(exception $e) {

                // if we can't dupe the questions
                // delete the duplicate query and
                // show the errror
                $feaux_inquiry->delete();

                throw new Rframe_Exception(
                    Rframe::BAD_DATA,
                    'Query Errors:<br /><br />' .
                    $outer_e->getMessage() .
                    '<br /><br /><br /><br />Question Errors:<br /><br />' .
                    $e->getMessage()
                );
            }
            $feaux_inquiry->delete();
            throw new Rframe_Exception(Rframe::BAD_DATA, $outer_e->getMessage());
        }

        if (!$new_inquiry_uuid) {
            $msg = 'Could not create duplicate query.';
            throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
        }

        $new_inquiry = $this->air_fetch($new_inquiry_uuid);

        if (!$new_inquiry) {
            $msg = 'Could not get new query.';
            throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
        }

        try {
            $this->duplicate_questions($rec, $new_inquiry);
        } catch(exception $e) {

            // if we can't dupe the questions
            // delete the duplicate query and
            // show the errror
            $new_inquiry->delete();

            throw new Rframe_Exception(Rframe::BAD_DATA, $e->getMessage());
        }

        return $new_inquiry;
    }

    /**
     * Copy all the questions from one query to another
     *
     * @param Inquiry $from_rec the query to copy from
     * @param Inquiry $to_rec the query to copy to
     */
    protected function duplicate_questions(Inquiry $from_rec, Inquiry $to_rec) {

        // get source questions
        $q = Doctrine_Query::create()->from('Question q');
        $q->where('q.ques_inq_id = ?', $from_rec->inq_id);

        $permission_types = array(
            Question::$TYPE_PERMISSION,
            Question::$TYPE_PERMISSION_HIDDEN,
        );

        $default_question_templates = array(
            Question::$TKEY_FIRSTNAME,
            Question::$TKEY_LASTNAME,
            Question::$TKEY_EMAIL,
            Question::$TKEY_ZIP,
        );

        $results = $q->execute();

        foreach ($results as $idx => $ques_rec) {
            if ( ! in_array($ques_rec->ques_template, $default_question_templates) &&
                 ! in_array($ques_rec->ques_type, $permission_types)) {
                $new_question = new Question();
                $new_question->ques_inq_id = $to_rec->inq_id;
                AIR2_QueryBuilder::copy_question($new_question, $ques_rec->ques_uuid);
                $this->air_save($new_question);
            }
        }
    }
}
