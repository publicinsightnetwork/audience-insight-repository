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
 * ProjectInquiry
 *
 * Inquiries that were created under a project
 *
 * @property integer $pinq_prj_id
 * @property integer $pinq_inq_id
 * @property string $pinq_status
 * @property integer $pinq_cre_user
 * @property integer $pinq_upd_user
 * @property timestamp $pinq_cre_dtim
 * @property timestamp $pinq_upd_dtim
 * @property Project $Project
 * @property Inquiry $Inquiry
 * @author rcavis
 * @package default
 */
class ProjectInquiry extends AIR2_Record {
    /* UUID column to map into a related table */
    private static $UUID_COL = 'Inquiry:inq_uuid';

    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';
    public static $STATUS_CONFLICT = 'C'; /* AIR1 conversion conflicts */

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('project_inquiry');
        $this->hasColumn('pinq_prj_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('pinq_inq_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('pinq_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('pinq_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('pinq_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('pinq_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('pinq_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Project', array(
                'local' => 'pinq_prj_id',
                'foreign' => 'prj_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('Inquiry', array(
                'local' => 'pinq_inq_id',
                'foreign' => 'inq_id',
                'onDelete' => 'CASCADE'
            ));
    }


    /**
     * Get the mapped-UUID column for this model
     *
     * @return string
     */
    public function get_uuid_col() {
        return ProjectInquiry::$UUID_COL;
    }


    /**
     * Change the side from which this table is accessed.
     *
     * @param boolean $is_inq_side
     */
    public static function change_uuid_col($is_inq_side) {
        if ($is_inq_side)
            ProjectInquiry::$UUID_COL = 'Project:prj_uuid';
        else
            ProjectInquiry::$UUID_COL = 'Inquiry:inq_uuid';
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
        // make sure "Inquiry" is part of the query
        $from_parts = $q->getDqlPart('from');
        foreach ($from_parts as $string_part) {
            if ($match = strpos($string_part, "$alias.Inquiry")) {
                $offset = strlen("$alias.Inquiry") + 1; // remove space
                $inq_alias = substr($string_part, $match + $offset);
                $a = ($inq_alias) ? "$inq_alias." : "";
                $str = "(".$a."inq_title LIKE ?)";
                if ($useOr) {
                    $q->orWhere($str, array("$search%"));
                }
                else {
                    $q->addWhere($str, array("$search%"));
                }
                break;
            }
        }
    }


    /**
     * Inherit from Inquiry
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        return $this->Inquiry->user_may_read($user);
    }


    /**
     * Inherit from Inquiry
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        return $this->Inquiry->user_may_write($user);
    }


    /**
     * Inherit from Inquiry
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        return $this->Inquiry->user_may_manage($user);
    }


    /**
     * May delete only if it is not the last project for the inquiry.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_delete($user) {
        $pinqs = count($this->Inquiry->ProjectInquiry);
        $ret = $this->user_may_manage($user);
        if ($ret && $pinqs > 1) {
            return $ret;
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


}
