<?php
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

/**
 * Email
 *
 * A template for sending an email to a source/bin
 *
 * @property integer    $email_id
 * @property integer    $email_org_id
 * @property integer    $email_usig_id
 * @property string     $email_uuid
 * @property string     $email_campaign_name
 *
 * @property string     $email_from_name
 * @property string     $email_from_email
 * @property string     $email_subject_line
 * @property string     $email_headline
 * @property string     $email_body
 *
 * @property string     $email_type
 * @property string     $email_status
 * @property timestamp  $email_schedule_dtim
 *
 * @property integer    $email_cre_user
 * @property integer    $email_upd_user
 * @property timestamp  $email_cre_dtim
 * @property timestamp  $email_upd_dtim
 *
 * @property Organization        $Organization
 * @property UserSignature       $UserSignature
 * @property Image               $Logo
 * @property Doctrine_Collection $EmailInquiry
 * @property Doctrine_Collection $SrcExport
 *
 * @author rcavis
 * @package default
 */
class Email extends AIR2_Record {

    public static $STATUS_ACTIVE    = 'A'; //sent
    public static $STATUS_SCHEDULED = 'Q';
    public static $STATUS_DRAFT     = 'D';
    public static $STATUS_INACTIVE  = 'F'; //archived

    public static $TYPE_QUERY     = 'Q';
    public static $TYPE_FOLLOW_UP = 'F';
    public static $TYPE_REMINDER  = 'R';
    public static $TYPE_THANK_YOU = 'T';
    public static $TYPE_OTHER     = 'O';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('email');

