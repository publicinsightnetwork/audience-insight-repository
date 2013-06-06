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
 * SrcResponse
 *
 * Response by a Source to a specific Question
 *
 * @property integer $sr_id
 * @property string $sr_uuid
 * @property integer $sr_src_id
 * @property integer $sr_ques_id
 * @property integer $sr_srs_id
 * @property boolean $sr_media_asset_flag
 * @property string $sr_orig_value
 * @property string $sr_mod_value
 * @property string $sr_status
 * @property string $sr_public_flag
 * @property integer $sr_cre_user
 * @property integer $sr_upd_user
 * @property timestamp $sr_cre_dtim
 * @property timestamp $sr_upd_dtim
 * @property SrcResponseSet $SrcResponseSet
 * @property Question $Question
 * @property Source $Source
 * @property Doctrine_Collection $SrAnnotation
 * @author rcavis
 * @package default
 */
class SrcResponse extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_response');
        $this->hasColumn('sr_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('sr_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            )
        );
        $this->hasColumn('sr_src_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sr_ques_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sr_srs_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sr_media_asset_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('sr_orig_value', 'string', null, array(

            ));
        $this->hasColumn('sr_mod_value', 'string', null, array(

            ));
        $this->hasColumn('sr_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('sr_public_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('sr_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sr_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('sr_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sr_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }



    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('SrcResponseSet', array(
                'local' => 'sr_srs_id',
                'foreign' => 'srs_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('Question', array(
                'local' => 'sr_ques_id',
                'foreign' => 'ques_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('Source', array(
                'local' => 'sr_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasMany('SrAnnotation', array(
                'local' => 'sr_id',
                'foreign' => 'sran_sr_id'
            ));
    }


    /**
     * Inherit from SrcResponseSet
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read(User $user) {
        return $this->SrcResponseSet->user_may_read($user);
    }


    /**
     * Inherit from SrcResponseSet
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write(User $user) {
        return $this->SrcResponseSet->user_may_write($user);
    }


    /**
     * Inherit from SrcResponseSet
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage(User $user) {
        return $this->SrcResponseSet->user_may_manage($user);
    }


    /**
     * Apply authz rules for who may view the existence of a SrcResponse.
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

        // readable src_response_sets
        $tmp = AIR2_Query::create();
        SrcResponseSet::query_may_read($tmp, $u);
        $tmp = array_pop($tmp->getDqlPart('where'));
        $srs_ids = "select srs_id from src_response_set where $tmp";

        // add to query
        $q->addWhere("{$a}sr_srs_id in ($srs_ids)");
    }


    /**
     * Apply authz rules for who may write to a SrcResponse.
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

        // writable src_response_sets
        $tmp = AIR2_Query::create();
        SrcResponseSet::query_may_write($tmp, $u);
        $tmp = array_pop($tmp->getDqlPart('where'));
        $srs_ids = "select srs_id from src_response_set where $tmp";

        // add to query
        $q->addWhere("{$a}sr_srs_id in ($srs_ids)");
    }


    /**
     * Apply authz rules for who may manage a SrcResponse.
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

        // manageable src_response_sets
        $tmp = AIR2_Query::create();
        SrcResponseSet::query_may_manage($tmp, $u);
        $tmp = array_pop($tmp->getDqlPart('where'));
        $srs_ids = "select srs_id from src_response_set where $tmp";

        // add to query
        $q->addWhere("{$a}sr_srs_id in ($srs_ids)");
    }


}
