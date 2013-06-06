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
 * InquiryAnnotation
 *
 * Annotation by a User on a Inquiry
 *
 * @property integer   $inqan_id
 * @property integer   $inqan_inq_id
 * @property string    $inqan_value
 * @property integer   $inqan_cre_user
 * @property integer   $inqan_upd_user
 * @property timestamp $inqan_cre_dtim
 * @property timestamp $inqan_upd_dtim
 * @property Inquiry   $Inquiry
 * @author rcavis
 * @package default
 */
class InquiryAnnotation extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('inquiry_annotation');
        $this->hasColumn('inqan_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('inqan_inq_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('inqan_value', 'string', null, array(

            ));
        $this->hasColumn('inqan_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('inqan_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('inqan_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('inqan_upd_dtim', 'timestamp', null, array(

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
        $this->hasOne('Inquiry', array(
                'local' => 'inqan_inq_id',
                'foreign' => 'inq_id',
                'onDelete' => 'CASCADE',
            ));
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
     * Need read to create; owner or manager to update/delete.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        elseif ($this->Inquiry->user_may_read($user)) {
            if (!$this->exists()) {
                return AIR2_AUTHZ_IS_NEW;
            }
            elseif ($this->inqan_cre_user == $user->user_id) {
                return AIR2_AUTHZ_IS_OWNER;
            }
            else {
                // may only write non-owned if MANAGER of owning user
                $ownr = Doctrine::getTable('User')->find($this->inqan_cre_user);
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

        // readable inquiries
        $tmp = AIR2_Query::create();
        Inquiry::query_may_read($tmp, $u);
        $tmp = array_pop($tmp->getDqlPart('where'));
        $inq_ids = "select inq_id from inquiry where $tmp";

        // add to query
        $q->addWhere("{$a}inqan_inq_id in ($inq_ids)");
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

        // readable inquiries
        $tmp = AIR2_Query::create();
        Inquiry::query_may_read($tmp, $u);
        $tmp = array_pop($tmp->getDqlPart('where'));
        $inq_ids = "select inq_id from inquiry where $tmp";

        // add to query
        $user_id = $u->user_id;
        $own = "{$a}inqan_cre_user = $user_id";
        $q->addWhere("({$a}inqan_inq_id in ($inq_ids) and $own)");
    }


    /**
     * Apply authz rules for who may manage.
     *
     * @param AIR2_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     */
    public static function query_may_manage(AIR2_Query $q, User $u, $alias=null) {
        $this->query_may_write($q, $u, $alias);
    }


}
