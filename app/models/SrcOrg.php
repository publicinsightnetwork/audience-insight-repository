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
 * SrcOrg
 *
 * Organizations that Sources have opted-in with
 *
 * @property integer $so_src_id
 * @property integer $so_org_id
 * @property string $so_uuid
 * @property date $so_effective_date
 * @property boolean $so_home_flag
 * @property boolean $so_lock_flag
 * @property string $so_status
 * @property integer $so_cre_user
 * @property integer $so_upd_user
 * @property timestamp $so_cre_dtim
 * @property timestamp $so_upd_dtim
 * @property Source $Source
 * @property Organization $Organization
 * @author rcavis
 * @package default
 */
class SrcOrg extends AIR2_Record {
    /* code_master values */
    public static $STATUS_OPTED_IN = 'A';
    public static $STATUS_EDITORIAL_DEACTV = 'D';
    public static $STATUS_OPTED_OUT = 'F';
    public static $STATUS_DELETED = 'X';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_org');
        $this->hasColumn('so_src_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('so_org_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('so_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('so_effective_date', 'date', null, array(
                'notnull' => true,
                'default' => '1970-01-01',
            ));
        $this->hasColumn('so_home_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('so_lock_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('so_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_OPTED_IN,
            ));
        $this->hasColumn('so_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('so_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('so_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('so_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'so_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('Organization', array(
                'local' => 'so_org_id',
                'foreign' => 'org_id',
                'onDelete' => 'CASCADE',
            ));
    }





    /**
     *
     *
     * @param unknown $event
     */
    public function preInsert($event) {
        parent::preInsert($event);
        if ($this->so_effective_date == '1970-01-01') {
            $this->so_effective_date = air2_date();
        }
    }


    /**
     * Re-cache source authz on any save
     *
     * @param Doctrine_Event $event
     */
    public function postSave($event) {
        parent::postSave($event);
        SrcOrgCache::refresh_cache($this->so_src_id);
        $this->Source->set_and_save_src_status();

        // uniqueness of home flag
        if ($this->so_home_flag) {
            $conn = AIR2_DBManager::get_master_connection();
            $q = "update src_org set so_home_flag = 0 where so_src_id = ? and so_org_id != ?";
            $conn->exec($q, array($this->so_src_id, $this->so_org_id));
        }
    }


    /**
     * If any src_org is deleted, the entire cache for that source needs to
     * be refreshed.
     *
     * @param Doctrine_Event $event
     */
    public function postDelete($event) {
        parent::postDelete($event);
        SrcOrgCache::refresh_cache($this->Source);
        $this->Source->set_and_save_src_status();
    }


    /**
     * Readable if READER for Source.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        return $this->Source->user_may_read($user);
    }


    /**
     * Writable if WRITER for Source + WRITER for Organization.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        // ignore src_has_acct (for now)
        return $this->Source->user_may_write($user, false);

        /* this added authz check was decided against in #2225. leaving here
         * in case that decision is ever changed.
         * return (
         *   $this->Source->user_may_write($user)
         *   && $user->has_authz_for(AIR2_AUTHZ_WRITER, $this->so_org_id)
         * );
         */
    }


    /**
     * For now, only SYSTEM users may manage (delete) SrcOrgs
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Don't allow deleting APM PIN org
     *
     * @param User    $u
     * @return unknown
     */
    public function user_may_delete(User $u) {
        if ($this->so_org_id == Organization::$APMPIN_ORG_ID) {
            return AIR2_AUTHZ_IS_DENIED;
        }
        return parent::user_may_delete($u);
    }


    /**
     * Forces a source to be opted-into APMG
     *
     * @param int     $src_id
     * @return bool $inserted
     */
    public static function force_apmg($src_id) {
        $data = array(
            'so_src_id'         => $src_id,
            'so_org_id'         => Organization::$APMPIN_ORG_ID,
            'so_uuid'           => air2_generate_uuid(),
            'so_effective_date' => air2_date(),
            'so_home_flag'      => 0,
            'so_status'         => self::$STATUS_OPTED_IN,
            'so_cre_user'       => 1,
            'so_upd_user'       => 1,
            'so_cre_dtim'       => air2_date(),
            'so_upd_dtim'       => air2_date(),
        );
        $flds = implode(',', array_keys($data));
        $vals = air2_sql_param_string($data);
        $stmt = "insert ignore into src_org ($flds) values ($vals)";

        // execute
        $conn = AIR2_DBManager::get_master_connection();
        $n = $conn->exec($stmt, array_values($data));
        return $n;
    }


    /**
     * Convenience method for adding a SrcOrg record to a new Source.
     *
     * @param Source  $source
     * @param string  $org_uuid
     * @return SrcOrg $src_org
     */
    public static function for_new_source($source, $org_uuid) {
        $org = AIR2_Record::find('Organization', $org_uuid);
        if (!$org) {
            throw new Exception("No such Organization for uuid $org_uuid");
        }
        $so = new SrcOrg();
        $so->so_home_flag = true;
        $so->so_org_id = $org->org_id;
        $so->so_effective_date = air2_date();
        return $so;
    }


}
