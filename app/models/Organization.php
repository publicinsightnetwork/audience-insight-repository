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
 * Organization
 *
 * A collection of AIR2 Users, for the purpose of assigning permissions
 *
 * @property integer   $org_id
 * @property integer   $org_parent_id
 * @property integer   $org_default_prj_id
 * @property string    $org_uuid
 * @property string    $org_name
 *
 * @property string    $org_display_name
 * @property string    $org_summary
 * @property string    $org_desc
 * @property string    $org_city
 * @property string    $org_state
 *
 * @property string    $org_site_uri
 * @property string    $org_logo_uri
 * @property string    $org_html_color
 *
 * @property string    $org_type
 * @property string    $org_status
 * @property integer   $org_max_users
 *
 * @property integer   $org_cre_user
 * @property integer   $org_upd_user
 * @property timestamp $org_cre_dtim
 * @property timestamp $org_upd_dtim
 *
 * @property Organization        $parent
 * @property Project             $DefaultProject
 * @property Image               $Banner
 * @property Image               $Logo
 * @property Doctrine_Collection $OrgSysId
 * @property Doctrine_Collection $ProjectOrg
 * @property Doctrine_Collection $SrcOrg
 * @property Doctrine_Collection $SrcPrefOrg
 * @property Doctrine_Collection $UserOrg
 * @property Doctrine_Collection $children
 * @property Doctrine_Collection $Outcome
 * @property Doctrine_Collection $OrgUri
 *
 * @author  rcavis
 * @package default
 */
class Organization extends AIR2_Record {

    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_PUBLISHABLE = 'P';
    public static $STATUS_GUEST  = 'G';
    public static $STATUS_INACTIVE = 'F';
    public static $TYPE_NEWSROOM = 'N';
    public static $TYPE_LJC = 'L';

    /* APM PIN org ID (should never change) */
    public static $APMPIN_ORG_ID = 1;
    public static $GLOBALPIN_ORG_ID = 44;

    /* flag to trigger creation of default project */
    public static $CREATE_DEFAULT_PRJ = true;

    /* cached static org-depth map */
    public static $ORG_MAP;
    protected static $ORG_LEVELS;
    protected static $ORG_CHILDREN;


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('organization');

        // identifiers and foreign keys
        $this->hasColumn('org_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('org_parent_id', 'integer', 4, array());
        $this->hasColumn('org_default_prj_id', 'integer', 4, array(
                'notnull' => true,
                'default' => 1, //system default project (see fixtures)
            ));
        $this->hasColumn('org_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('org_name', 'string', 32, array(
                'notnull' => true,
                'unique' => true,
                'airvalid' => array(
                    '/^[a-zA-Z0-9\-\_]+$/' => 'Invalid character(s)! Use [A-Za-z0-9], dashes and underscores',
                ),
            ));

        // profile info
        $this->hasColumn('org_display_name', 'string', 128,  array());
        $this->hasColumn('org_summary',      'string', 255,  array());
        $this->hasColumn('org_desc',         'string', null, array());
        $this->hasColumn('org_welcome_msg',  'string', null, array());
        $this->hasColumn('org_email',        'string', 255,  array());
        $this->hasColumn('org_address',      'string', 255,  array());
        $this->hasColumn('org_zip',          'string', 32,   array());
        $this->hasColumn('org_city',         'string', 128,  array());
        $this->hasColumn('org_state',        'string', 2,    array(
                'fixed' => true,
            ));

        // assets
        $this->hasColumn('org_logo_uri',   'string', 255, array());
        $this->hasColumn('org_site_uri',   'string', 255, array());
        $this->hasColumn('org_html_color', 'string', 6,   array(
                'fixed'   => true,
                'default' => '777777',
                'notnull' => true,
            ));

