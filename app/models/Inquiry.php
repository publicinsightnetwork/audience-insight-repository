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
 * Inquiry
 *
 * A collection of questions sent out to sources
 *
 * @property integer    $inq_id
 * @property string     $inq_uuid
 * @property string     $inq_title       (deprecated)
 * @property string     $inq_ext_title
 *
 * @property string     $inq_desc        (deprecated)
 * @property string     $inq_intro_para
 * @property string     $inq_rss_intro
 * @property string     $inq_ending_para (deprecated)
 * @property string     $inq_confirm_msg
 *
 * @property string     $inq_type
 * @property string     $inq_status
 * @property string     $inq_stale_flag
 * @property string     $inq_public_flag
 * @property string     $inq_rss_status
 * @property integer    $inq_loc_id
 * @property integer    $inq_xid
 * @property string     $inq_url
 * @property string     $inq_tpl_opts
 *
 * @property timestamp  $inq_publish_dtim
 * @property string     $inq_deadline_msg
 * @property timestamp  $inq_deadline_dtim
 * @property string     $inq_expire_msg
 * @property timestamp  $inq_expire_dtim
 *
 * @property integer    $inq_cre_user
 * @property integer    $inq_upd_user
 * @property integer    $inq_cache_user
 * @property timestamp  $inq_cre_dtim
 * @property timestamp  $inq_upd_dtim
 * @property timestamp  $inq_cache_dtim
 *
 * @property Locale     $Locale
 * @property UserStamp  $CacheUser
 * @property Doctrine_Collection $ProjectInquiry
 * @property Doctrine_Collection $Question
 * @property Doctrine_Collection $SrcResponseSet
 * @property Doctrine_Collection $SrcInquiry
 * @property Doctrine_Collection $InquiryAnnotation
 * @property Doctrine_Collection $InqOrg
 * @property Doctrine_Collection $InqOutcome
 * @property Doctrine_Collection $Tags
 *
 * @author rcavis
 * @package default
 */
require_once 'phperl/callperl.php';
require_once 'querybuilder/AIR2_QueryBuilder.php';

class Inquiry extends AIR2_Record {
    /*
     * A - Published - accepting submissions
     * S - Scheduled - inq_publish_dtim >= $now
     * L - Deadline - accepting submissions, but deadline is past
     * E - Expired - NOT accepting, but still visible
     * D - Draft - invisible
     * F - Inactive - invisible, but was at one point visible
     */
    public static $STATUS_ACTIVE    = 'A';
    public static $STATUS_SCHEDULED = 'S';
    public static $STATUS_DEADLINE  = 'L';
    public static $STATUS_EXPIRED   = 'E';
    public static $STATUS_DRAFT     = 'D';
    public static $STATUS_INACTIVE  = 'F';

    public static $TYPE_FORMBUILDER  = 'F';
    public static $TYPE_MANUAL_ENTRY = 'E';
    public static $TYPE_COMMENT      = 'C';
    public static $TYPE_QUERYBUILDER = 'Q';

    /*
     * legal types of manual-entry inquiries (these are actually used as
     * the answer to the first question of the inquiry)
     */
    public static $MANUAL_TYPES = array(
        'E' => array(
            'label' => 'Email',
            'actm'  => ActivityMaster::EMAIL_IN,
        ),
        'P' => array(
            'label' => 'Phone Call',
            'actm'  => ActivityMaster::PHONE_IN,
        ),
        'T' => array(
            'label' => 'Text Message',
            'actm'  => ActivityMaster::TEXT_IN,
        ),
        'I' => array(
            'label' => 'In-person Interaction',
            'actm'  => ActivityMaster::PERSONEVENT,
        ),
        'O' => array(
            'label' => 'Online Action',
            'actm'  => ActivityMaster::ONLINEEVENT,
        ),
    );

    // fallback protection against re-adding permission question
    protected $_has_permission_question = false;

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('inquiry');

