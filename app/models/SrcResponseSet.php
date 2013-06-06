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
 * SrcResponseSet
 *
 * Responses by a Source to an Inquiry
 *
 * @property integer $srs_id
 * @property string $srs_uuid
 * @property integer $srs_src_id
 * @property integer $srs_inq_id
 * @property timestamp $srs_date
 * @property string $srs_uri
 * @property string $srs_type
 * @property boolean $srs_public_flag
 * @property boolean $srs_delete_flag
 * @property boolean $srs_translated_flag
 * @property boolean $srs_export_flag
 * @property boolean $srs_approved_flag
 * @property integer $srs_loc_id
 * @property string $srs_conf_level
 * @property string $srs_city
 * @property string $srs_state
 * @property string $srs_country
 * @property string $srs_county
 * @property float $srs_lat
 * @property float $srs_long
 * @property integer $srs_cre_user
 * @property integer $srs_upd_user
 * @property timestamp $srs_cre_dtim
 * @property timestamp $srs_upd_dtim
 * @property Source $Source
 * @property Inquiry $Inquiry
 * @property Locale $Locale
 * @property Doctrine_Collection $SrcResponse
 * @property Doctrine_Collection $SrsAnnotation
 * @property Doctrine_Collection $UserSrs
 * @author rcavis
 * @package default
 */
class SrcResponseSet extends AIR2_Record {
    /* code_master values */
    public static $TYPE_FORMBUILDER = 'F';
    public static $TYPE_QUERYMAKER = 'Q';
    public static $TYPE_MANUAL_ENTRY = 'E';
    public static $TYPE_COMMENT = 'C';
    public static $CONF_HIGH = 'H';
    public static $CONF_LOW = 'L';
    public static $CONF_NOT = 'N';

    /* should we log manual-entry submissions? */
    public static $LOG_MANUAL_ENTRY = false;

