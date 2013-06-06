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
 * ProjectOrg
 *
 * Class to relate Projects to Organizations
 *
 * @property integer $porg_prj_id
 * @property integer $porg_org_id
 * @property integer $porg_contact_user_id
 * @property string $porg_status
 * @property integer $porg_cre_user
 * @property integer $porg_upd_user
 * @property timestamp $porg_cre_dtim
 * @property timestamp $porg_upd_dtim
 * @property Project $Project
 * @property Organization $Organization
 * @property User $ContactUser
 * @author rcavis
 * @package default
 */
class ProjectOrg extends AIR2_Record {
    /* UUID column to map into a related table */
    private static $UUID_COL = 'Organization:org_uuid';

    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('project_org');
        $this->hasColumn('porg_prj_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('porg_org_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('porg_contact_user_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('porg_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('porg_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('porg_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('porg_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('porg_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Project', array(
                'local' => 'porg_prj_id',
                'foreign' => 'prj_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('Organization', array(
                'local' => 'porg_org_id',
                'foreign' => 'org_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('User as ContactUser', array(
                'local' => 'porg_contact_user_id',
                'foreign' => 'user_id',
                'onDelete' => 'CASCADE'
            ));
    }


    /**
     * Get the mapped-uuid column for this table
     *
     * @return string
     */
    public function get_uuid_col() {
        return ProjectOrg::$UUID_COL;
    }


    /**
     * Change the side from which this table is accessed.  For instance, to
     * access from "Project->ProjectOrg", you would call change_uuid_col(false).
     * To access from "Organization->ProjectOrg", pass in true.
     *
     * @param boolean $is_org_side
     */
    public static function change_uuid_col($is_org_side) {
        if ($is_org_side)
            ProjectOrg::$UUID_COL = 'Project:prj_uuid';
        else
            ProjectOrg::$UUID_COL = 'Organization:org_uuid';
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
        $mod = 'Organization';
        if (ProjectOrg::$UUID_COL == 'Project:prj_uuid')
            $mod = 'Project';

        // make sure "Organization" or "Project" is part of the query
        $from_parts = $q->getDqlPart('from');
        foreach ($from_parts as $string_part) {
            if ($match = strpos($string_part, "$alias.$mod")) {
                $offset = strlen("$alias.$mod") + 1; // remove space
                $org_alias = substr($string_part, $match + $offset);
                $a = ($org_alias) ? "$org_alias." : "";

                if ($mod == 'Organization') {
                    $str = "(".$a."org_name LIKE ? OR ".$a."org_display_name LIKE ?)";
                }
                else {
                    $str = "(".$a."prj_name LIKE ? OR ".$a."prj_desc LIKE ?)";
                }

                if ($useOr) {
                    $q->orWhere($str, array("%$search%", "%$search%"));
                }
                else {
                    $q->addWhere($str, array("%$search%", "%$search%"));
                }
                break;
            }
        }
    }


    /**
     * Inherit from Project
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        return $this->Project->user_may_read($user);
    }


    /**
     * Inherit from Project
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        return $this->Project->user_may_write($user);
    }


    /**
     * Inherit from Project
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        return $this->Project->user_may_manage($user);
    }



    /**
     * May delete only if it is not the last Org for the Project.
     * See Trac #1539.
     *
     * @param unknown $user
     * @return unknown
     */
    public function user_may_delete($user) {
        $porgs = count($this->Project->ProjectOrg);
        $ret = $this->user_may_manage($user);
        if ($ret && $porgs > 1) {
            return $ret;
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Inherit from Project
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

        // readable projects
        $tmp = AIR2_Query::create();
        Project::query_may_read($tmp, $u);
        $tmp = array_pop($tmp->getDqlPart('where'));
        $prj_ids = "select prj_id from project where $tmp";

        // fetch actual id's, to prevent doctrine from adding its own alias to
        // our columns (porg fields will get re-aliased by doctrine).
        $conn = AIR2_DBManager::get_connection();
        $rs = $conn->fetchColumn($prj_ids, array(), 0);
        $prj_ids = count($rs) ? implode(',', $rs) : 'NULL';

        $q->addWhere("{$a}porg_prj_id in ($prj_ids)");
    }


}
