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
 * Email API
 *
 * (Email templates that users send via Mailchimp)
 *
 * @author rcavis
 * @package default
 */
class AAPI_Email extends AIRAPI_Resource {

    // API definitions
    protected $ALLOWED = array('query', 'create', 'fetch', 'update', 'delete');
    protected $CREATE_DATA = array(
        'org_uuid', 'dup_uuid', 'srs_uuid', 'src_uuid', 'usig_uuid',
        'email_campaign_name', 'email_subject_line', 'email_body', 'email_type',
        'no_export'
    );
    protected $UPDATE_DATA = array(
        'org_uuid', 'usig_uuid', 'usig_text', 'logo',
        'email_campaign_name', 'email_from_name', 'email_from_email',
        'email_subject_line', 'email_headline', 'email_body', 'email_type',
        'email_status'
    );
    protected $QUERY_ARGS  = array('mine', 'status', 'type');

    // default query/paging/sorting
    protected $query_args_default = array(
        'mine'   => true,
        'status' => 'AQD',
        'type'   => '',
    );
    protected $sort_default   = 'email_cre_dtim desc';
    protected $sort_valids    = array('email_campaign_name', 'email_from_name',
        'email_from_email', 'email_subject_line', 'email_headline',
        'email_cre_dtim', 'email_upd_dtim', 'org_name', 'owner_first',
        'email_schedule_dtim', 'first_exported_dtim');

    // metadata
    protected $ident = 'email_uuid';
    protected $fields = array(
        'email_uuid',
        'email_campaign_name',
        'email_from_name',
        'email_from_email',
        'email_subject_line',
        'email_headline',
        'email_body',
        'email_type',
        'email_status',
        'email_cre_dtim',
        'email_upd_dtim',
        'email_schedule_dtim',
        // logo image
        'Logo' => 'DEF::IMAGE',
        // has-one organization
        'org_uuid',
        'org_name',
        'org_display_name',
        'Organization' => 'DEF::ORGANIZATION',
        // has-one user_signature
        'usig_uuid',
        'usig_text',
        'UserSignature' => 'DEF::USERSIGNATURE',
        // has-one cre/upd_users
        'owner_first',
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
        // has-many (but actually 0-or-1) src_exports
        'first_exported_dtim',
        'SrcExport' => array(
            'se_uuid',
            'se_name',
            'se_type',
            'se_status',
            'se_notes',
            'se_cre_dtim',
            'se_upd_dtim',
        ),
        // has-many inquiries (include count only)
        'inq_count',
    );


    /**
     * Create
     *
     * @param array   $data
     * @return Doctrine_Record $rec
     */
    protected function air_create($data) {
        $eml = new Email();

        if (isset($data['srs_uuid']) || isset($data['src_uuid'])) {
            // optionally hold up the export
            $noexp = isset($data['no_export']) ? true : false;
            unset($data['no_export']);

            $rep = $this->create_reply($eml, $data);
            $this->send_single($eml, $rep['addr'], $rep['srs_id'], $noexp); //throws
        }
        elseif (isset($data['dup_uuid'])) {
            $this->create_default($eml, $data); //get defaults first
            $this->create_duplicate($eml, $data);
        }
        else {
            $this->create_default($eml, $data);
        }

        return $eml;
    }


    /**
     * Update - (handle image creation/deletion)
     *
     * @param Email   $eml
     * @param array   $data
     */
    protected function air_update($eml, $data) {
        if (array_key_exists('logo', $data)) {
            if ($data['logo']) {
                try {
                    if (!$eml->Logo) $eml->Logo = new ImageEmailLogo();
                    $eml->Logo->set_image($data['logo']);
                }
                catch (Exception $e) {
                    throw new Rframe_Exception(RFrame::BAD_DATA, $e->getMessage());
                }
            }
            else {
                if ($eml->Logo) {
                    $eml->Logo->delete();
                    $eml->clearRelated('Logo');
                }
            }
        }

        // organization change
        if (isset($data['org_uuid'])) {
            $org = AIR2_Record::find('Organization', $data['org_uuid']);
            if (!$org) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid Organization specified!');
            }
            $eml->Organization = $org;
        }

