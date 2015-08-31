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
require_once 'phperl/callperl.php';

/**
 * Email/Export API
 *
 * Resource representing a SrcExport related to an email.  Also allows
 * creating (scheduling) a new Mailchimp-export, or sending a preview of the
 * email.
 *
 * This is a single-resource, and all you can do is 'create' or 'fetch' it.
 *
 * @author rcavis
 * @package default
 */
class AAPI_Email_Export extends AIRAPI_Resource {

    // single resource
    protected static $REL_TYPE = self::ONE_TO_ONE;

    // API definitions
    protected $ALLOWED = array('create', 'fetch');
    protected $CREATE_DATA = array(
        // when previewing
        'preview',
        // when cancelling
        'cancel',
        // when actually sending
        'bin_uuid',
        'strict_check',
        'schedule',
        'dry_run',
        'no_export',
    );

    // metadata
    protected $ident = 'se_uuid';
    protected $fields = array(
        'se_uuid',
        'se_name',
        'se_type',
        'se_ref_type',
        'se_status',
        'se_notes',
        'se_cre_dtim',
        'se_upd_dtim',
        'CreUser' => 'DEF::USERSTAMP',
        'UpdUser' => 'DEF::USERSTAMP',
        'Bin'     => array(
            'bin_uuid',
            'bin_name',
            'bin_desc',
            'bin_type',
            'bin_status',
            'bin_shared_flag',
            'bin_cre_dtim',
            'bin_upd_dtim',
        ),
        'Source' => 'DEF::SOURCE',
        'SrcResponseSet' => array(
            'DEF::SRCRESPONSESET',
            'Source' => 'DEF::SOURCE',
        ),
    );


    /**
     * Fetch
     *
     * @param string  $uuid
     * @param bool    $minimal
     * @return Doctrine_Record $rec
     */
    protected function air_fetch($uuid, $minimal=false) {
        $q = Doctrine_Query::create()->from('SrcExport se');
        $q->where('se.se_email_id = ?', $this->parent_rec->email_id);

        $q->leftJoin('se.CreUser cu');
        $q->leftJoin('se.UpdUser uu');
        SrcExport::joinRelated($q, 'se');

        return $q->fetchOne();
    }


    /**
     * Schedule/preview an export
     *
     * @param array   $data
     */
    protected function air_create($data) {
        $prev  = isset($data['preview']) ? $data['preview'] : null;
        $cancel = isset($data['cancel']) ? $data['cancel'] : null;
        $sched = isset($data['schedule']) ? $data['schedule'] : null;

        if ($prev && $sched) {
            $msg = "Cannot preview and schedule an email export";
            throw new Rframe_Exception(Rframe::BAD_DATA, $msg);
        }
        elseif ($cancel) {
            $this->unschedule_mailchimp_export($data);
        }
        elseif ($prev) {
            $this->send_preview($prev);
        }
        else {
            $this->schedule_mailchimp_export($data);
        }
    }


    /**
     * Send a preview email
     *
     * @param string  $addr
     */
    private function send_preview($addr) {
        try {
            $email_id = $this->parent_rec->email_id;
            CallPerl::exec('AIR2::Email->send_preview', $email_id, $addr, '[PROOF] ');
        }
        catch (PerlException $e) {
            throw new Rframe_Exception(Rframe::BAD_DATA, $e->getMessage());
        }
        throw new Rframe_Exception(Rframe::BGND_CREATE, 'Email preview sent');
    }


    /**
     * Attempt to schedule a Mailchimp export
     *
     * @param array   $data
     */
    private function schedule_mailchimp_export($data) {
        $this->require_data($data, array('bin_uuid'));

        // validate email
        $eml = $this->parent_rec;
        $send_authz = $eml->user_may_send($this->user);
        if (!$send_authz['success']) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Email not ready to be sent');
        }

        // validate bin
        $bin = AIR2_Record::find('Bin', $data['bin_uuid']);
        if (!$bin) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'Invalid bin_uuid');
        }
        if (!$bin->user_may_read($this->user)) {
            throw new Rframe_Exception(Rframe::BAD_DATA, 'No read authz for bin');
        }

        // timestamp
        $time = null;
        if (array_key_exists('schedule', $data) && $data['schedule']) {
            $time = $data['schedule'];
            // make sure we save it in server timezone
            $tz = new DateTimeZone(AIR2_SERVER_TIME_ZONE);
            $dt = new DateTime($time);
            $dt->setTimezone($tz);
            $time = $dt->format(AIR2_DTIM_FORMAT);
        }

        // extra params (and defaults)
        $strict = true;
        $dry = false;
        $no_exp = false;
        if (array_key_exists('strict_check', $data) && !$data['strict_check']) {
            $strict = false;
        }
        if (array_key_exists('dry_run', $data) && $data['dry_run']) {
            $dry = true;
        }
        if (array_key_exists('no_export', $data) && $data['no_export']) {
            $no_exp = true;
        }
        $extra = array('strict' => $strict, 'dry_run' => $dry, 'no_exp' => $no_exp);

        // punch it!
        try {
            // lock the email, so it doesn't get sent again
            $eml->email_status = Email::$STATUS_SCHEDULED;
            if ($time) $eml->email_schedule_dtim = $time;
            $bin->queue_mailchimp_export($this->user, $eml, $extra);
            $eml->save();
        }
        catch (Exception $e) {
            throw new Rframe_Exception(Rframe::UNKNOWN_ERROR, $e->getMessage());
        }

        // success, but the resource doesn't exist yet, so throw up!
        $msg = 'Mailchimp export scheduled for background processing';
        throw new Rframe_Exception(Rframe::BGND_CREATE, $msg);
    }


    /**
     *
     *
     * @param unknown $data
     */
    private function unschedule_mailchimp_export($data) {
        $eml = $this->parent_rec;
        $eml->cancel_scheduled_send();
        $eml->save();

        // interrupt flow since we do not want to alter an Export
        throw new Rframe_Exception(Rframe::OKAY, 'Email schedule canceled');
    }


}
