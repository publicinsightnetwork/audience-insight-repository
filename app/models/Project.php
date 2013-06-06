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
 * Project
 *
 * Provides way to group inquiries and collaborate between organizations
 *
 * @property integer $prj_id
 * @property string $prj_uuid
 * @property string $prj_name
 * @property string $prj_display_name
 * @property string $prj_desc
 * @property string $prj_status
 * @property string $prj_type
 * @property integer $prj_cre_user
 * @property integer $prj_upd_user
 * @property timestamp $prj_cre_dtim
 * @property timestamp $prj_upd_dtim
 * @property Doctrine_Collection $ProjectActivity
 * @property Doctrine_Collection $ProjectAnnotation
 * @property Doctrine_Collection $ProjectInquiry
 * @property Doctrine_Collection $ProjectMessage
 * @property Doctrine_Collection $ProjectOrg
 * @property Doctrine_Collection $PrjOutcome
 * @property Doctrine_Collection $SrcActivity
 * @property Doctrine_Collection $OrgDefault
 * @author rcavis
 * @package default
 */
class Project extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_PUBLISHABLE = 'P';
    public static $STATUS_INACTIVE = 'F';
    public static $TYPE_INQUIRY = 'I';
    public static $TYPE_SYSTEM = 'S';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('project');
        $this->hasColumn('prj_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('prj_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('prj_name', 'string', 32, array(
                'notnull' => true,
                'unique'  => true,
                'airvalid' => array(
                    '/^[a-zA-Z0-9\-\_]+$/' => 'Invalid character(s)! Use [A-Za-z0-9], dashes and underscores',
                ),
            ));
        $this->hasColumn('prj_display_name', 'string', 255, array(
                'notnull' => true,
                'unique'  => true,
            ));
        $this->hasColumn('prj_desc', 'string', null, array(

            ));
        $this->hasColumn('prj_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('prj_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$TYPE_INQUIRY,
            ));
        $this->hasColumn('prj_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('prj_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('prj_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('prj_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasMany('ProjectActivity', array(
                'local' => 'prj_id',
                'foreign' => 'pa_prj_id'
            ));
        $this->hasMany('ProjectAnnotation', array(
                'local' => 'prj_id',
                'foreign' => 'prjan_prj_id'
            ));
        $this->hasMany('ProjectInquiry', array(
                'local' => 'prj_id',
                'foreign' => 'pinq_prj_id'
            ));
        $this->hasMany('ProjectMessage', array(
                'local' => 'prj_id',
                'foreign' => 'pm_pj_id'
            ));
        $this->hasMany('ProjectOrg', array(
                'local' => 'prj_id',
                'foreign' => 'porg_prj_id'
            ));
        $this->hasMany('PrjOutcome', array(
                'local' => 'prj_id',
                'foreign' => 'pout_prj_id'
            ));
        $this->hasMany('SrcActivity', array(
                'local' => 'prj_id',
                'foreign' => 'sact_prj_id'
            ));

        // Tagging
        $this->hasMany('TagProject as Tags', array(
                'local' => 'prj_id',
                'foreign' => 'tag_xid'
            )
        );

        // Organization this project is default for (optional)
        $this->hasMany('Organization as OrgDefault', array(
                'local' => 'prj_id',
                'foreign' => 'org_default_prj_id'
            )
        );
    }


    /**
     * Add Organizations to this Project.  Contact users are set as the first
     * manager/writer found in the Organization.
     *
     * @param array   $orgs
     */
    public function add_orgs(array $orgs) {
        foreach ($orgs as $org) {
            $po = new ProjectOrg();
            $po->porg_org_id    = $org->org_id;
            $po->porg_status    = ProjectOrg::$STATUS_ACTIVE;
            $po->porg_contact_user_id = 1; // default
            // get the first related user who can writer and make them the contact.
            foreach ($org->UserOrg as $uo) {
                $mask = AdminRole::to_bitmask($uo->uo_ar_id);
                if ($mask & ACTION_ORG_PRJ_BE_CONTACT) {
                    $po->porg_contact_user_id = $uo->uo_user_id;
                }
            }
            $this->ProjectOrg[] = $po;
        }
    }


    /**
     * Returns array of related Organization org_ids that affect
     * the authorization of the Project.
     *
     * @return array $org_ids
     */
    public function get_authz() {
        $org_ids = array();
        foreach ($this->ProjectOrg as $porg) {
            $children = Organization::get_org_children($porg->porg_org_id);
            foreach ($children as $org_id) {
                $org_ids[$org_id] = 1;
            }
        }
        return array_keys($org_ids);
    }


    /**
     * Readable if member org reader
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // look read authz in related organization
        $user_authz = $user->get_authz();
        $prj_org_ids = $this->get_authz();
        foreach ($prj_org_ids as $org_id) {
            $role = isset($user_authz[$org_id]) ? $user_authz[$org_id] : null;
            if (ACTION_ORG_PRJ_READ & $role) {
                return AIR2_AUTHZ_IS_ORG;
            }
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Writable if User is writer in a member Organization.  UNLIKE reading,
     * writing to an Org requires User WRITE role of an explicit ProjectOrg.
     *
     * This effectively prevents a WRITER from writing to a project belonging
     * to their parent org.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // abort early if cannot read
        if (!$this->user_may_read($user)) {
            return AIR2_AUTHZ_IS_DENIED;
        }

        // only SYSTEM user may change prj_name (requires IT actions)
        $mod_flds = $this->getModified();
        if ($this->exists() && array_key_exists('prj_name', $mod_flds)) {
            return AIR2_AUTHZ_IS_DENIED;
        }

        // look for update authz in EXPLICIT organization
        $authz = $user->get_authz();
        foreach ($this->ProjectOrg as $po) {
            $role = isset($authz[$po->porg_org_id]) ? $authz[$po->porg_org_id] : 0;
            if ($this->exists() && (ACTION_ORG_PRJ_UPDATE & $role)) {
                return AIR2_AUTHZ_IS_ORG;
            }
            elseif (!$this->exists() && (ACTION_ORG_PRJ_CREATE & $role)) {
                return AIR2_AUTHZ_IS_ORG;
            }
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Manageable if User is a contact user for this Project, or if User is
     * a MANAGER in an EXPLICITLY-related Org.
     *
     * This effectively prevents a MANAGER from managing a project belonging to
     * their parent org.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // check contact_users
        foreach ($this->ProjectOrg as $porg) {
            if ($porg->porg_contact_user_id == $user->user_id) {
                return AIR2_AUTHZ_IS_MANAGER;
            }
        }

        // look for MANAGER role in EXPLICIT organization
        $authz = $user->get_authz();
        foreach ($this->ProjectOrg as $po) {
            if ($po->porg_status == ProjectOrg::$STATUS_ACTIVE) {
                $org_id = $po->porg_org_id;
                $role = isset($authz[$org_id]) ? $authz[$org_id] : 0;
                if (ACTION_ORG_PRJ_DELETE & $role) {
                    return AIR2_AUTHZ_IS_ORG;
                }
            }
        }

        // not a contact_user or manager
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Apply authz rules for who may view the existence of a Project.
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

        // is current user in an org related to this project?
        // NOTE: this will CASCADE UP the org tree, so we don't have to try
        // caching explicit prj_orgs, or something crazy
        $org_ids = $u->get_authz_str(ACTION_ORG_PRJ_READ, 'porg_org_id', true);
        $prj_ids = "select porg_prj_id from project_org where $org_ids";
        $q->addWhere("{$a}prj_id in ($prj_ids)");
    }


    /**
     * Apply authz rules for who may write to a Project.
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

        // look for related writers, but do NOT cascade-up!
        $org_ids = $u->get_authz_str(ACTION_ORG_PRJ_UPDATE, 'porg_org_id', false);
        $prj_ids = "select porg_prj_id from project_org where $org_ids";
        $q->addWhere("{$a}prj_id in ($prj_ids)");
    }


    /**
     * Apply authz rules for who may manage a Project.
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

        // is user contact_user for this project
        $user_id = $u->user_id;
        $prj_ids = "select porg_prj_id from project_org where porg_contact_user_id = $user_id";
        $contact_user = "{$a}prj_id in ($prj_ids)";

        // is user MANAGER in an org related to this project
        $org_ids = $u->get_authz_str(ACTION_ORG_PRJ_DELETE, 'porg_org_id', false);
        $prj_ids = "select porg_prj_id from project_org where $org_ids";
        $manager = "{$a}prj_id in ($prj_ids)";

        // add complete where condition
        $q->addWhere("($contact_user or $manager)");
    }


    /**
     * Gets (or creates, if DNE) the manual-input inquiry associated with this
     * particular project.  This is used to manually enter source responses for
     * things like emails and phone calls.
     *
     * @return Inquiry
     */
    public function get_manual_entry_inquiry() {
        $me_uuid = air2_str_to_uuid('me-'.$this->prj_name);
        $inq = AIR2_Record::find('Inquiry', $me_uuid);

        if (!$inq) {
            $inq = Inquiry::make_manual_entry();
            $inq->inq_uuid = $me_uuid;
            $inq->add_projects(array($this));
            $orgs = array();
            foreach ($this->ProjectOrg as $porg) {
                $orgs[] = $porg->Organization;
            }
            $inq->add_orgs($orgs);
            $inq->save();
        }
        return $inq;
    }


    /**
     * Add custom search query (from the get param 'q')
     *
     * @return unknown
     * @param AIR2_Query $q
     * @param string  $alias
     * @param string  $search
     * @param boolean $useOr
     */
    public static function add_search_str(&$q, $alias, $search, $useOr=null) {
        $a = ($alias) ? "$alias." : "";
        $str = "({$a}prj_name LIKE ? OR {$a}prj_display_name LIKE ?)";
        if ($useOr) {
            $q->orWhere($str, array("%$search%", "$search%"));
        }
        else {
            $q->addWhere($str, array("%$search%", "$search%"));
        }
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
         * Clear the project's RSS feed cache.
         */

        if (file_exists($this->get_rss_cache_path())) {
            unlink( $this->get_rss_cache_path() );
        }


        /*
         * Clear the RSS feed cache for all projects.
         */
        if (file_exists( self::get_combined_rss_cache_path() ) ) {
            unlink( self::get_combined_rss_cache_path() );
        }
    }


    /**
     * Returns the absolute file path to the cached RSS feed file.
     *
     * @return $rss_feed_path
     */
    public function get_rss_cache_path() {
        if (!is_dir(AIR2_RSS_CACHE_ROOT . '/project')) {
            air2_mkdir(AIR2_RSS_CACHE_ROOT . '/project');
        }
        return sprintf("%s/project/%s.rss", AIR2_RSS_CACHE_ROOT, $this->prj_name);
    }


    /**
     * Returns the absolute fiel path to the cached RSS feed for all projects.
     *
     * @return $rss_feed_path
     */
    public static function get_combined_rss_cache_path() {
        return sprintf("%s/project.rss", AIR2_RSS_CACHE_ROOT);
    }



    /**
     * Returns array of Inquiry records that comprise the RSS feed
     * for this Project.
     *
     * @param integer $limit (optional) default is 100
     * @return unknown
     */
    public function get_inquiries_in_rss_feed($limit=100) {

        // make sure we have an integer
        if (!isset($limit)) {
            $limit = 100;
        }

        $q = Inquiry::get_base_query_for_published();
        $q->innerJoin('i.ProjectInquiry pi');
        $q->innerJoin('pi.Project p');
        $q->andWhereIn('pi.pinq_status', array('A'));
        $q->andWhere('i.inq_rss_status = ?', 'Y');
        $q->andWhere('p.prj_id = ?', $this->prj_id);
        if ($limit) {
            $q->limit($limit);
        }
        $q->orderBy('i.inq_publish_dtim desc');

        return $q->execute();

    }


    /**
     *
     *
     * @return unknown
     */
    public function is_active() {
        $status = $this->prj_status;
        if ($status == self::$STATUS_ACTIVE
            || $status == self::$STATUS_PUBLISHABLE
        ) {
            return true;
        }
        return false;
    }


}