        // identifiers
        $this->hasColumn('email_id', 'integer', 4, array(
                'primary'       => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('email_org_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('email_usig_id', 'integer', 4, array());
        $this->hasColumn('email_uuid', 'string', 12, array(
                'fixed'   => true,
                'notnull' => true,
                'unique'  => true,
            ));
        $this->hasColumn('email_campaign_name', 'string', 255, array(
                'notnull' => true,
            ));

        // text
        $this->hasColumn('email_from_name', 'string', 255, array());
        $this->hasColumn('email_from_email', 'string', 255, array());
        $this->hasColumn('email_subject_line', 'string', 255, array());
        $this->hasColumn('email_headline', 'string', 255, array());
        $this->hasColumn('email_body', 'string', null, array(
                'airvalidhtml' => array(
                    'display' => 'Email Body',
                    'message' => 'Not well formed html'
                ),
            ));

        // meta
        $this->hasColumn('email_type', 'string', 1, array(
                'fixed'   => true,
                'notnull' => true,
                'default' => self::$TYPE_OTHER,
            ));
        $this->hasColumn('email_status', 'string', 1, array(
                'fixed'   => true,
                'notnull' => true,
                'default' => self::$STATUS_DRAFT,
            ));
        $this->hasColumn('email_report', 'string', null, array());
        $this->hasColumn('email_schedule_dtim', 'timestamp', null, array());

        // user/timestamps
        $this->hasColumn('email_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('email_upd_user', 'integer', 4, array());
        $this->hasColumn('email_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('email_upd_dtim', 'timestamp', null, array());

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Organization', array(
                'local'   => 'email_org_id',
                'foreign' => 'org_id',
            ));
        $this->hasOne('UserSignature', array(
                'local'   => 'email_usig_id',
                'foreign' => 'usig_id',
            ));
        $this->hasOne('ImageEmailLogo as Logo', array(
                'local'   => 'email_id',
                'foreign' => 'img_xid',
            ));
        $this->hasMany('EmailInquiry', array(
                'local'   => 'email_id',
                'foreign' => 'einq_email_id',
            ));
        $this->hasMany('SrcExport', array(
                'local'   => 'email_id',
                'foreign' => 'se_email_id',
            ));
    }


    /**
     *
     */
    public function cancel_scheduled_send() {
        // find the job and delete it
        $job_sql = 'jq_type=? and jq_xid=? and jq_start_dtim is null and jq_start_after_dtim=?';
        $q = AIR2_Query::create()->from('JobQueue');
        $q->where($job_sql, array(JobQueue::$TYPE_EMAIL, $this->email_id, $this->email_schedule_dtim));
        $job = $q->fetchOne();
        if (!$job) {
            throw new Exception("No scheduled job found");
        }
        $job->delete();
        $q->free();

        // null schedule column and reset status
        $this->email_schedule_dtim = null;
        $this->email_status = self::$STATUS_DRAFT;
    }


    /**
     * Run a sanity check, to see if the email can be sent/scheduled.  This
     * ALWAYS returns an object, indicating a pass/fail status on each test.
     *  1 == Pass
     *  0 == Fail
     * -1 == Warning
     *
     * @param User    $user
     * @return array
     */
    public function user_may_send($user) {
        $tests = array();

        // need edit authz
        $tests[] = array('No authz to edit email', $this->user_may_write($user));
        $tests[] = array('No authz to send email', $this->email_cre_user == $user->user_id);

        // required fields
        $tests[] = array('Missing from name', $this->email_from_name);
        $tests[] = array('Missing from address', $this->email_from_email);
        $tests[] = array('Invalid from address', filter_var($this->email_from_email, FILTER_VALIDATE_EMAIL));
        $tests[] = array('Missing subject line', $this->email_subject_line);
        $tests[] = array('Missing headline', $this->email_headline);
        $tests[] = array('Missing body text', $this->email_body);
        $tests[] = array('Missing signature', $this->UserSignature && $this->UserSignature->usig_text);

        // email status
        $tests[] = array('Email not in Draft state', $this->email_status == Email::$STATUS_DRAFT);
        $tests[] = array('Email has already been exported', $this->SrcExport->count() < 1);

        // associated queries
        if ($this->email_type == Email::$TYPE_QUERY) {
            $tests[] = array('Missing associated queries', $this->EmailInquiry->count() > 0);
        }
        elseif ($this->email_type == Email::$TYPE_FOLLOW_UP ||
            $this->email_type == Email::$TYPE_REMINDER  ||
            $this->email_type == Email::$TYPE_THANK_YOU) {
            $tests[] = array('Missing associated queries', $this->EmailInquiry->count() > 0 ? 1 : -1);
        }

        // change conditions into pure 1/0/-1 values
        $errors = 0;
        $warnings = 0;
        foreach ($tests as $i => $test) {
            if ($tests[$i][1] !== -1) {
                $tests[$i][1] = $tests[$i][1] ? 1 : 0;
            }
            if (!$tests[$i][1]) $errors++;
            if ($tests[$i][1] === -1) $warnings++;
        }
        return array(
            'success'       => $errors < 1,
            'error_count'   => $errors,
            'warning_count' => $warnings,
            'tests'         => $tests,
        );
    }


    /**
     * Read authz
     *
     * @param User    $user
     * @return boolean
     */
    public function user_may_read($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        if ($this->email_cre_user == $user->user_id) {
            return AIR2_AUTHZ_IS_OWNER;
        }

        // check users auth in email-org
        $orgid = $this->email_org_id;
        $authz = $user->get_authz();
        $role = isset($authz[$orgid]) ? $authz[$orgid] : null;
        if (ACTION_EMAIL_READ & $role) {
            return AIR2_AUTHZ_IS_ORG;
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Write authz
     *
     * @param User    $user
     * @return boolean
     */
    public function user_may_write($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        if (!$this->exists()) {
            $authz = $user->get_authz();
            foreach ($authz as $org_id => $role) {
                if ($role & ACTION_EMAIL_CREATE) {
                    return AIR2_AUTHZ_IS_NEW;
                }
            }
        }
        elseif ($this->email_cre_user == $user->user_id) {
            return AIR2_AUTHZ_IS_OWNER;
        }
        else {
            $authz = $user->get_authz();
            $orgid = $this->email_org_id;
            $role  = isset($authz[$orgid]) ? $authz[$orgid] : null;
            if (ACTION_EMAIL_CREATE & $role) {
                return AIR2_AUTHZ_IS_ORG;
            }
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Manage authz - same as write
     *
     * @param User    $user
     * @return boolean
     */
    public function user_may_manage($user) {
        return $this->user_may_write($user);
    }


    /**
     * Read - owner or shared
     *
     * @param Doctrine_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     */
    public static function query_may_read($q, $u, $alias=null) {
        if ($u->is_system()) return;
        $a = ($alias) ? "$alias." : "";

        // readable
        $rd_org_ids = $u->get_authz_str(ACTION_EMAIL_READ, "{$a}email_org_id", true);

        // owner
        $uid = $u->user_id;
        $owner = "email_cre_user=$uid";

        // add to query
        $q->addWhere("($rd_org_ids or $owner)");
    }


    /**
     * Write - owner
     *
     * @param Doctrine_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     */
    public static function query_may_write($q, $u, $alias=null) {
        if ($u->is_system()) return;
        $a = ($alias) ? "$alias." : "";
        $q->addWhere("{$a}bin_user_id = ?", $u->user_id);
    }


    /**
     * Manage - same as write
     *
     * @param Doctrine_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     */
    public static function query_may_manage($q, $u, $alias=null) {
        self::query_may_write($q, $u, $alias);
    }


    /**
     * Add custom search query (from the get param 'q')
     *
     * @param AIR2_Query $q
     * @param string  $alias
     * @param string  $search
     * @param boolean $useOr
     */
    public static function add_search_str(&$q, $alias, $search, $useOr=null) {
        $a = ($alias) ? "$alias." : "";
        $str = "({$a}email_campaign_name like ? or email_subject_line like ?)";
        $params = array("%$search%", "%$search%");

        // try searching cre_user and organization
        if ($alias) {
            $parts = $q->getDqlPart('from');
            foreach ($parts as $dql) {
                // CreUser
                if (preg_match("/$alias.CreUser.*$/", $dql, $matches)) {
                    $usr_alias = preg_replace("/$alias.CreUser\s*/", '', $matches[0]);
                    if ($usr_alias) {
                        $tmp = Doctrine_Query::create();
                        User::add_search_str($tmp, $usr_alias, $search);
                        $usrq = array_pop($tmp->getDqlPart('where'));
                        $usrp = $tmp->getFlattenedParams();
                        $str .= " or $usrq";
                        $params = array_merge($params, $usrp);
                    }
                }

                // Organization
                if (preg_match("/$alias.Organization.*$/", $dql, $matches)) {
                    $org_alias = preg_replace("/$alias.Organization\s*/", '', $matches[0]);
                    if ($org_alias) {
                        $tmp = Doctrine_Query::create();
                        Organization::add_search_str($tmp, $org_alias, $search);
                        $orgq = array_pop($tmp->getDqlPart('where'));
                        $orgp = $tmp->getFlattenedParams();
                        $str .= " or $orgq";
                        $params = array_merge($params, $orgp);
                    }
                }
            }
        }

        // add to query
        if ($useOr) {
            $q->orWhere($str, $params);
        }
        else {
            $q->addWhere($str, $params);
        }
    }


}
