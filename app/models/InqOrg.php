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
 * InqOrg
 *
 * Class to designate Inquiry ownership by Organization.
 *
 * @property integer $iorg_inq_id
 * @property integer $iorg_org_id
 * @property string $iorg_status
 * @property integer $iorg_cre_user
 * @property integer $iorg_upd_user
 * @property timestamp $iorg_cre_dtim
 * @property timestamp $iorg_upd_dtim
 * @property Inquiry $Inquiry
 * @property Organization $Organization
 * @author pkarman
 * @package default
 */
class InqOrg extends AIR2_Record {
    /* UUID column to map into a related table */
    private static $UUID_COL = 'Organization:org_uuid';

    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('inq_org');
        $this->hasColumn('iorg_inq_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('iorg_org_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('iorg_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('iorg_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('iorg_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('iorg_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('iorg_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Inquiry', array(
                'local' => 'iorg_inq_id',
                'foreign' => 'inq_id',
                'onDelete' => 'CASCADE'
            )
        );
        $this->hasOne('Organization', array(
                'local' => 'iorg_org_id',
                'foreign' => 'org_id',
                'onDelete' => 'CASCADE',
            )
        );
        $this->hasOne('ImageOrgLogo as OrgLogo', array(
                'local' => 'iorg_org_id',
                'foreign' => 'img_xid',
            )
        );

    }





    /**
     * Override save() to workaround Doctrine bug in cascading save().
     *
     * @return parent::save()
     */
    public function save() {
        if (!$this->iorg_org_id) {
            throw new Exception("iorg_org_id not set");
        }
        return parent::save();
    }


    /**
     * Get the mapped-uuid column for this table
     *
     * @return string
     */
    public function get_uuid_col() {
        return InqOrg::$UUID_COL;
    }


    /**
     * Change the side from which this table is accessed.  For instance, to
     * access from "Inquiry->InqOrg", you would call change_uuid_col(false).
     * To access from "Organization->InqOrg", pass in true.
     *
     * @param boolean $is_org_side
     */
    public static function change_uuid_col($is_org_side) {
        if ($is_org_side)
            InqOrg::$UUID_COL = 'Inquiry:inq_uuid';
        else
            InqOrg::$UUID_COL = 'Organization:org_uuid';
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
        if (InqOrg::$UUID_COL == 'Inquiry:inq_uuid')
            $mod = 'Inquiry';

        // make sure "Organization" or "Inquiry" is part of the query
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
                    $str = "(".$a."inq_title LIKE ? OR ".$a."inq_ext_title LIKE ?)";
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
     * Inherit from Organization
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        return $this->Organization->user_may_read($user);
    }


    /**
     * Inherit from Organization
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        return $this->Organization->user_may_write($user);
    }


    /**
     * Inherit from Organization
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        return $this->Organization->user_may_manage($user);
    }



    /**
     * May delete only if it is not the last Org for the Inquiry.
     *
     * @param unknown $user
     * @return unknown
     */
    public function user_may_delete($user) {
        $iorgs = count($this->Inquiry->InqOrg);
        $ret = $this->user_may_manage($user);
        if ($ret && $iorgs > 1) {
            return $ret;
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Inherit from Organization
     *
     * @param AIR2_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     * @return unknown
     */
    public static function query_may_read(AIR2_Query $q, User $u, $alias=null) {
        if ($u->is_system()) {
            return;
        }
        return Organization::query_may_read($q, $u, $alias);
    }


}