    /* publish statuses */
    const PUBLISHABLE         = 1;
    const NOTHING_TO_PUBLISH  = 2;
    const UNPUBLISHED_PRIVATE = 3;
    const PUBLISHED           = 4;
    const UNPUBLISHABLE       = 5;

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_response_set');
        $this->hasColumn('srs_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('srs_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            )
        );
        $this->hasColumn('srs_src_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('srs_inq_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('srs_date', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('srs_uri', 'string', null, array(

            ));
        $this->hasColumn('srs_xuuid', 'string', 255, array(

            ));
        $this->hasColumn('srs_city', 'string', 128, array());
        $this->hasColumn('srs_state', 'string', 2, array());
        $this->hasColumn('srs_country', 'string', 2, array());
        $this->hasColumn('srs_county', 'string', 128, array());
        $this->hasColumn('srs_lat', 'float', null, array());
        $this->hasColumn('srs_long', 'float', null, array());
        $this->hasColumn('srs_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$TYPE_FORMBUILDER,
            ));
        $this->hasColumn('srs_public_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('srs_delete_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('srs_translated_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('srs_export_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('srs_fb_approved_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('srs_loc_id', 'integer', 4, array(
                'default' => 52, /* en_US -- see Locale.yml */
                'notnull' => true,
            ));
        $this->hasColumn('srs_conf_level', 'string', 1, array(
                'fixed' => true,
            ));
        $this->hasColumn('srs_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('srs_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('srs_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('srs_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'srs_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('Inquiry', array(
                'local' => 'srs_inq_id',
                'foreign' => 'inq_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasMany('SrcResponse', array(
                'local' => 'srs_id',
                'foreign' => 'sr_srs_id'
            ));
        $this->hasMany('SrsAnnotation', array(
                'local' => 'srs_id',
                'foreign' => 'srsan_srs_id'
            ));
        $this->hasOne('Locale', array(
                'local' => 'srs_loc_id',
                'foreign' => 'loc_id'
            ));
        $this->hasMany('UserSrs', array(
                'local' => 'srs_id',
                'foreign' => 'usrs_srs_id',
            ));

        // Tagging
        $this->hasMany('TagResponseSet as Tags', array(
                'local' => 'srs_id',
                'foreign' => 'tag_xid'
            ));

        // Visiting.
        $this->hasMany(
            "UserVisitSrs",
            array(
                'local' => 'srs_id',
                'foreign' => 'uv_xid',
            )
        );
    }


    /**
     * Returns array of related Organization org_ids that affect
     * the authorization of the SrcResponseSet.
     *
     * @param boolean $include_children
     * @return array   $org_ids
     */
    public function get_authz($include_children=true) {
        $org_ids = array();
        foreach ($this->Inquiry->ProjectInquiry as $pinq) {
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
     * Read authz on srs-inq
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        $authz = $user->get_authz();
        $org_ids = $this->get_authz();
        foreach ($org_ids as $org_id) {
            $role = isset($authz[$org_id]) ? $authz[$org_id] : null;
            if (ACTION_ORG_PRJ_INQ_SRS_READ & $role) {
                return AIR2_AUTHZ_IS_ORG;
            }
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Update authz on srs-inq
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        $authz = $user->get_authz();
        $org_ids = $this->get_authz(false); //NO CHILDREN!
        foreach ($org_ids as $org_id) {
            $role = isset($authz[$org_id]) ? $authz[$org_id] : null;
            if ($this->exists() && ACTION_ORG_PRJ_INQ_SRS_UPDATE & $role) {
                return AIR2_AUTHZ_IS_ORG;
            }
            elseif (!$this->exists() && ACTION_ORG_PRJ_INQ_SRS_CREATE & $role) {
                return AIR2_AUTHZ_IS_ORG;
            }
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Manage authz on srs-inq
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        $authz = $user->get_authz();
        $org_ids = $this->get_authz(false); //NO CHILDREN!
        foreach ($org_ids as $org_id) {
            $role = isset($authz[$org_id]) ? $authz[$org_id] : null;
            if (ACTION_ORG_PRJ_INQ_SRS_DELETE & $role) {
                return AIR2_AUTHZ_IS_ORG;
            }
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Apply authz rules for who may view the existence of a SrcResponseSet.
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
        $rd_org_ids = $u->get_authz_str(ACTION_ORG_PRJ_INQ_SRS_READ, 'porg_org_id', true);
        $prj_ids = "select porg_prj_id from project_org where $rd_org_ids";
        $inq_ids = "select pinq_inq_id from project_inquiry where pinq_prj_id in ($prj_ids)";

        // fetch actual id's, to prevent doctrine from adding its own alias to
        // our columns (pinq fields will get re-aliased by doctrine).
        $conn = AIR2_DBManager::get_connection();
        $rs = $conn->fetchColumn($inq_ids, array(), 0);
        $inq_ids = count($rs) ? implode(',', $rs) : 'NULL';

        // add to query
        $q->addWhere("{$a}srs_inq_id in ($inq_ids)");
    }


    /**
     * Apply authz rules for who may write to a SrcResponseSet.
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

        // writable
        $wt_org_ids = $u->get_authz_str(ACTION_ORG_PRJ_INQ_SRS_UPDATE, 'porg_org_id', true);
        $prj_ids = "select porg_prj_id from project_org where $wt_org_ids";
        $inq_ids = "select pinq_inq_id from project_inquiry where pinq_prj_id in ($prj_ids)";

        // fetch actual id's, to prevent doctrine from adding its own alias to
        // our columns (pinq fields will get re-aliased by doctrine).
        $conn = AIR2_DBManager::get_connection();
        $rs = $conn->fetchColumn($inq_ids, array(), 0);
        $inq_ids = count($rs) ? implode(',', $rs) : 'NULL';

        // add to query
        $q->addWhere("{$a}srs_inq_id in ($inq_ids)");
    }


    /**
     * Apply authz rules for who may manage a SrcResponseSet.
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

        // manageable
        $mg_org_ids = $u->get_authz_str(ACTION_ORG_PRJ_INQ_SRS_DELETE, 'porg_org_id', true);
        $prj_ids = "select porg_prj_id from project_org where $mg_org_ids";
        $inq_ids = "select pinq_inq_id from project_inquiry where pinq_prj_id in ($prj_ids)";

        // fetch actual id's, to prevent doctrine from adding its own alias to
        // our columns (pinq fields will get re-aliased by doctrine).
        $conn = AIR2_DBManager::get_connection();
        $rs = $conn->fetchColumn($inq_ids, array(), 0);
        $inq_ids = count($rs) ? implode(',', $rs) : 'NULL';

        // add to query
        $q->addWhere("{$a}srs_inq_id in ($inq_ids)");
    }


    /**
     * Post-insert hook to log an activity for "manual-entry" submissions.
     * (Can't use regular AIR2Logger, since we need the postInsert xid).
     *
     * @param DoctrineEvent $event
     */
    public function postInsert($event) {
        parent::postInsert($event);

        // only manual-entries, and only if requestion
        if ($this->srs_type != self::$TYPE_MANUAL_ENTRY) {
            return;
        }
        if (!self::$LOG_MANUAL_ENTRY) {
            return;
        }

        // figure out what type of entry this is
        $actm_id = false;
        foreach (Inquiry::$MANUAL_TYPES as $code => $config) {
            if ($this->SrcResponse[0]->sr_orig_value == $config['label']) {
                $actm_id = $config['actm'];
                break;
            }
        }

        // find project id
        $prj_id = false;
        if (count($this->Inquiry->ProjectInquiry) > 0) {
            $prj_id = $this->Inquiry->ProjectInquiry[0]->pinq_prj_id;
        }

        // only log if the type matched something
        if ($actm_id && $prj_id) {
            $sact = new SrcActivity();
            $sact->sact_src_id = $this->srs_src_id;
            $sact->sact_actm_id = $actm_id;
            $sact->sact_prj_id = $prj_id;
            $sact->sact_dtim = $this->srs_date;
            $sact->sact_desc = '{USER} entered {XID} for source {SRC}';
            $sact->sact_notes = null;
            $sact->sact_xid = $this->srs_id;
            $sact->sact_ref_type = SrcActivity::$REF_TYPE_RESPONSE;
            $sact->save();
        }
    }


    /**
     * Returns the constant integer representing the publishable state of the SrcResponseSet.
     *
     * @return int
     */
    public function get_publish_state() {
        $flags = '';
        $inq_public_flag = $this->Inquiry->inq_public_flag;
        $srs_public_flag = $this->srs_public_flag;
        if ($srs_public_flag == 0) {
            $srs_public_flag = 0;
        }
        //Carper::carp($srs_public_flag);

        $responses = $this->SrcResponse;
        $has_public_questions = 0;
        $has_public_responses = 0;
        $permission_response = 'no';
        foreach ($responses as $response) {
            $question               = $response->Question;
            $has_public_questions   += $question->ques_public_flag;
            $has_public_responses   += $response->sr_public_flag;
            if ($question->ques_type == 'p' || $question->ques_type == 'P') {
                if ($response->sr_mod_value != '' && $response->sr_mod_value != null) {
                    $permission_response = strtolower($response->sr_mod_value);
                }
                else {
                    $permission_response = strtolower($response->sr_orig_value);
                }
                $permission_response = preg_replace('/\W/', '', $permission_response);
            }
        }

        $has_public_questions = $has_public_questions ? 1 : 0;
        $has_public_responses = $has_public_responses ? 1 : 0;

        $flagTypes = array($inq_public_flag, $srs_public_flag, $has_public_questions, $has_public_responses);
        $flags = implode(':', $flagTypes);
        $publish_state = self::UNPUBLISHABLE;

        //Carper::carp($flags);
        //Carper::carp($permission_response);

        if ( $flags == '1:1:1:1' and $permission_response == 'yes') {
            $publish_state = self::PUBLISHED;
        }
        elseif ( $flags == '1:0:1:1' and $permission_response == 'yes') {
            $publish_state = self::PUBLISHABLE;
        }
        elseif ( preg_match('/^1:\d:1:0$/', $flags) and $permission_response == 'yes') {
            $publish_state = self::NOTHING_TO_PUBLISH;
        }
        elseif ( preg_match('/^1:\d:1:\d$/', $flags) and $permission_response != 'yes') {
            $publish_state = self::UNPUBLISHED_PRIVATE;
        }

        return $publish_state;
    }


}
