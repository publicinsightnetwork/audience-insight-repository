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
 * ProjectActivity
 *
 * Activity occuring in reference to a project
 *
 * @property integer $pa_id
 * @property integer $pa_actm_id
 * @property integer $pa_prj_id
 * @property timestamp $pa_dtim
 * @property string $pa_desc
 * @property string $pa_notes
 * @property integer $pa_cre_user
 * @property integer $pa_upd_user
 * @property timestamp $pa_cre_dtim
 * @property timestamp $pa_upd_dtim
 * @property integer $pa_xid
 * @property string $pa_ref_type
 * @property Project $Project
 * @property ActivityMaster $ActivityMaster
 * @property User $User
 * @author rcavis
 * @package default
 */
class ProjectActivity extends AIR2_Record {
    /* Static array of valid pa_ref_type's for joining pa_xid */
    public static $REF_TYPE_ORG = 'O';
    public static $REF_TYPE_INQ = 'I';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('project_activity');
        $this->hasColumn('pa_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('pa_actm_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('pa_prj_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('pa_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('pa_desc', 'string', 255, array(

            ));
        $this->hasColumn('pa_notes', 'string', null, array(

            ));
        $this->hasColumn('pa_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('pa_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('pa_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('pa_upd_dtim', 'timestamp', null, array(

            ));
        $this->hasColumn('pa_xid', 'integer', 4, array(

            ));
        $this->hasColumn('pa_ref_type', 'string', 1, array(
                'fixed' => true,
            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Project', array(
                'local' => 'pa_prj_id',
                'foreign' => 'prj_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasOne('ActivityMaster', array(
                'local' => 'pa_actm_id',
                'foreign' => 'actm_id',
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
        if ($this->pa_ref_type && $this->pa_xid) {
            $rt = $this->pa_ref_type;
            if (!in_array($rt, array(self::$REF_TYPE_ORG, self::$REF_TYPE_INQ))) {
                throw new Exception("Invalid pa_ref_type specified!");
            }
        }
    }


    /**
     * Sets the generic "pa_xid" on this table to a specific relation based
     * on pa_ref_type.
     */
    public static function setupRelated() {
        // need to alter tables for ALL connections
        foreach (AIR2_DBManager::$db_handles as $name => $conn) {
            $tbl = $conn->getTable('ProjectActivity');

            // setup the non-enforced related items
            if (!$tbl->hasRelation('Organization')) {
                $tbl->hasOne('Organization', array('local' => 'pa_xid', 'foreign' => 'org_id'));
            }
            if (!$tbl->hasRelation('Inquiry')) {
                $tbl->hasOne('Inquiry', array('local' => 'pa_xid', 'foreign' => 'inq_id'));
            }
        }
    }


    /**
     * Joins a ProjectActivity to it's external reference in a Doctrine Query.
     *
     * @param AIR2_Query $q
     * @param string  $alias
     */
    public static function joinRelated($q, $alias) {
        $a = ($alias) ? "$alias." : "";
        ProjectActivity::setupRelated();

        $q->leftJoin("{$a}Organization WITH {$a}pa_ref_type = ?", self::$REF_TYPE_ORG);
        $q->leftJoin("{$a}Inquiry WITH {$a}pa_ref_type = ?", self::$REF_TYPE_INQ);
    }


}
