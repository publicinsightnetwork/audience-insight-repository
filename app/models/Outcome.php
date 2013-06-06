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
 * Outcome
 *
 * Outcomes of work in AIR2.  May be related (via foreign keys) to Projects,
 * Sources, and Inquiries.
 *
 * @property integer   $out_id
 * @property string    $out_uuid
 * @property integer   $out_org_id
 * @property string    $out_headline
 * @property string    $out_internal_headline
 * @property string    $out_url
 * @property string    $out_teaser
 * @property string    $out_internal_teaser
 * @property string    $out_show
 * @property string    $out_survey
 * @property timestamp $out_dtim
 * @property string    $out_meta
 * @property string    $out_type
 * @property string    $out_status
 * @property integer   $out_cre_user
 * @property integer   $out_upd_user
 * @property timestamp $out_cre_dtim
 * @property timestamp $out_upd_dtim
 * @property Organization $Organization
 * @property Doctrine_Collection $PrjOutcome
 * @property Doctrine_Collection $SrcOutcome
 * @property Doctrine_Collection $InqOutcome
 *
 * @author rcavis
 * @package default
 */
class Outcome extends AIR2_Record {

    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';
    public static $STATUS_ACTIVE_WITH_FEEDS = 'A'; //same
    public static $STATUS_ACTIVE_NO_FEEDS = 'N';

    public static $TYPE_STORY =  'S';
    public static $TYPE_SERIES = 'R';
    public static $TYPE_EVENT =  'E';
    public static $TYPE_OTHER =  'O';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('outcome');
        $this->hasColumn('out_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('out_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('out_org_id', 'integer', 4, array(
                'notnull' => true,
                'default' => 1,
            ));
        $this->hasColumn('out_headline', 'string', 255, array(
                'notnull' => true,
            ));
        $this->hasColumn('out_internal_headline', 'string', 255, array(

            ));
        $this->hasColumn('out_url', 'string', 255, array(

            ));
        $this->hasColumn('out_teaser', 'string', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('out_internal_teaser', 'string', null, array(

            ));
        $this->hasColumn('out_show', 'string', 255, array(

            ));
        $this->hasColumn('out_survey', 'string', null, array(

            ));
        $this->hasColumn('out_dtim', 'timestamp', null, array(

            ));
        $this->hasColumn('out_meta', 'string', null, array(

            ));
        $this->hasColumn('out_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$TYPE_STORY,
            ));
        $this->hasColumn('out_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('out_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('out_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('out_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('out_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Organization', array(
                'local' => 'out_org_id',
                'foreign' => 'org_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasMany('PrjOutcome', array(
                'local'   => 'out_id',
                'foreign' => 'pout_out_id',
            ));
        $this->hasMany('SrcOutcome', array(
                'local'   => 'out_id',
                'foreign' => 'sout_out_id',
            ));
        $this->hasMany('InqOutcome', array(
                'local'   => 'out_id',
                'foreign' => 'iout_out_id',
            ));
    }


    /**
     * Convenience function for getting json-encoded out_meta
     *
     * @param string  $name the meta-field name
     * @return mixed
     */
    public function get_meta_field($name) {
        if (!$this->out_meta) {
            return null;
        }
        else {
            $data = json_decode($this->out_meta, true);
            return isset($data[$name]) ? $data[$name] : null;
        }
    }


    /**
     * Convenience function for setting json-encoded out_meta
     *
     * @param string  $name  the meta-field name
     * @param mixed   $value the new value
     */
    public function set_meta_field($name, $value) {
        $data = json_decode($this->out_meta, true);
        $data = $data ? $data : array();
        $data[$name] = $value;
        $this->out_meta = json_encode($data);
    }


    /**
     * Public
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        return AIR2_AUTHZ_IS_PUBLIC;
    }


    /**
     * Must be owner, or inherit from Project or Inquiry
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        if ($this->out_cre_user == $user->user_id) {
            return AIR2_AUTHZ_IS_OWNER;
        }
        if (!$this->exists()) {
            return AIR2_AUTHZ_IS_NEW;
        }

        // per #9533, only owner may edit
        // foreach ($this->PrjOutcome as $pout) {
        //     $authz = $pout->Project->user_may_write($user);
        //     if ($authz) return $authz;
        // }
        // foreach ($this->InqOutcome as $iout) {
        //     $authz = $iout->Inquiry->user_may_write($user);
        //     if ($authz) return $authz;
        // }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Same as writing
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        return $this->user_may_write($user);
    }


}