        // signature setting/creation
        if (isset($data['usig_uuid'])) {
            $usig = AIR2_Record::find('UserSignature', $data['usig_uuid']);
            if (!$usig) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid Signature specified!');
            }
            $usig->usig_upd_dtim = air2_date(); //touch
            $eml->UserSignature = $usig;
        }
        elseif (isset($data['usig_text'])) {
            $usig = new UserSignature();
            $usig->usig_user_id = $this->user->user_id;
            $usig->usig_text = $data['usig_text'];
            $eml->UserSignature = $usig;
        }
    }


    /**
     * Query
     *
     * @param array   $args
     * @return Doctrine_Query $q
     */
    protected function air_query($args=array()) {
        $q = Doctrine_Query::create()->from('Email e');
        $q->leftJoin('e.Logo elg WITH elg.img_ref_type = ?', 'E');
        $q->leftJoin('e.Organization org');
        $q->leftJoin('e.UserSignature usig');
        $q->leftJoin('e.CreUser cu');
        $q->leftJoin('e.UpdUser uu');
        $q->leftJoin('e.SrcExport ese');

        // flatten a bit
        $q->addSelect('org.org_uuid as org_uuid');
        $q->addSelect('org.org_name as org_name');
        $q->addSelect('org.org_display_name as org_display_name');
        $q->addSelect('usig.usig_uuid as usig_uuid');
        $q->addSelect('usig.usig_text as usig_text');
        $q->addSelect('cu.user_first_name as owner_first');
        $q->addSelect('(select count(*) from email_inquiry where einq_email_id = e.email_id) as inq_count');
        $q->addSelect('ese.se_cre_dtim as first_exported_dtim');

        // status and type
        if (isset($args['status'])) {
            air2_query_in($q, $args['status'], 'e.email_status');
        }
        if (isset($args['type'])) {
            air2_query_in($q, $args['type'], 'e.email_type');
        }

        // stuff I own
        if (isset($args['mine']) && $args['mine'] && $args['mine'] !== 'false') {
            $q->addWhere('e.email_cre_user = ?', $this->user->user_id);
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
        $q->andWhere('e.email_uuid = ?', $uuid);
        return $q->fetchOne();
    }


    /**
     * Override to include user_may_send authz tests
     *
     * @param mixed   $mixed
     * @param string  $method
     * @param string  $uuid   (optional)
     * @param array   $extra  (optional)
     * @return array $response
     */
    protected function format($mixed, $method, $uuid=null, $extra=array()) {
        $resp = parent::format($mixed, $method, $uuid, $extra);
        if ($method == 'fetch' && is_a($mixed, 'Doctrine_Record')) {
            $resp['authz']['may_send'] = $mixed->user_may_send($this->user);
        }
        return $resp;
    }


    /**
     * Create a default email (chooses a bunch of defaults)
     *
     * @param Email   $eml
     * @param array   $data
     */
    private function create_default($eml, $data) {
        $eml->email_status = Email::$STATUS_DRAFT;
        $this->require_data($data, array('email_campaign_name', 'email_type', 'org_uuid'));

        $org = AIR2_Record::find('Organization', $data['org_uuid']);
        if (!$org) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid Organization specified!');
        }
        $eml->Organization = $org;

        // default logo (pull from the org)
        if ($org->Logo->exists()) {
            try {
                $cpy = $org->Logo->get_image();
                $eml->Logo = new ImageEmailLogo();
                $eml->Logo->set_image($cpy['original']);
            }
            catch (Exception $e) {
                $eml->Logo = null;
            }
        }

        // default signature (find the most recent one the user touched)
        $q = Doctrine_Query::create()->from('UserSignature s');
        $q->where('s.usig_user_id = ?', $this->user->user_id);
        $q->orderBy('s.usig_upd_dtim desc');
        $sig = $q->fetchOne();
        if ($sig) $eml->UserSignature = $sig;

        // more defaults
        $eml->email_from_name = $this->user->get_email_from_name();
        if ($uem = $this->user->get_primary_email()) {
            $eml->email_from_email = $uem;
        }
        $eml->email_subject_line = 'Insert your subject line here';
        $eml->email_headline = 'Insert your headline here';
        $eml->email_body = 'Insert the body of your email here';
    }


    /**
     * Create a duplicate email
     *
     * @param Email   $eml
     * @param array   $data
     */
    private function create_duplicate($eml, $data) {
        $dup = AIR2_Record::find('Email', $data['dup_uuid']);
        if (!$dup || !$dup->user_may_read($this->user)) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid Email to duplicate!');
        }
        $eml->email_from_name = $this->user->get_email_from_name();
        $eml->email_from_email = $this->user->get_primary_email();
        $eml->email_subject_line = $dup->email_subject_line;
        $eml->email_headline = $dup->email_headline;
        $eml->email_body = $dup->email_body;

        // copy logo, if it exists
        if ($dup->Logo->exists()) {
            try {
                if (!$eml->Logo) $eml->Logo = new ImageEmailLogo();
                $cpy = $dup->Logo->get_image();
                $eml->Logo->set_image($cpy['original']);
            }
            catch (Exception $e) {
                $eml->Logo = null;
            }
        }

        // copy inquiries/signature, only if same owner
        if ($dup->email_cre_user == $this->user->user_id) {
            if ($dup->UserSignature) {
                $eml->UserSignature = $dup->UserSignature;
            }
            foreach ($dup->EmailInquiry as $einq) {
                $new_einq = new EmailInquiry();
                $new_einq->einq_inq_id = $einq->einq_inq_id;
                $eml->EmailInquiry[] = $new_einq;
            }
        }
    }


    /**
     * Create and send a "reply" email
     *
     * @param Email   $eml
     * @param array   $data
     * @return unknown
     */
    private function create_reply($eml, $data) {
        $eml->email_status = Email::$STATUS_DRAFT;
        $this->require_data($data, array('org_uuid', 'email_campaign_name',
                'email_type', 'email_subject_line', 'email_body', 'usig_uuid'));
        if (!isset($data['src_uuid']) && !isset($data['srs_uuid'])) {
            throw new Rframe_Exception(Rframe::BAD_DATA, "Must provide src_uuid or srs_uuid");
        }

        // organization
        $org = AIR2_Record::find('Organization', $data['org_uuid']);
        if (!$org) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid Organization specified!');
        }
        $eml->Organization = $org;

        // signature
        $usig = AIR2_Record::find('UserSignature', $data['usig_uuid']);
        if (!$usig) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid Signature specified!');
        }
        $eml->UserSignature = $usig;

        // and the rest
        if ($this->user->user_first_name && $this->user->user_last_name) {
            $eml->email_from_name = $this->user->user_first_name . ' ' . $this->user->user_last_name;
        }
        else {
            $eml->email_from_name = $this->user->user_username;
        }
        $eml->email_from_email = $this->user->get_primary_email();
        $eml->email_campaign_name = $data['email_campaign_name'];
        $eml->email_subject_line = $data['email_subject_line'];
        $eml->email_body = $data['email_body'];
        $eml->email_type = $data['email_type'];

        // source and submission
        $return_data = array('addr' => null, 'srs_id' => null);
        $src_email = null;
        if (isset($data['srs_uuid'])) {
            $srs = AIR2_Record::find('SrcResponseSet', $data['srs_uuid']);
            if (!$srs) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid Submission specified!');
            }
            $return_data['srs_id'] = $srs->srs_id;
            $src_email = $srs->Source->get_primary_email();

            // associate the query
            $eml->EmailInquiry[]->einq_inq_id = $srs->srs_inq_id;
        }
        else {
            $src = AIR2_Record::find('Source', $data['src_uuid']);
            if (!$src) {
                throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid Source specified!');
            }
            $src_email = $src->get_primary_email();
        }

        // email address
        if (!$src_email || $src_email->sem_status != SrcEmail::$STATUS_GOOD) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Source has no good email address');
        }
        $return_data['addr'] = $src_email->sem_email;

        return $return_data;
    }


    /**
     * Save/send a single email, and throw a BGND-CREATE at the end
     *
     * @param Email   $eml
     * @param String  $addr
     * @param Integer $srs_id
     * @param Boolean $no_export
     */
    private function send_single($eml, $addr, $srs_id=null, $no_export=null) {
        $this->check_authz($eml, 'read');
        $this->air_save($eml);

        try {
            if (!$no_export) {
                CallPerl::exec('AIR2::Email->send_single', $eml->email_id, $addr, $srs_id);
            }
        }
        catch (PerlException $e) {
            throw new Rframe_Exception(Rframe::BAD_DATA, $e->getMessage());
        }
        throw new Rframe_Exception(Rframe::BGND_CREATE, $eml->email_uuid);
    }


}
