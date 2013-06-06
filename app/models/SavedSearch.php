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
 * Saved Search
 *
 * Serialized search parameters, public or private.
 *
 * @property integer   $ssearch_id
 * @property string    $ssearch_uuid
 * @property string    $ssearch_name
 * @property boolean   $ssearch_shared_flag
 * @property string    $ssearch_params
 * @property integer   $ssearch_cre_user
 * @property integer   $ssearch_upd_user
 * @property timestamp $ssearch_cre_dtim
 * @property timestamp $ssearch_upd_dtim
 * @property Doctrine_Collection $Projects
 * @author pkarman
 * @package default
 */
class SavedSearch extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('saved_search');
        $this->hasColumn('ssearch_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            )
        );
        $this->hasColumn('ssearch_name', 'string', 255, array(
                'notnull' => true,
                'default' => 'My Search',
                'unique'  => true,
            )
        );
        $this->hasColumn('ssearch_shared_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => 0,
            )
        );
        $this->hasColumn('ssearch_params', 'string', null, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('ssearch_cre_user', 'integer', 4, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('ssearch_upd_user', 'integer', 4, array(

            )
        );
        $this->hasColumn('ssearch_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            )
        );
        $this->hasColumn('ssearch_upd_dtim', 'timestamp', null, array(

            )
        );
        $this->hasColumn('ssearch_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            )
        );

        parent::setTableDefinition();
    }



    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();

        $this->hasMany('ProjectSavedSearch as Projects', array(
                'foreign' => 'pss_ssearch_id',
                'local' => 'ssearch_id'
            )
        );
    }



    /**
     * Add projects to this SavedSearch
     *
     * @param array   $projects
     */
    public function add_projects(array $projects) {
        foreach ($projects as $p) {
            $pss = new ProjectSavedSearch();
            $pss->pss_prj_id    = $p->prj_id;
            $pss->pss_ssearch_id = $this->ssearch_id;
            $this->Projects[] = $pss;
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
        $str = "(".$a."ssearch_name LIKE ? )";
        $q->addWhere($str, array("%$search%"));
    }


    /**
     * Apply authz rules for who may view the existence of a Saved Search.
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

        // owner or shared
        $shared = "{$a}ssearch_shared_flag = 1";
        $owner = "{$a}ssearch_cre_user = ".$u->user_id;
        $q->addWhere("($owner or $shared)");
    }


    /**
     * Apply authz rules for who may view the existence of a Saved Search.
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
        $q->addWhere("{$a}ssearch_cre_user = ?", $u->user_id);
    }


    /**
     * Same as writing
     *
     * @param unknown $q
     * @param unknown $u
     * @param unknown $alias (optional)
     * @return unknown
     */
    public static function query_may_manage(AIR2_Query $q, User $u, $alias=null) {
        return self::query_may_write($q, $u, $alias);
    }


    /**
     * Return org_ids associated with this SavedSearch's Projects
     *
     * @return array $org_ids
     */
    private function _get_proj_org_ids() {
        $proj_org_ids = array();
        $projects = $this->Projects;
        foreach ($projects as $pss) {
            $proj_org_ids = array_merge($proj_org_ids, $pss->Project->get_authz());
        }
        return $proj_org_ids;
    }


    /**
     * Must be owner or able to read a shared project
     *
     * @param User    $user
     * @return integer
     */
    public function user_may_read($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        if ($this->ssearch_cre_user == $user->user_id) {
            return AIR2_AUTHZ_IS_OWNER;
        }
        if ($this->ssearch_shared_flag) {
            return AIR2_AUTHZ_IS_PUBLIC;
        }

        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Must be owner to write to existing SavedSearch.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        if (!$this->exists()) {
            return AIR2_AUTHZ_IS_NEW;
        }
        if ($this->ssearch_cre_user == $user->user_id) {
            return AIR2_AUTHZ_IS_OWNER;
        }

        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Calls user_may_write().
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        return $this->user_may_write($user);
    }


    /**
     * Setup new ProjectSavedSearch.
     *
     * NOTE: this is temporary, until we can explicitly set Projects in the
     * SavedSearch UI.
     *
     * @param Doctrine_Event $event
     */
    public function preValidate($event) {
        parent::preValidate($event);

        // only create if there are no projects
        if (!$this->exists() && $this->Projects->count() == 0) {
            $u = Doctrine::getTable('User')->find($this->ssearch_cre_user);
            $prj_id = ($u) ? $u->find_default_prj_id() : null;

            if ($prj_id) {
                $pss = new ProjectSavedSearch();
                $pss->pss_prj_id = $prj_id;
                $this->Projects[] = $pss;
            }
        }
    }


}
