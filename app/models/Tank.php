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
 * Tank
 *
 * AIR2 Metadata concerning rows in the TankSource table
 *
 * @property integer   $tank_id
 * @property string    $tank_uuid
 * @property integer   $tank_user_id
 * @property string    $tank_name
 * @property string    $tank_notes
 * @property string    $tank_meta
 * @property string    $tank_type
 * @property string    $tank_status
 * @property string    $tank_xuuid
 * @property string    $tank_errors
 * @property integer   $tank_cre_user
 * @property integer   $tank_upd_user
 * @property timestamp $tank_cre_dtim
 * @property timestamp $tank_upd_dtim
 * @property User                $User
 * @property Doctrine_Collection $TankSource
 * @property Doctrine_Collection $TankActivity
 * @property Doctrine_Collection $TankOrg
 * @author rcavis
 * @package default
 */
class Tank extends AIR2_Record {
    public static $CSV_FILENAME = 'upload.csv';

    // tank types
    public static $TYPE_CSV = 'C';
    public static $TYPE_QM = 'Q';
    public static $TYPE_FB = 'F';

    // status
    public static $STATUS_TSRC_ERRORS    = 'E';
    public static $STATUS_TSRC_CONFLICTS = 'C';
    public static $STATUS_READY          = 'R';
    public static $STATUS_LOCKED         = 'L';
    public static $STATUS_LOCKED_ERROR   = 'K';
    public static $STATUS_CSV_NEW        = 'N';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('tank');
        $this->hasColumn('tank_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('tank_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('tank_user_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('tank_name', 'string', 255, array(
                'notnull' => true,
            ));
        $this->hasColumn('tank_notes', 'string', null, array());
        $this->hasColumn('tank_meta', 'string', null, array());
        $this->hasColumn('tank_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('tank_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
            ));
        $this->hasColumn('tank_xuuid', 'string', 255, array(

            ));
        $this->hasColumn('tank_errors', 'string', null, array(
            ));
        $this->hasColumn('tank_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('tank_upd_user', 'integer', 4, array());
        $this->hasColumn('tank_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('tank_upd_dtim', 'timestamp', null, array());

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('User', array(
                'local' => 'tank_user_id',
                'foreign' => 'user_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasMany('TankSource', array(
                'local' => 'tank_id',
                'foreign' => 'tsrc_tank_id'
            ));
        $this->hasMany('TankActivity', array(
                'local' => 'tank_id',
                'foreign' => 'tact_tank_id'
            ));
        $this->hasMany('TankOrg', array(
                'local' => 'tank_id',
                'foreign' => 'to_tank_id'
            ));
    }


    /**
     * Gets the directory used for any files associated with this Tank
     *
     * @return string
     */
    public function get_folder_path() {
        return AIR2_CSV_PATH.'/upload/'.$this->tank_uuid;
    }


    /**
     * Deletes this Tank's folder, and anything in it
     */
    public function delete_folder() {
        $dir = $this->get_folder_path();
        air2_rmdir($dir);
    }


    /**
     * Gets the full filepath for this Tank's primary file, or null if this
     * type of Tank doesn't have a file.
     *
     * @return string|null
     */
    public function get_file_path() {
        if ($this->tank_type == self::$TYPE_CSV) {
            return $this->get_folder_path().'/'.self::$CSV_FILENAME;
        }
        else {
            return null;
        }
    }


    /**
     * Deletes the file associated with this tank, if it exists
     */
    public function delete_file() {
        $file = $this->get_file_path();
        if ($file && is_file($file)) {
            unlink($file);
        }
    }


    /**
     * Copies a readable file, overwriting this Tank's file.
     *
     * @param string  $source
     * @return boolean success
     */
    public function copy_file($source) {
        air2_mkdir($this->get_folder_path()); // make sure it exists
        $dest = $this->get_file_path();
        if (is_readable($source) && $dest) {
            $this->delete_file();
            copy($source, $dest);
            chmod($dest, 0770);
            return true;
        }
        return false;
    }


    /**
     * Convenience function for getting json-encoded tank_meta
     *
     * @param string  $name the meta-field name
     * @return mixed
     */
    public function get_meta_field($name) {
        if (!$this->tank_meta) {
            return null;
        }
        else {
            $data = json_decode($this->tank_meta, true);
            if (isset($data[$name])) {
                return $data[$name];
            }
            else {
                return null;
            }
        }
    }


    /**
     * Convenience function for setting json-encoded tank_meta
     *
     * @param string  $name  the meta-field name
     * @param mixed   $value the new value
     */
    public function set_meta_field($name, $value) {
        $data = array();
        if ($this->tank_meta) {
            $data = json_decode($this->tank_meta, true);
        }

        $data[$name] = $value;
        $this->tank_meta = json_encode($data);
    }


    /**
     * Create/update src_orgs for a Source.  Also forces a source to be
     * opted-into APMG.
     *
     * @param Source  $src
     */
    public function process_orgs(Source $src) {
        $has_apmg_org = false;
        $processed = 0;
        foreach ($this->TankOrg as $to) {
            $to->process_source($src);
            $processed++;
        }
        $processed += SrcOrg::force_apmg($src->src_id);
        if ($processed > 0) {
            SrcOrgCache::refresh_cache($src);
        }
    }


    /**
     * Create src_activity for a Source.
     *
     * @param Source  $src
     */
    public function process_activity(Source $src) {
        foreach ($this->TankActivity as $tact) {
            $tact->process_source($src);
        }
    }


    /**
     * After a record is deleted, clean up any files/directories related to it
     *
     * @param Doctrine_Event $event
     */
    public function postDelete($event) {
        $this->delete_folder();
    }


    /**
     * Readable by owner and system.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        elseif ($this->tank_user_id == $user->user_id) {
            return AIR2_AUTHZ_IS_OWNER;
        }
        else {

            // any shared Org where user is a WRITER can
            // read the Tank
            $user_authz = $user->get_authz();
            foreach ($this->TankOrg as $to) {
                $role = isset($user_authz[$to->to_org_id]) ? $user_authz[$to->to_org_id] : 0;
                if (ACTION_ORG_SRC_UPDATE & $role) {
                    return AIR2_AUTHZ_IS_ORG;
                }
            }

            return AIR2_AUTHZ_IS_DENIED;
        }
    }


    /**
     * Writable by owner and system.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        return $this->user_may_read($user);
    }


    /**
     * Manageable by owner and system.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        return $this->user_may_write($user);
    }


    /**
     * Only CSV-uploads can be deleted, and only then if they haven't been
     * imported yet.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_delete($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }

        // only CSV uploads
        if ($this->tank_type == Tank::$TYPE_CSV) {
            $uid = $this->tank_user_id;
            $stat = $this->tank_status;
            if ($uid == $user->user_id && $stat == Tank::$STATUS_CSV_NEW) {
                return AIR2_AUTHZ_IS_OWNER;
            }
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Restrict to owner, and anyone able to update sources in a tank_org.
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
        $uid = $u->user_id;
        $authz_str = $u->get_authz_str(ACTION_ORG_SRC_UPDATE, 'to_org_id');
        $subselect = "select to_tank_id from tank_org where $authz_str";
        $q->addWhere("({$a}tank_id in ($subselect) or {$a}tank_user_id = $uid)");
    }


    /**
     * Add conflict/error/done/etc counts to a tank.  Optionally pass in which
     * types to select, rather than them all.
     *
     * @param AIR2_Query $q
     * @param char    $alias
     * @param array   $fld_defs (optional, reference)
     * @param array   $types    (optional)
     */
    public static function add_counts($q, $alias, &$fld_defs=null, $types=null) {
        // code => subselect-alias
        $type_counts = array(
            '*'                             => 'count_total',
            TankSource::$STATUS_NEW         => 'count_new',
            TankSource::$STATUS_CONFLICT    => 'count_conflict',
            TankSource::$STATUS_RESOLVED    => 'count_resolved',
            TankSource::$STATUS_LOCKED      => 'count_locked',
            TankSource::$STATUS_DONE        => 'count_done',
            TankSource::$STATUS_ERROR       => 'count_error',
        );
        if ($types) {
            $less_types = array();
            foreach ($types as $t) $less_types[$t] = $type_counts[$t];
            $type_counts = $less_types;
        }

        // add subselects
        $sub = "select count(*) from tank_source where tsrc_tank_id = $alias.tank_id";
        foreach ($type_counts as $code => $name) {
            if ($code == '*') {
                $q->addSelect("($sub) as $name");
            }
            else {
                $q->addSelect("($sub and tsrc_status = '$code') as $name");
            }
            if (is_array($fld_defs)) {
                $fld_defs []= array('name' => $name, 'type' => 'int');
            }
        }
    }


}
