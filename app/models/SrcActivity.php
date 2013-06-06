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
 * SrcActivity
 *
 * Activity initiated by or on a Source.
 *
 * @property integer $sact_id
 * @property integer $sact_actm_id
 * @property integer $sact_src_id
 * @property integer $sact_prj_id
 * @property timestamp $sact_dtim
 * @property string $sact_desc
 * @property string $sact_notes
 * @property integer $sact_cre_user
 * @property integer $sact_upd_user
 * @property timestamp $sact_cre_dtim
 * @property timestamp $sact_upd_dtim
 * @property integer $sact_xid
 * @property string $sact_ref_type
 * @property Source $Source
 * @property ActivityMaster $ActivityMaster
 * @property Project $Project
 * @author rcavis
 * @package default
 */
class SrcActivity extends AIR2_Record {
    /* xid reference types */
    public static $REF_TYPE_RESPONSE = 'R';
    public static $REF_TYPE_INQUIRY = 'I';
    public static $REF_TYPE_TANK = 'T';
    public static $REF_TYPE_ORG = 'O';
    public static $REF_TYPE_MAIL = 'M';  


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_activity');
        $this->hasColumn('sact_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('sact_actm_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sact_src_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sact_prj_id', 'integer', 4, array(
                //ALLOW NULLS - workaround for unique key
            ));
        $this->hasColumn('sact_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sact_desc', 'string', 255, array(

            ));
        $this->hasColumn('sact_notes', 'string', null, array(

            ));
        $this->hasColumn('sact_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sact_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('sact_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sact_upd_dtim', 'timestamp', null, array(

            ));
        $this->hasColumn('sact_xid', 'integer', 4, array(

            ));
        $this->hasColumn('sact_ref_type', 'string', 1, array(
                'fixed' => true,
            ));

        $this->index('sact_ix_3', array(
                'fields' => array('sact_prj_id', 'sact_dtim'),
            )
        );

        // upd_dtim index for optimizing search index builds.
        $this->index('sact_ix_4', array(
                'fields' => array('sact_upd_dtim')
            )
        );

        // cre_user index looking at a user's activity
        $this->index('sact_ix_5', array(
                'fields' => array('sact_cre_user')
            )
        );

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'sact_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('ActivityMaster', array(
                'local' => 'sact_actm_id',
                'foreign' => 'actm_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('Project', array(
                'local' => 'sact_prj_id',
                'foreign' => 'prj_id',
                'onDelete' => 'CASCADE'
            ));
    }


    /**
     * Custom AIR2 validation before update/save
     *
     * @param Doctrine_Event $event
     */
    public function preValidate($event) {
        parent::preValidate($event);

        // make sure we got a valid ref type
        $types = array(
            self::$REF_TYPE_RESPONSE,
            self::$REF_TYPE_INQUIRY,
            self::$REF_TYPE_TANK,
            self::$REF_TYPE_ORG,
            self::$REF_TYPE_MAIL,
        );
        if ($this->sact_ref_type && $this->sact_xid) {
            if (!in_array($this->sact_ref_type, $types)) {
                throw new Exception("Invalid sact_ref_type specified!");
            }
        }
    }


    /**
     * Sets the generic "sact_xid" on this table to a specific relation based
     * on sact_ref_type.
     */
    public static function setupRelated() {
        // need to alter tables for ALL connections
        foreach (AIR2_DBManager::$db_handles as $name => $conn) {
            $tbl = $conn->getTable('SrcActivity');

            // setup the non-enforced related items
            if (!$tbl->hasRelation('SrcResponseSet')) {
                $tbl->hasOne('SrcResponseSet', array('local' => 'sact_xid', 'foreign' => 'srs_id'));
            }
            if (!$tbl->hasRelation('Tank')) {
                $tbl->hasOne('Tank', array('local' => 'sact_xid', 'foreign' => 'tank_id'));
            }
            if (!$tbl->hasRelation('Organization')) {
                $tbl->hasOne('Organization', array('local' => 'sact_xid', 'foreign' => 'org_id'));
            }
            if (!$tbl->hasRelation('Inquiry')) {
                $tbl->hasOne('Inquiry', array('local' => 'sact_xid', 'foreign' => 'inq_id'));
            }
        }
    }


    /**
     * Joins a SrcActivity to it's external reference in a Doctrine Query.
     *
     * @param AIR2_Query $q
     * @param string  $alias
     */
    public static function joinRelated($q, $alias) {
        $a = ($alias) ? "$alias." : "";
        SrcActivity::setupRelated();

        $q->leftJoin("{$a}SrcResponseSet WITH {$a}sact_ref_type = ?", self::$REF_TYPE_RESPONSE);
        $q->leftJoin("{$a}Tank WITH {$a}sact_ref_type = ?", self::$REF_TYPE_TANK);
        $q->leftJoin("{$a}Organization WITH {$a}sact_ref_type = ?", self::$REF_TYPE_ORG);
        $q->leftJoin("{$a}Inquiry WITH {$a}sact_ref_type = ?", self::$REF_TYPE_INQUIRY);
    }


}
