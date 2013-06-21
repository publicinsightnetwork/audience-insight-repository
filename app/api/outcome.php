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
require_once 'AIR2Outcome.php';


/**
 * Outcome API
 *
 * @author rcavis
 * @package default
 */
class AAPI_Outcome extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'create', 'fetch', 'update', 'delete');
    protected $CREATE_DATA = array('out_headline', 'out_url', 'out_teaser',
        'out_dtim', 'org_uuid', 'prj_uuid', 'inq_uuid', 'src_uuid', 'emails',
        'emails_cited', 'emails_featured', 'out_status', 'out_type',
        'out_internal_headline', 'out_internal_teaser', 'out_show', 'out_survey', 'sout_type', 'bin_uuid');
    protected $UPDATE_DATA = array('out_headline', 'out_url', 'out_teaser', 'out_dtim',
        'org_uuid', 'emails', 'out_status', 'out_type', 'out_internal_headline',
        'out_internal_teaser', 'out_show', 'out_survey', 'inq_uuid', 'sout_type');
    protected $QUERY_ARGS  = array();

    // default paging/sorting
    protected $sort_default   = 'out_dtim desc';
    protected $sort_valids    = array('out_dtim');

    // these are the bulk UPDATE operations allowed on this resource
    // (keys will be added to $UPDATE_DATA)
    protected $BULK_OPS = array(
        'sources',
    );

    // metadata
    protected $ident = 'out_uuid';
    protected $fields = array(
        'out_uuid',
        'out_headline',
        'out_internal_headline',
        'out_url',
        'out_teaser',
        'out_internal_teaser',
        'out_show',
        'out_survey',
        'out_dtim',
        'out_meta',
        'out_type',
        'out_status',
        'out_cre_dtim',
        'out_upd_dtim',
        'org_uuid',
        'org_name',
        'org_display_name',
        'InqOutcome' => array(
            'iout_inq_id',
        ),
        'Organization' => 'DEF::ORGANIZATION',
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
        // aggregates
        'inq_count',
        'src_count',
        'prj_count',
    );

    /**
     * Add $BULK_OPS to $UPDATE_DATA
     *
     * @param Rframe_Parser $parser
     * @param array         $path
     * @param array         $inits
     */
    public function __construct($parser, $path=array(), $inits=array()) {
        foreach ($this->BULK_OPS as $key) {
            $this->UPDATE_DATA[] = $key;
        }
        parent::__construct($parser, $path, $inits);
    }

    /**
     * Query
     *
     * @param array $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('Outcome o');
        $q->leftJoin('o.CreUser cu');
        $q->leftJoin('o.UpdUser uu');
        $q->leftJoin('o.Organization org');
        $q->leftJoin('o.InqOutcome iout');
        $q->leftJoin('iout.Inquiry inq');

        // flatten org a bit
        $q->addSelect('org.org_uuid as org_uuid');
        $q->addSelect('org.org_name as org_name');
        $q->addSelect('org.org_display_name as org_display_name');

        // add counts
        $sel = "(select count(*) from %s where %s=o.out_id) as %s";
        $q->addSelect(sprintf($sel, 'inq_outcome', 'iout_out_id', 'inq_count'));
        $q->addSelect(sprintf($sel, 'src_outcome', 'sout_out_id', 'src_count'));
        $q->addSelect(sprintf($sel, 'prj_outcome', 'pout_out_id', 'prj_count'));
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
        $q->andWhere('o.out_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Create
     *
     * We have to override 'rec_create' instead of 'air_create' here, because
     * Doctrine sucks at pulling the correct data out of the SrcOutcome in the
     * post-insert hooks.
     *
     * @param array $data
     * @return string $uuid
     */
    protected function rec_create($data) {
        $this->require_data($data, array('out_headline', 'out_teaser'));
        $rec = new Outcome();

        // organization
        if (isset($data['org_uuid']) && $data['org_uuid']) {
            $o = AIR2_Record::find('Organization', $data['org_uuid']);
            if (!$o) throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid org_uuid');
            $rec->out_org_id = $o->org_id;
        }

        // project
        if (isset($data['prj_uuid']) && $data['prj_uuid']) {
            $p = AIR2_Record::find('Project', $data['prj_uuid']);
            if (!$p) throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid prj_uuid');
            $rec->PrjOutcome[]->pout_prj_id = $p->prj_id;
        }

        // inquiry
        if (isset($data['inq_uuid']) && $data['inq_uuid']) {
            $i = AIR2_Record::find('Inquiry', $data['inq_uuid']);
            if (!$i) throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid inq_uuid');
            $rec->InqOutcome[]->iout_inq_id = $i->inq_id;
        }

        $add_src_ids = array();

        if (isset($data['bin_uuid']) && $data['bin_uuid']) {
            $b = AIR2_Record::find('Bin', $data['bin_uuid']);
            if (!$b) throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid bin_uuid');
            $bsources = $b->get('BinSource');
            $type = $data['sout_type'];
            if ($bsources) {
                foreach ($bsources->toArray() as $key => $bsource) {
                    $src_id = $bsource['bsrc_src_id'];
                    $add_src_ids[$src_id] = $type;
                }
            }
        }

        // add the sources later, so the activity logging works
        if (isset($data['src_uuid']) && $data['src_uuid']) {
            $s = AIR2_Record::find('Source', $data['src_uuid']);
            if (!$s) throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid src_uuid');
            $add_src_ids[$s->src_id] = SrcOutcome::$TYPE_INFORMED;
        }

        // process email lists
        $em_tbl = Doctrine::getTable('SrcEmail');
        $list_keys = array(
            'emails'          => SrcOutcome::$TYPE_INFORMED,
            'emails_cited'    => SrcOutcome::$TYPE_CITED,
            'emails_featured' => SrcOutcome::$TYPE_FEATURED,
        );
        foreach ($list_keys as $key => $code) {
            if (isset($data[$key])) {
                $parts = explode(',', $data[$key]);
                foreach ($parts as $em) {
                    $em = trim($em);
                    if ($em && strlen(trim($em)) > 0) {
                        $eml_rec = $em_tbl->findOneBy('sem_email', $em);
                        if (!$eml_rec) {
                            throw new Rframe_Exception(Rframe::BAD_DATA, "Unknown email \"$em\"");
                        }
                        $add_src_ids[$eml_rec->sem_src_id] = $code;
                    }
                }
            }
        }

        // update and check authz
        foreach ($data as $key => $val) {
            if ($rec->getTable()->hasColumn($key)) $rec->$key = $val;
        }
        $this->check_authz($rec, 'write');

        // save and add the sources
        $this->air_save($rec);
        foreach ($add_src_ids as $srcid => $code) {
            $sout = new SrcOutcome();
            $sout->sout_out_id = $rec->out_id;
            $sout->sout_src_id = $srcid;
            $sout->sout_type = $code;
            $this->air_save($sout);
        }

        // send email alert, if set in profile
        if (defined('AIR2_EMAIL_ALERTS')) {
            $this->_send_notification_email($rec);
        }

        // return identifier
        return $rec[$this->ident];
    }


    /**
     * Update out_org_id
     *
     * @param Doctrine_Record $rec
     * @param array $data
     */
    protected function air_update($rec, $data) {

        // check perms
        if (!$rec->user_may_write($this->user)) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "You do not have permission to update this PINfluence.");
            return;
        }

        // unset bulk_op vars
        $this->bulk_op = null;
        $this->bulk_rs = null;

        if (isset($data['org_uuid']) && $data['org_uuid']) {
            $o = AIR2_Record::find('Organization', $data['org_uuid']);
            if (!$o) throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid org_uuid');
            $rec->out_org_id = $o->org_id;
            $rec->Organization = $o;
        }

        $bulk_op = '';
        foreach ($this->BULK_OPS as $op) {
            if (isset($data[$op])) {
                $bulk_op = $op;
                break;
            }
        }

        if ($bulk_op) {
             // sanity
            if (count($data) > 1) {
                throw new Rframe_Exception(Rframe::BAD_DATA, "Bulk operation ".
                    "$bulk_op cannot run with any other updates!");
            }
            $this->run_bulk($rec, $bulk_op, $data[$bulk_op]);
            // touch timestamp, since bulk ops usually don't

            $rec->out_upd_user = $this->user->user_id;
            $rec->out_upd_dtim = air2_date();
        }



    }


    /**
     * Send a notification email that a new PINfluence has been created
     *
     * @param Outcome $outcome
     */
    private function _send_notification_email($outcome) {
        $subj = "New PINfluence Filed in AIR";
        $link = air2_uri_for("outcome/{$outcome->out_uuid}");
        $body = "It's here!  A brand new PINfluence!\n\n";
        $body .= "Filed by: {$this->user->user_username}\n";
        $body .= "Permalink: $link\n\n";

        // Build based on entered fields
        $fields = array(
            'Story Headline'                    => 'out_headline',
            'How the PIN influenced this story' => 'out_teaser',
            'Content Link'                      => 'out_url',
            'Publish/Air/Event Date'            => 'out_dtim',
            'Show in feeds'                     => 'out_status',
            'Content Type'                      => 'out_type',
            'Program/Event/Website'             => 'out_show',
            'Additional Information'            => 'out_internal_teaser',
        );
        $statuses = array('A' => 'Yes', 'N' => 'No');
        $types = array('S' => 'Story', 'R' => 'Series', 'E' => 'Event', 'O' => 'Other');
        foreach ($fields as $name => $fld) {
            if ($val = $outcome->$fld) {
                if ($fld == 'out_status') $val = $statuses[$val];
                if ($fld == 'out_type') $val = $types[$val];
                $body .= "$name: $val\n";
            }
        }
        $body .= "\n";

        // add more complex fields
        if ($outcome->Organization) {
            $body .= "Organization: {$outcome->Organization->org_display_name}\n";
        }
        foreach ($outcome->PrjOutcome as $pout) {
            $body .= "Project: {$pout->Project->prj_display_name}\n";
        }
        if ($outcome->SrcOutcome->count() > 0) {
            $srcs = array();
            foreach ($outcome->SrcOutcome as $sout) {
                $srcs[] = $sout->Source->src_username;
            }
            $body .= "Sources: " . implode(", ", $srcs) . "\n";
        }
        foreach ($outcome->InqOutcome as $iout) {
            $body .= "Query: {$iout->Inquiry->inq_ext_title}\n";
        }
        if ($outcome->out_survey && $surv = json_decode($outcome->out_survey, true)) {
            $checked = array();
            foreach ($surv as $key => $val) {
                if ($val) $checked[] = $key;
            }
            if (count($checked)) {
                $body .= "Survey: " . implode(" - ", $checked) . "\n";
            }
        }

        // send the mail!
        mail(AIR2_EMAIL_ALERTS, $subj, $body);
    }

    /**
     * Process bulk add/remove/etc operations
     *
     * @param Outcome $rec
     * @param string  $bulk_op
     * @param array   $data
     */
    protected function run_bulk($rec, $bulk_op, $data) {
        // rethrow any exceptions as 'data' exceptions
        try {
            if ($bulk_op == 'sources') {
                $bin = AIR2_Record::find('Bin', $data['bin_uuid']);
                if (!$bin) {
                    throw new Rframe_Exception(Rframe::BAD_DATA, 'Unable to get the Bin specified.');
                    return;
                }
                $this->bulk_rs = AIR2Outcome::add_sources_from_bin($rec, $bin, $data['sout_type']);
            }
        }
        catch (Rframe_Exception $e) {
            throw $e; //re-throw as-is
        }
        catch (Exception $e) {
            throw new Rframe_Exception(Rframe::BAD_DATA, $e->getMessage());
        }
    }

}