        // metadata
        $this->hasColumn('org_type', 'string', 1, array(
                'fixed'   => true,
                'notnull' => true,
                'default' => self::$TYPE_NEWSROOM,
            ));
        $this->hasColumn('org_status', 'string', 1, array(
                'fixed'   => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('org_max_users', 'integer', 4, array(
                'default' => 0, //no more users may be added
            ));

        // stamps
        $this->hasColumn('org_cre_user', 'integer',   4,    array(
                'notnull' => true,
            ));
        $this->hasColumn('org_upd_user', 'integer',   4,    array());
        $this->hasColumn('org_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('org_upd_dtim', 'timestamp', null, array());

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasMany('OrgSysId', array(
                'local' => 'org_id',
                'foreign' => 'osid_org_id'
            ));
        $this->hasMany('InqOrg', array(
                'local' => 'org_id',
                'foreign' => 'iorg_org_id',
            ));
        $this->hasMany('ProjectOrg', array(
                'local' => 'org_id',
                'foreign' => 'porg_org_id',
            ));
        $this->hasMany('SrcOrg', array(
                'local' => 'org_id',
                'foreign' => 'so_org_id'
            ));
        $this->hasMany('SrcOrgEmail', array(
                'local' => 'org_id',
                'foreign' => 'soe_org_id'
            ));
        $this->hasMany('SrcPrefOrg', array(
                'local' => 'org_id',
                'foreign' => 'spo_org_id'
            ));
        $this->hasMany('UserOrg', array(
                'local' => 'org_id',
                'foreign' => 'uo_org_id'
            ));
        $this->hasMany('Outcome', array(
                'local' => 'org_id',
                'foreign' => 'out_org_id'
            ));
        $this->hasMany('OrgUri', array(
                'local' => 'org_id',
                'foreign' => 'ouri_org_id'
            ));
        $this->hasOne('Project as DefaultProject', array(
                'local' => 'org_default_prj_id',
                'foreign' => 'prj_id'
            ));
        // add sub-orgs and parent orgs
        $this->hasOne('Organization as parent', array(
                'local' => 'org_parent_id',
                'foreign' => 'org_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasMany('Organization as children', array(
                'local' => 'org_id',
                'foreign' => 'org_parent_id'
            ));

        // images
        $this->hasOne('ImageOrgBanner as Banner', array(
                'local' => 'org_id',
                'foreign' => 'img_xid',
            ));
        $this->hasOne('ImageOrgLogo as Logo', array(
                'local' => 'org_id',
                'foreign' => 'img_xid',
            ));
    }


    /**
     * Make sure new Organizations get default projects
     *
     * @param Doctrine_Event $event
     */
    public function postInsert($event) {
        if (self::$CREATE_DEFAULT_PRJ && $this->org_default_prj_id == 1 && $this->org_type != 'T') {
            $p = new Project();
            $p->prj_name = air2_urlify($this->org_name);
            $p->prj_display_name = 'Project '.$this->org_display_name;
            $p->prj_desc = 'Default project for organization "'.$this->org_display_name.'"';
            $p->ProjectOrg[0]->porg_org_id = $this->org_id;
            $p->ProjectOrg[0]->porg_contact_user_id = $this->org_cre_user;

            // make sure prj_name is unique
            $count = 0;
            $orig = $p->prj_name;
            $tbl = Doctrine::getTable('Project');
            $name = $tbl->findOneBy('prj_name', $p->prj_name);
            while ($name) {
                $p->prj_name = $orig.'_'.$count;
                $name = $tbl->findOneBy('prj_name', $p->prj_name);
            }

            // save, and make default
            $p->save();
            $this->org_default_prj_id = $p->prj_id;
            $this->save();
        }
        parent::postInsert($event);
    }


    /**
     * Clean up any image assets
     *
     * @param unknown $event
     */
    public function preDelete($event) {
        if ($this->Banner && $this->Banner->exists()) {
            $this->Banner->delete();
        }
        if ($this->Logo && $this->Logo->exists()) {
            $this->Logo->delete();
        }
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
        $str = "(".$a."org_name LIKE ? OR ".$a."org_display_name LIKE ?)";
        if ($useOr) {
            $q->orWhere($str, array("%$search%", "$search%"));
        }
        else {
            $q->addWhere($str, array("%$search%", "$search%"));
        }
    }


    /**
     * Helper function to create UserOrgs
     *
     * @param array   $users
     * @param unknown $role  (optional)
     */
    public function add_users(array $users, $role=2) {
        foreach ($users as $user) {
            $uo = new UserOrg();
            $uo->uo_user_id     = $user->user_id;
            $uo->uo_ar_id       = $role;
            $uo->uo_org_id      = $this->org_id;
            $uo->uo_home_flag   = false;
            $uo->uo_status      = UserOrg::$STATUS_ACTIVE;
            $uo->uo_notify_flag = true;
            $this->UserOrg[] = $uo;
        }
    }


    /**
     * Reading is public
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        return AIR2_AUTHZ_IS_PUBLIC;
    }


    /**
     * Write organization
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // only SYSTEM user may change org_name (requires IT actions)
        $mod_flds = $this->getModified();
        if ($this->exists() && array_key_exists('org_name', $mod_flds)) {
            return AIR2_AUTHZ_IS_DENIED;
        }

        $authz = $user->get_authz();
        $this_authz = array_key_exists($this->org_id, $authz) ? $authz[$this->org_id] : 0;
        $parent_authz = array_key_exists($this->org_parent_id, $authz) ? $authz[$this->org_parent_id] : 0;

        // authz on parent org (if exists) to update org_max_users
        if ($this->exists() && $this->org_parent_id && isset($mod_flds['org_max_users'])) {
            if (!(ACTION_ORG_UPDATE & $parent_authz)) {
                return AIR2_AUTHZ_IS_DENIED;
            }
        }

        // authz on this if exists, otherwise check parent
        if ($this->exists() && ACTION_ORG_UPDATE & $this_authz) {
            return AIR2_AUTHZ_IS_MANAGER;
        }
        elseif (!$this->exists() && ACTION_ORG_CREATE & $parent_authz) {
            return AIR2_AUTHZ_IS_MANAGER;
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Manage organization
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        $authz = $user->get_authz();
        $this_authz = array_key_exists($this->org_id, $authz) ? $authz[$this->org_id] : 0;
        $parent_authz = array_key_exists($this->org_parent_id, $authz) ? $authz[$this->org_parent_id] : 0;
        if ($this->exists() && ACTION_ORG_DELETE & $this_authz) {
            return AIR2_AUTHZ_IS_MANAGER;
        }
        elseif (!$this->exists() && ACTION_ORG_DELETE & $parent_authz) {
            return AIR2_AUTHZ_IS_MANAGER;
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Apply authz rules for who may write to an Organization.
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
        $org_ids = $u->get_authz_str(ACTION_ORG_UPDATE, 'org_id', false);
        $q->addWhere($a.$org_ids);
    }


    /**
     * Apply authz rules for who may manage an Organization
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
        $org_ids = $u->get_authz_str(ACTION_ORG_DELETE, 'org_id', false);
        $q->addWhere($a.$org_ids);
    }


    /**
     * Helper function to cache map of org_id => org_parent_id
     */
    private static function _cache_org_map() {
        $conn = AIR2_DBManager::get_connection();
        $rs = $conn->fetchAll('select org_id, org_parent_id from organization');

        // build map
        $map = array();
        foreach ($rs as $row) $map[$row['org_id']] = $row['org_parent_id'];

        // assign static vars
        self::$ORG_MAP = $map;
        self::$ORG_CHILDREN = false;
        self::$ORG_LEVELS = false;
    }


    /**
     * Clear org-tree maps so they get recalculated on the next call
     */
    public static function clear_org_map() {
        self::$ORG_MAP = false;
        self::$ORG_CHILDREN = false;
        self::$ORG_LEVELS = false;
    }


    /**
     * Retrieve an array of org_ids sorted by depth.
     *   array(
     *     array(<id1>, <id2>), // depth=0
     *     array(<id3>),        // depth=1
     *   );
     *
     * @return array
     */
    public static function get_org_levels() {
        if (!self::$ORG_MAP) {
            self::_cache_org_map();
        }
        if (self::$ORG_LEVELS) {
            return self::$ORG_LEVELS;
        }

        // build levels on the first run
        self::$ORG_LEVELS = array();
        foreach (self::$ORG_MAP as $oid => $pid) {
            $depth = 0;

            // calculate depth
            while ($pid != null) {
                $depth++;
                $pid = self::$ORG_MAP[$pid];
                if ($pid && $pid == self::$ORG_MAP[$pid]) {
                    throw new Exception("ERROR: $pid has recursive parent!");
                }
            }

            // add this org_id at the correct depth
            if (!isset(self::$ORG_LEVELS[$depth])) {
                self::$ORG_LEVELS[$depth] = array();
            }
            self::$ORG_LEVELS[$depth][] = $oid;
        }
        ksort(self::$ORG_LEVELS); // make sure keys are in order
        return self::$ORG_LEVELS;
    }


    /**
     * Get all the descendants of an org_id, including the passed org_id.
     *
     * @param int     $org_id
     * @return array
     */
    public static function get_org_children($org_id) {
        if (!self::$ORG_MAP) {
            self::_cache_org_map();
        }
        if (self::$ORG_CHILDREN && isset(self::$ORG_CHILDREN[$org_id])) {
            return self::$ORG_CHILDREN[$org_id];
        }

        $ids = array($org_id);
        $direct_children = array_keys(self::$ORG_MAP, $org_id);
        foreach ($direct_children as $child_id) {
            $ids = array_merge($ids, self::get_org_children($child_id));
        }
        self::$ORG_CHILDREN[$org_id] = $ids;
        return $ids;
    }


    /**
     * Get all the ancestors of an org_id, NOT including the passed org_id
     *
     * @param int     $org_id
     * @return array
     */
    public static function get_org_parents($org_id) {
        if (!self::$ORG_MAP) {
            self::_cache_org_map();
        }

        $parents = array();
        $parent_id = self::$ORG_MAP[$org_id];
        while ($parent_id != null) {
            $parents[] = $parent_id;
            $parent_id = self::$ORG_MAP[$parent_id];
        }
        return $parents;
    }


    /**
     * Get a true "tree" of all organizations.  It will have the following
     * format:
     *
     * $tree = array(
     *     array(
     *         'org_id' => 12,
     *         'children' => array(
     *             array('org_id' => 13, 'children' => array()),
     *             array('org_id' => 15, 'children' => array()),
     *         ),
     *     ),
     *     array(
     *         'org_id' => 16,
     *         'children' => array(),
     *     ),
     * );
     *
     * @param int     $root_org_id
     * @return array
     */
    public static function get_org_tree($root_org_id=null) {
        if (!self::$ORG_MAP) {
            self::_cache_org_map();
        }

        $tree = array();
        $direct_children = array_keys(self::$ORG_MAP, $root_org_id);
        foreach ($direct_children as $org_id) {
            $tree[] = array(
                'org_id' => $org_id,
                'children' => self::get_org_tree($org_id),
            );
        }
        return $tree;
    }


    /**
     * Helper function to sort an array of some sort by org depth
     *
     * @param array   $array
     * @param string  $orgid_fld (optional)
     * @return array
     */
    public static function sort_by_depth(&$array, $orgid_fld='org_id') {
        $levels = self::get_org_levels();
        $result = array();
        foreach ($levels as $lvl) {
            foreach ($array as $item) {
                if (in_array($item[$orgid_fld], $lvl)) {
                    $result[] = $item;
                }
            }
        }
        return $result;
    }


    /**
     * Determine if an Organization has room for more Users in it.  A negative
     * org_max_users indicates that it can hold unlimited Users.
     *
     * @return boolean
     */
    public function is_full() {
        if ($this->org_max_users < 0) {
            return false; // < 0 == no user limit
        }
        $n = UserOrg::get_user_count($this->org_id);
        return $n >= $this->org_max_users;
    }


    /**
     * Add user counts to an organization query.
     *
     * @param AIR2_Query $q
     * @param char    $alias
     * @param array   $fld_defs (optional, reference)
     */
    public static function add_counts(AIR2_Query $q, $alias=null, &$fld_defs=null) {
        $a = ($alias) ? "$alias." : '';
        $uost = UserOrg::$STATUS_ACTIVE;
        $ust1 = User::$STATUS_ACTIVE;
        $ust2 = User::$STATUS_PUBLISHABLE;

        $active_users = "select user_id from user where user_status " .
            "= '$ust1' or user_status = '$ust2'";
        $c = "select count(*) from user_org where uo_org_id = {$a}org_id " .
            "and uo_status = '$uost' and uo_user_id in ($active_users)";
        $q->addSelect("($c) as active_users");
        if (is_array($fld_defs)) {
            $fld_defs []= array('name' => 'active_users', 'type' => 'int');
        }
    }


    /**
     * Returns number of related active Sources. src_status is factored in,
     * so Sources who are not active in the PIN are not counted.
     *
     * @param boolean $use_cached (optional)
     * @return integer count_of_sources
     */
    public function get_num_sources($use_cached=false) {
        $conn = AIR2_DBManager::get_connection();
        if ($use_cached) {
            $q = "select count(soc_src_id) from src_org_cache, source where soc_src_id=src_id and src_status in ('A','E','T') and soc_status='A' and soc.soc_org_id=".$this->org_id;
        }
        else {
            $q = "select count(so_src_id) from src_org,source where src_status in ('A','E','T') and so_status = 'A' and so_src_id=src_id and so_org_id=".$this->org_id;
        }
        return $conn->fetchOne($q, array(), 0);
    }


    /**
     *
     *
     * @return unknown
     */
    public function is_active() {
        $status = $this->org_status;
        if ($status == self::$STATUS_ACTIVE
            || $status == self::$STATUS_GUEST
            || $status == self::$STATUS_PUBLISHABLE
        ) {
            return true;
        }
        return false;
    }


    /**
     * Returns the absolute file path to the cached RSS feed file.
     *
     * @return $rss_feed_path
     */
    public function get_rss_cache_path() {
        if (!is_dir(AIR2_RSS_CACHE_ROOT . '/org')) {
            air2_mkdir(AIR2_RSS_CACHE_ROOT . '/org');
        }
        return sprintf("%s/org/%s.rss", AIR2_RSS_CACHE_ROOT, $this->org_name);
    }



    /**
     * Returns array of Inquiry records that comprise the RSS feed
     * for this Organization.
     *
     * @param integer $limit         (optional) default is 100
     * @param unknown $ignore_src_id (optional)
     * @param unknown $class         (optional)
     * @return array $inquiries
     */
    public function get_inquiries_in_rss_feed($limit=100, $ignore_src_id=null, $class='Inquiry') {

        // make sure we have an integer
        if (!isset($limit)) {
            $limit = 100;
        }

        $q = Inquiry::get_base_query_for_published($class);
        $q->innerJoin('i.InqOrg io');
        $q->andWhereIn('io.iorg_status', array('A'));
        $q->andWhere('i.inq_rss_status = ?', 'Y');
        $q->andWhere('io.iorg_org_id = ?', $this->org_id);

        if ($ignore_src_id) {
            $q->andWhere("i.inq_id not in (select srs_inq_id from src_response_set where srs_src_id = ?)", $ignore_src_id);
        }

        if ($limit) {
            $q->limit($limit);
        }

        $q->orderBy('i.inq_publish_dtim desc');

        return $q->execute();
    }


}