        // identifiers
        $this->hasColumn('inq_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('inq_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('inq_title', 'string', 128, array(
                'notnull' => true,
            ));
        $this->hasColumn('inq_ext_title', 'string', 255, array());

        // text
        $this->hasColumn('inq_desc', 'string', 255, array());
        $this->hasColumn(
            'inq_intro_para',
            'string',
            null,
            array(
                'airvalidhtml' => array(
                    'display' => 'Full Description',
                    'message' => 'Not well formed html'
                )
            )
        );

        $this->hasColumn('inq_rss_intro', 'string', null, array(
                'airvalidnohtml' => array(
                    'display' => 'Short Description',
                    'message' => 'No HTML (<>&) allowed in short description.'
                )
        ));
        $this->hasColumn('inq_ending_para', 'string', null, array());
        $this->hasColumn(
            'inq_confirm_msg',
            'string',
            null,
            array(
                'airvalidhtml' => array(
                    'display' => 'Thank You Message',
                    'message' => 'Not well formed html'
                )
            )
        );


        // meta
        $this->hasColumn('inq_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$TYPE_FORMBUILDER,
            ));
        $this->hasColumn('inq_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('inq_stale_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => true,
            ));
        $this->hasColumn('inq_rss_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => "N",
            ));
        $this->hasColumn('inq_loc_id', 'integer', 4, array(
                'default' => 52, /* en_US -- see Locale.yml */
                'notnull' => true,
            ));
        $this->hasColumn('inq_xid', 'integer', 4, array());
        $this->hasColumn('inq_url', 'string', 255, array());
        $this->hasColumn('inq_tpl_opts', 'string', 255, array());

        // events
        $this->hasColumn('inq_publish_dtim', 'timestamp', null, array());
        $this->hasColumn(
            'inq_deadline_msg',
            'string',
            null,
            array(
                'airvalidhtml' => array(
                    'display' => 'Deadline Message',
                    'message' => 'Not well formed html'
                )
            )
        );

        $this->hasColumn('inq_deadline_dtim', 'timestamp', null, array());
        $this->hasColumn(
            'inq_expire_msg',
            'string',
            null,
            array(
                'airvalidhtml' => array(
                    'display' => 'Expire Message',
                    'message' => 'Not well formed html'
                )
            )
        );

        $this->hasColumn('inq_expire_dtim', 'timestamp', null, array());

        // user/timestamps
        $this->hasColumn('inq_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('inq_upd_user', 'integer', 4, array());
        $this->hasColumn('inq_cache_user', 'integer', 4, array());
        $this->hasColumn('inq_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('inq_public_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('inq_upd_dtim', 'timestamp', null, array());
        $this->hasColumn('inq_cache_dtim', 'timestamp', null, array());

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasMany('InquiryActivity', array(
                'local' => 'inq_id',
                'foreign' => 'ia_inq_id'
            ));
        $this->hasMany('ProjectInquiry', array(
                'local' => 'inq_id',
                'foreign' => 'pinq_inq_id'
            ));
        $this->hasMany('Question', array(
                'local' => 'inq_id',
                'foreign' => 'ques_inq_id'
            ));
        $this->hasMany('SrcResponseSet', array(
                'local' => 'inq_id',
                'foreign' => 'srs_inq_id'
            ));
        $this->hasMany('SrcInquiry', array(
                'local' => 'inq_id',
                'foreign' => 'si_inq_id'
            ));
        $this->hasMany('InquiryAnnotation', array(
                'local' => 'inq_id',
                'foreign' => 'inqan_inq_id',
            ));
        $this->hasMany('InqOrg', array(
                'local' => 'inq_id',
                'foreign' => 'iorg_inq_id',
            ));
        $this->hasMany('InqOutcome', array(
                'local' => 'inq_id',
                'foreign' => 'iout_inq_id'
            ));
        $this->hasMany('InquiryAuthor as Author', array(
                'local' => 'inq_id',
                'foreign' => 'iu_inq_id'
            ));
        $this->hasMany('InquiryWatcher as Watcher', array(
                'local' => 'inq_id',
                'foreign' => 'iu_inq_id'
            ));
        $this->hasOne('Locale', array(
                'local' => 'inq_loc_id',
                'foreign' => 'loc_id'
            ));
        $this->hasOne('UserStamp as CacheUser',
            array('local' => 'inq_cache_user', 'foreign' => 'user_id')
        );

        // Tagging
        $this->hasMany('TagInquiry as Tags', array(
                'local' => 'inq_id',
                'foreign' => 'tag_xid'
            ));

        // image
        $this->hasOne('ImageInqLogo as Logo', array(
                'local' => 'inq_id',
                'foreign' => 'img_xid',
            ));

        // add a mutator on the optional dtim fields
        // to fix doctrine bug with setting null on timestamp columns
        $this->hasMutator('inq_expire_dtim', '_set_inq_expire_dtim');
        $this->hasMutator('inq_deadline_dtim', '_set_inq_deadline_dtim');
        $this->hasMutator('inq_publish_dtim', '_set_inq_publish_dtim');
    }


    /**
     * Custom mutator to reset inq_deadline_dtim to NULL value.
     *
     * @param timestamp $value
     */
    public function _set_inq_expire_dtim($value) {
        $this->_set_timestamp('inq_expire_dtim', $value);
    }



    /**
     * Custom mutator to reset inq_deadline_dtim to NULL value.
     *
     * @param timestamp $value
     */
    public function _set_inq_deadline_dtim($value) {
        $this->_set_timestamp('inq_deadline_dtim', $value);
    }


    /**
     * Custom mutator to reset inq_publish_dtim to NULL value.
     *
     * @param timestamp $value
     */
    public function _set_inq_publish_dtim($value) {
        $this->_set_timestamp('inq_publish_dtim', $value);
    }



    /**
     * Delete any image assets.
     *
     * @param Doctrine_Event $event
     * @return unknown
     */
    public function preDelete($event) {
        // nuke any logo files
        if ($this->Logo && $this->Logo->exists()) {
            $this->Logo->delete();
        }
        return parent::preDelete($event);
    }


    /**
     * Add Projects to this Inquiry.
     *
     * @param array   $prjs
     */
    public function add_projects(array $prjs) {
        foreach ($prjs as $prj) {
            $pinq = new ProjectInquiry;
            $pinq->pinq_prj_id = $prj->prj_id;
            $pinq->pinq_status = 'A';
            $this->ProjectInquiry[] = $pinq;
        }
    }



    /**
     * Add Organizations to this Inquiry;
     *
     * @param array   $orgs
     */
    public function add_orgs(array $orgs) {
        foreach ($orgs as $org) {
            $iorg = new InqOrg();
            $iorg->iorg_org_id = $org->org_id;
            $iorg->iorg_status = 'A';
            $this->InqOrg[] = $iorg;
        }
    }


    /**
     * Returns array of related Organization org_ids that affect
     * the authorization of the Inquiry.
     *
     * @param boolean $include_children
     * @return array   $org_ids
     */
    public function get_authz($include_children=true) {
        $org_ids = array();
        foreach ($this->ProjectInquiry as $pinq) {
            foreach ($pinq->Project->ProjectOrg as $porg) {
                if ($include_children) {
                    $children = Organization::get_org_children($porg->porg_org_id);
                    foreach ($children as $org_id) {
                        $org_ids[$org_id] = 1;
                    }
                }
                else {
                    $org_ids[$porg->porg_org_id] = 1;
                }
            }
        }
        return array_keys($org_ids);
    }


    /**
     * Reading Inquiries
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // allow owner to read
        if ($user->user_id == $this->inq_cre_user) {
            return AIR2_AUTHZ_IS_OWNER;
        }

        // others reading
        $authz = $user->get_authz();
        $org_ids = $this->get_authz();
        foreach ($org_ids as $org_id) {
            $role = isset($authz[$org_id]) ? $authz[$org_id] : null;
            if (ACTION_ORG_PRJ_INQ_READ & $role) {
                return AIR2_AUTHZ_IS_ORG;
            }
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Writing Inquiries
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // allow owner to edit
        if ($user->user_id == $this->inq_cre_user) {
            return AIR2_AUTHZ_IS_OWNER;
        }

        // if new, allow inq-creators
        $authz = $user->get_authz();
        if (!$this->exists()) {
            foreach ($authz as $orgid => $role) {
                if (ACTION_ORG_PRJ_INQ_CREATE & $role) {
                    return AIR2_AUTHZ_IS_OWNER;
                }
            }
        }

        // others updating
        $org_ids = $this->get_authz(false); //NO CHILDREN!
        foreach ($org_ids as $org_id) {
            $role = isset($authz[$org_id]) ? $authz[$org_id] : null;
            if (ACTION_ORG_PRJ_INQ_UPDATE & $role) {
                return AIR2_AUTHZ_IS_ORG;
            }
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Managing Inquiries
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // allow owner to manage
        if ($user->user_id == $this->inq_cre_user) {
            return AIR2_AUTHZ_IS_OWNER;
        }

        // allow contact-user to manage
        foreach ($this->ProjectInquiry as $pinq) {
            foreach ($pinq->Project->ProjectOrg as $porg) {
                if ($user->user_id == $porg->porg_contact_user_id) {
                    return AIR2_AUTHZ_IS_MANAGER;
                }
            }
        }

        // others updating
        $authz = $user->get_authz();
        $org_ids = $this->get_authz(false); //NO CHILDREN
        foreach ($org_ids as $org_id) {
            $role = isset($authz[$org_id]) ? $authz[$org_id] : null;
            if (ACTION_ORG_PRJ_INQ_DELETE & $role) {
                return AIR2_AUTHZ_IS_ORG;
            }
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Apply authz rules for who may view the existence of an Inquiry.
     *
     * @param AIR2_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     */
    public static function query_may_read(AIR2_Query $q, User $u, $alias=null) {
        if ($u->is_system()) {
            return;
        }
        $a = ($alias) ? "$alias." : "";

        // readable
        $rd_org_ids = $u->get_authz_str(ACTION_ORG_PRJ_INQ_READ, 'porg_org_id', true);
        $prj_ids = "select porg_prj_id from project_org where $rd_org_ids";
        $inq_ids = "select pinq_inq_id from project_inquiry where pinq_prj_id in ($prj_ids)";

        // owner
        $uid = $u->user_id;
        $owner = "inq_cre_user=$uid";

        // add to query
        $q->addWhere("({$a}inq_id in ($inq_ids) or $owner)");
    }


    /**
     * Apply authz rules for who may write to an Inquiry.
     *
     * @param AIR2_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     */
    public static function query_may_write(AIR2_Query $q, User $u, $alias=null) {
        if ($u->is_system()) {
            return;
        }
        $a = ($alias) ? "$alias." : "";
        $uid = $u->user_id;

        // writable or contact-user
        $wt_org_ids = $u->get_authz_str(ACTION_ORG_PRJ_INQ_UPDATE, 'porg_org_id');
        $is_contact = "porg_contact_user_id=$uid";
        $prj_ids = "select porg_prj_id from project_org where $wt_org_ids or $is_contact";
        $inq_ids = "select pinq_inq_id from project_inquiry where pinq_prj_id in ($prj_ids)";

        // owner
        $owner = "inq_cre_user=$uid";

        // add to query
        $q->addWhere("({$a}inq_id in ($inq_ids) or $owner)");
    }


    /**
     * Apply authz rules for who may manage an Inquiry.
     *
     * @param AIR2_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     */
    public static function query_may_manage(AIR2_Query $q, User $u, $alias=null) {
        if ($u->is_system()) {
            return;
        }
        $a = ($alias) ? "$alias." : "";
        $uid = $u->user_id;

        // managable or contact-user
        $mg_org_ids = $u->get_authz_str(ACTION_ORG_PRJ_INQ_DELETE, 'porg_org_id');
        $is_contact = "porg_contact_user_id=$uid";
        $prj_ids = "select porg_prj_id from project_org where $mg_org_ids or $is_contact";
        $inq_ids = "select pinq_inq_id from project_inquiry where pinq_prj_id in ($prj_ids)";

        // owner
        $owner = "inq_cre_user=$uid";

        // add to query
        $q->addWhere("({$a}inq_id in ($inq_ids) or $owner)");
    }


    /**
     * Add sent/recieved counts to an inquiry query.
     *
     * @param AIR2_Query $q
     * @param char    $alias
     * @param array   $fld_defs (optional, reference)
     */
    public static function add_counts(AIR2_Query $q, $alias='', &$fld_defs=null) {
        if ($alias) $alias = "$alias.";
        $sent_count = "(select count(*) from src_inquiry where si_inq_id = {$alias}inq_id) as sent_count";
        $recv_count = "(select count(*) from src_response_set where srs_inq_id = {$alias}inq_id) as recv_count";
        $q->addSelect($sent_count);
        $q->addSelect($recv_count);
        if (is_array($fld_defs)) {
            $fld_defs []= array('name' => 'sent_count', 'type' => 'int');
            $fld_defs []= array('name' => 'recv_count', 'type' => 'int');
        }
    }


    /**
     *
     *
     * @param string  $uri_base (optional)
     * @return string $uri
     */
    public function get_uri($uri_base=AIR2_MYPIN2_URL) {
        if ($this->inq_url) {
            return $this->inq_url;
        }
        $title = !empty($this->inq_ext_title)
            ? $this->inq_ext_title
            : $this->inq_title;
        return sprintf("%s/%s/%s/insight/%s/%s", $uri_base,
            $this->get_uri_locale(),
            $this->InqOrg[0]->Organization->org_name,
            $this->inq_uuid,
            air2_urlify($title)
        );
    }


    /**
     *
     *
     * @return string $uri_path
     */
    public function get_uri_path() {
        $title = $this->get_title();
        return sprintf("%s/insight/%s/%s",
            $this->InqOrg[0]->Organization->org_name,
            $this->inq_uuid,
            air2_urlify($title)
        );
    }


    /**
     *
     *
     * @return string $locale
     */
    public function get_uri_locale() {
        return preg_replace('/_\w\w$/', '', $this->Locale->loc_key);
    }


    /**
     * Looks at event triggers (publish/deadline/expire dtim) and changes the
     * inq_status accordingly.
     *
     * @return boolean $has_changed
     */
    public function update_status_from_events() {
        $stat = $this->inq_status;

        // inactive status is never automated
        if ($stat == self::$STATUS_INACTIVE) {
            return false;
        }

        $now = air2_date();
        if (!$this->is_published()) {
            if ($this->inq_publish_dtim && $this->inq_publish_dtim <= $now) {
                $stat = self::$STATUS_ACTIVE;
            }
        }
        if ($this->is_published()) {

            //error_log("inquiry is published, now=" . $now);
            //error_log("inq_expire_dtim          =" . $this->inq_expire_dtim);
            //error_log("inq_deadline_dtim        =" . $this->inq_deadline_dtim);

            // expires always takes precedence
            if ($this->inq_expire_dtim && $this->inq_expire_dtim <= $now) {
                $stat = self::$STATUS_EXPIRED;
            }
            elseif ($this->inq_deadline_dtim && $this->inq_deadline_dtim <= $now) {
                $stat = self::$STATUS_DEADLINE;
            }

            //error_log("status now               = $stat");
        }
        $has_changed = ($stat != $this->inq_status);
        $this->inq_status = $stat;
        return $has_changed;
    }


    /**
     * Returns the values of inq_status that denote a 'published' inquiry.
     *
     * @return array Array of strings.
     * */
    public static function published_status_flags() {
        return array(
            self::$STATUS_ACTIVE,
            self::$STATUS_DEADLINE,
            self::$STATUS_EXPIRED,
        );
    }


    /**
     * Helper to check if a query is published (visible to the public)
     *
     * @return boolean $is_published
     */
    public function is_published() {
        return in_array($this->inq_status, self::published_status_flags());
    }


    /**
     * Publish an inquiry by writing it to cache files
     *
     * @return unknown
     */
    public function do_publish() {

        $now = air2_date();

        $activity = new InquiryActivity();
        $activity->ia_inq_id = $this->inq_id;
        $activity->ia_actm_id = 49;
        $activity->ia_dtim = $now;
        $activity->ia_desc = 'published by {USER}';

        // implicitly set if not published
        if (!$this->inq_publish_dtim) {
            $this->inq_publish_dtim = $now;
        }

        $this->InquiryActivity[] = $activity;

        // check to see if we've previously expired this and reset expire time
        if (strtotime($this->inq_expire_dtim) < time()) {
            $this->inq_expire_dtim = null;
        }

        // calculate status from event timestamps
        $this->inq_status = self::$STATUS_ACTIVE;
        $this->update_status_from_events();

        $published = CallPerl::exec('AIR2::InquiryPublisher->publish', $this->inq_uuid);

        $this->inq_stale_flag = 0;
        $this->save();

        return true;
    }


    /**
     * Expire an inquiry by marking it expired and calling publish
     *
     * @return boolean true on success, will throw exception on failure.
     */
    public function do_expire() {

        $activity = new InquiryActivity();
        $activity->ia_inq_id = $this->inq_id;
        $activity->ia_actm_id = 49;
        $activity->ia_desc = 'expired by {USER}';
        $activity->ia_dtim = air2_date();
        $this->InquiryActivity[] = $activity;
        $this->inq_status = self::$STATUS_EXPIRED;
        $this->inq_expire_dtim = air2_date();
        $this->inq_stale_flag = 0;
        $this->save();

        // call after save so that expire time and status are checked correctly.
        $unpublished = CallPerl::exec('AIR2::InquiryPublisher->publish', $this->inq_uuid);

        return true;
    }





    /**
     * Deactivate an inquiry by changing inq_status and calling unpublish
     *
     * @return boolean true on success, will throw exception on failure.
     */
    public function do_deactivate() {

        $activity = new InquiryActivity();
        $activity->ia_inq_id = $this->inq_id;
        $activity->ia_actm_id = 49;
        $activity->ia_desc = 'deactivated by {USER}';
        $activity->ia_dtim = air2_date();
        $this->InquiryActivity[] = $activity;
        $this->inq_status = self::$STATUS_INACTIVE;
        $unpublished = CallPerl::exec('AIR2::InquiryPublisher->unpublish', $this->inq_uuid);

        $this->inq_stale_flag = 0;
        $this->save();

        return true;
    }


    //TODO: docs
    /**
     * Retrieve a preview of the published query
     *
     * @param unknown $format (optional)
     * @return unknown
     */
    public function get_preview($format='html') {
        return CallPerl::exec('AIR2::InquiryPublisher->get_preview', $this->inq_uuid, $format);
    }


    /**
     * Create a new "Manual Entry" type of inquiry, complete with the standard
     * questions.
     *
     * @return Inquiry $inq
     */
    public static function make_manual_entry() {
        $inq = new Inquiry();
        $inq->inq_title = 'manual_entry';
        $inq->inq_ext_title = 'Submission Manual Entry';
        $inq->inq_desc = 'Query object to hold manual User input';
        $inq->inq_type = Inquiry::$TYPE_MANUAL_ENTRY;
        $inq->Question[0]->ques_type = Question::$TYPE_PICK_DROPDOWN;
        $inq->Question[0]->ques_value = 'Entry type';
        $choices = array();
        foreach (self::$MANUAL_TYPES as $code => $def) {
            $choices[] = array('value' => $def['label'], 'isdefault' => false);
        }
        $inq->Question[0]->ques_choices = json_encode($choices);
        $inq->Question[0]->ques_dis_seq = 1;
        $inq->Question[1]->ques_value = 'Description';
        $inq->Question[1]->ques_dis_seq = 2;
        $inq->Question[2]->ques_value = 'Text';
        $inq->Question[2]->ques_dis_seq = 3;
        return $inq;
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
        $str = "({$a}inq_title LIKE ? OR {$a}inq_ext_title LIKE ?)";
        if ($useOr) {
            $q->orWhere($str, array("%$search%", "$search%"));
        }
        else {
            $q->addWhere($str, array("%$search%", "$search%"));
        }
    }


    /**
     * Returns title of the Inquiry, preferring inq_ext_title over inq_title.
     *
     * @return string $title
     */
    public function get_title() {
        if (strlen($this->inq_ext_title)) {
            return $this->inq_ext_title;
        }
        return $this->inq_title;
    }


    /**
     *
     *
     * @return boolean true if has expected number of published files
     */
    public function has_published_files() {
        $base_path = AIR2_QUERY_DOCROOT;
        $written = 0;
        $exts = array('json', 'html');
        foreach ($exts as $ext) {
            $written += file_exists($base_path . '/' . $this->inq_uuid . '.' . $ext);
        }
        if ($written == count($exts)) {
            return true;
        }
        return false;
    }


    /**
     * Post save() hook provided by Doctrine.
     *
     *
     * @return void
     * @param Doctrine_Event $event
     * */
    public function postSave($event) {
        /*
         * Clear the current projects and orgs RSS feed cache(s).
         */
        if ($this->ProjectInquiry) {
            foreach ($this->ProjectInquiry as $pi) {
                if (file_exists($pi->Project->get_rss_cache_path())) {
                    unlink( $pi->Project->get_rss_cache_path() );
                }
            }
        }
        if ($this->InqOrg) {
            foreach ($this->InqOrg as $io) {
                if (file_exists($io->Organization->get_rss_cache_path())) {
                    unlink( $io->Organization->get_rss_cache_path());
                }
            }
        }

        /*
         * Clear the RSS feed cache for all projects.
         */
        if (file_exists( Project::get_combined_rss_cache_path() ) ) {
            unlink( Project::get_combined_rss_cache_path() );
        }

        // manual entry has no need of default questions
        if ($this->inq_type != self::$TYPE_MANUAL_ENTRY) {
            // see about default questions.
            $this->_check_default_questions();
            $this->check_permission_question(false);
        }
    }


    /**
     *
     *
     * @param unknown $event
     */
    public function preInsert($event) {
        $activity = new InquiryActivity();
        $activity->ia_actm_id = 42;
        $activity->ia_desc = 'created by {USER}';
        $activity->ia_dtim = air2_date();
        $this->InquiryActivity[] = $activity;

        $author = new InquiryAuthor();
        $author->iu_user_id = defined('AIR2_REMOTE_USER_ID') ? AIR2_REMOTE_USER_ID : 1;
        $this->Author[] = $author;

        $watcher = new InquiryWatcher();
        $watcher->iu_user_id = defined('AIR2_REMOTE_USER_ID') ? AIR2_REMOTE_USER_ID : 1;
        $this->Watcher[] = $watcher;

        parent::preInsert($event);
    }


    /**
     *
     */
    private function _check_default_questions() {

        // get all existing questions
        $q = AIR2_Query::create()->from('Question q');
        $q->where('q.ques_inq_id = ?', $this->inq_id);

        $count = $q->count();

        if (!$count) {

            $defaults = array(
                Question::$TKEY_FIRSTNAME,
                Question::$TKEY_LASTNAME,
                Question::$TKEY_EMAIL,
                Question::$TKEY_ZIP,
            );

            $sequence = 1;

            foreach ($defaults as $template) {
                $question = new Question();
                $question->ques_inq_id = $this->inq_id;
                $question->ques_dis_seq = $sequence;

                $sequence++;

                AIR2_QueryBuilder::make_question($question, $template);
                $question->save();
            }
        }
    }


    /**
     * See if the permission question is needed.
     *
     *
     * @param bool    $force (optional) force creation
     */
    public function check_permission_question($force = false) {

        // get all existing questions
        if (!$force) {
            $q = AIR2_Query::create()->from('Question q');
            $q->where('q.ques_inq_id = ?', $this->inq_id);
            $q->andWhere('q.ques_public_flag = 1');
            $q->andWhereNotIn(
                'q.ques_type',
                array(
                    Question::$TYPE_CONTRIBUTOR,
                    Question::$TYPE_PERMISSION_HIDDEN,
                    Question::$TYPE_PERMISSION,
                    Question::$TYPE_PICK_COUNTRY,
                    Question::$TYPE_PICK_STATE
                )
            );

            $count = $q->count();
        }

        if (($force || $count)) {
            $permq = $this->_fetch_permission_question();

            if (!$permq && !$this->_has_permission_question) {

                // doctrine doesn't seem to notice the question below right away
                // this is a backstop to prevent adding duplicates
                $this->_has_permission_question = true;

                $question = new Question();
                $question->ques_inq_id = $this->inq_id;
                $question->ques_dis_seq = 99;
                $template = Question::$TKEY_PERMISSION;

                AIR2_QueryBuilder::make_question($question, $template);

                // save question
                $question->save();
            }

            // update flag on this inquiry if necessary
            if (!$this->inq_public_flag) {
                $this->inq_public_flag = 1;
                $this->save();
            }

        }
        elseif (!$count && $this->inq_type == self::$TYPE_FORMBUILDER) {
            // legacy queries allowed to have permission question
            // with no accompanying public questions.
            // so no-op here. See redmine #7785
        }
        else {
            $permq = $this->_fetch_permission_question();
            if ($permq) {
                $permq->delete();

                // update flag on this inquiry if necessary
                if ($this->inq_public_flag) {
                    $this->inq_public_flag = 0;
                    $this->save();
                }
            }
        }
    }


    /**
     * fetch the permission question if it exists.
     *
     * @return unknown
     */
    protected function _fetch_permission_question() {
        $q = AIR2_Query::create()->from('Question q');
        $q->where('q.ques_inq_id = ?', $this->inq_id);
        $q->andWhereIn(
            'q.ques_type',
            array(
                Question::$TYPE_PERMISSION_HIDDEN,
                Question::$TYPE_PERMISSION,
            )
        );

        return $q->fetchOne();
    }


    /**
     * Returns number of published submissions.
     *
     * @return integer count of published submissions
     */
    public function has_published_submissions() {
        // SQL comes from Perl AIR2::PublicSrcResponseSet
        $sql =  'select count(distinct srs_id) ';
        $sql .= 'from src_response_set,inquiry,src_response ';
        $sql .= 'where srs_inq_id=inq_id and srs_id=sr_srs_id and srs_public_flag=1 and inq_public_flag=1 and srs_id in ';
        $sql .= '(select sr_srs_id from src_response where sr_public_flag=1 and sr_ques_id in ';
        $sql .= '(select ques_id from question where ques_public_flag=1)';
        $sql .= ') and inq_id=?';

        $conn = AIR2_DBManager::get_connection();
        $count = $conn->fetchOne($sql, array($this->inq_id), 0);
        return $count;
    }


    /**
     * Returns number of submissions to this Inquiry.
     *
     * @return integer number of submissions
     */
    public function has_submissions() {
        $sql = "select count(*) from src_response_set where srs_inq_id = ?";
        $conn = AIR2_DBManager::get_connection();
        return $conn->fetchOne($sql, array($this->inq_id), 0);
    }





    /**
     * Return array of all published Inquiries. Useful for pan-PIN RSS feed.
     *
     * @param integer $limit (optional) default is 100
     * @return array of Inquiry objects
     */
    public static function get_all_published_rss($limit=100) {

        // make sure we have an integer
        if (!isset($limit)) {
            $limit = 100;
        }

        $q = self::get_base_query_for_published();
        $q->addWhere('i.inq_rss_status = ?', 'Y');
        if ($limit) {
            $q->limit($limit);
        }
        $q->orderBy('i.inq_publish_dtim desc');

        return $q->execute();

    }


    /**
     * Returns AIR2_Query object for published Inquiries.
     *
     * @param string  $class (optional)
     * @return AIR2_Query $q
     */
    public static function get_base_query_for_published($class='Inquiry') {
        $now = air2_date();
        $q = AIR2_Query::create()
        ->from("$class i")
        ->whereIn("i.inq_type", array('F', 'Q', 'T'))
        ->andWhereIn('i.inq_status', Inquiry::published_status_flags())
        ->andWhere("(i.inq_publish_dtim is null OR i.inq_publish_dtim <= '$now')")
        ->andWhere("(i.inq_expire_dtim is null OR i.inq_expire_dtim > '$now')")
        ->andWhere("(i.inq_deadline_dtim is null OR i.inq_deadline_dtim > '$now')");

        return $q;

    }


    /**
     * Returns array of User objects who are Authors.
     *
     * @return array Users
     */
    public function get_authors() {
        $authors = array();
        foreach ($this->Author as $iu) {
            if ($iu->iu_type != InquiryUser::$TYPE_AUTHOR) {
                continue;
            }
            $authors[] = $iu->User;
        }
        return $authors;
    }


    /**
     * Returns array of User objects who are Watchers.
     *
     * @return array Users
     */
    public function get_watchers() {
        $watchers = array();
        foreach ($this->Watcher as $iu) {
            if ($iu->iu_type != InquiryUser::$TYPE_WATCHER) {
                continue;
            }
            $watchers[] = $iu->User;
        }
        return $watchers;
    }


    /**
     * Override basic exception string handling to make it friendlier for browser.
     *
     * @return unknown
     */
    public function getErrorStackAsString() {
        $errorStack = $this->getErrorStack();

        if (count($errorStack)) {
            $message = sprintf("Validation failed for Inquiry {$this->inq_ext_title}<br /><br /><br />", get_class($this));

            $message .= "  " . count($errorStack) . " field" . (count($errorStack) > 1 ?  's' : null) . " had validation error" . (count($errorStack) > 1 ?  's' : null) . ":<br /><br /><ul>";
            foreach ($errorStack as $field => $errors) {
                $message .= "    <li> " . count($errors) . " validator" . (count($errors) > 1 ?  's' : null) . " failed on $field (" . implode(", ", $errors) . ")<br /><br /></li>";
                if (count($errorStack) == 1) {
                    $known_fields = array(
                        'Deadline Message',
                        'Expire Message',
                        'Full Description',
                        'Question Value',
                        'Short Description',
                        'Thank You Message',
                    );
                    if (in_array($field, $known_fields)) {
                        $message = $field . ': ' . implode(", ", $errors);
                    }
                    return $message;
                }
            }
            $message .= "</ul>";
            return $message;
        } else {
            return false;
        }
    }


}
