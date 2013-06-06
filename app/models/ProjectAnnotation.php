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
 * ProjectAnnotation
 *
 * Annotation by a User on a Project
 *
 * @property integer $prjan_id
 * @property integer $prjan_prj_id
 * @property string $prjan_value
 * @property integer $prjan_cre_user
 * @property integer $prjan_upd_user
 * @property timestamp $prjan_cre_dtim
 * @property timestamp $prjan_upd_dtim
 * @property Project $Project
 * @author rcavis
 * @package default
 */
class ProjectAnnotation extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('project_annotation');
        $this->hasColumn('prjan_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('prjan_prj_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('prjan_value', 'string', null, array(

            ));
        $this->hasColumn('prjan_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('prjan_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('prjan_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('prjan_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     *
     * @return unknown
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Project', array(
                'local' => 'prjan_prj_id',
                'foreign' => 'prj_id',
                'onDelete' => 'CASCADE',
            ));
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
     * Need read to create; owner or manager to update/delete.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        elseif ($this->Project->user_may_read($user)) {
            if (!$this->exists()) {
                return AIR2_AUTHZ_IS_NEW;
            }
            elseif ($this->prjan_cre_user == $user->user_id) {
                return AIR2_AUTHZ_IS_OWNER;
            }
            else {
                // may only write non-owned if MANAGER of owning user
                $ownr = Doctrine::getTable('User')->find($this->prjan_cre_user);
                if ($ownr && $ownr->user_may_manage($user)) {
                    return AIR2_AUTHZ_IS_MANAGER;
                }
            }
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Same as writing.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        return $this->user_may_write($user);
    }


    /**
     * Apply authz rules for who may read.
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
        $user_id = $u->user_id;
        $prjq = $q->createSubquery();
        $prjq->select('prj.prj_id');
        $prjq->from('Project prj');
        Project::query_may_read($prjq, $u);

        $q->addWhere("${a}prjan_prj_id IN (" . $prjq->getDql() . ")");
    }


    /**
     * Apply authz rules for who may write.
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
        $user_id = $u->user_id;
        $prjq = $q->createSubquery();
        $prjq->select('prj.prj_id');
        $prjq->from('Project prj');
        Project::query_may_write($prjq, $u);

        $q->addWhere("${a}prjan_prj_id IN (" . $prjq->getDql() . ")");
        $q->addWhere("${a}prjan_cre_user = ?", $u->user_id);
    }


    /**
     * Apply authz rules for who may manage.
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
        $user_id = $u->user_id;
        $prjq = $q->createSubquery();
        $prjq->select('prj.prj_id');
        $prjq->from('Project prj');
        Project::query_may_manage($prjq, $u);

        $q->addWhere("${a}prjan_prj_id IN (" . $prjq->getDql() . ")");
        $q->addWhere("${a}prjan_cre_user = ?", $u->user_id);
    }


}
