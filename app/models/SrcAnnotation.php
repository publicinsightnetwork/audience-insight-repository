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
 * SrcAnnotation
 *
 * User Annotation about a Source
 *
 * @property integer $srcan_id
 * @property integer $srcan_src_id
 * @property string $srcan_value
 * @property integer $srcan_cre_user
 * @property integer $srcan_upd_user
 * @property timestamp $srcan_cre_dtim
 * @property timestamp $srcan_upd_dtim
 * @property Source $Source
 * @author rcavis
 * @package default
 */
class SrcAnnotation extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_annotation');
        $this->hasColumn('srcan_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('srcan_src_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('srcan_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => 'S', // "Source" annotation (see code_master)
            ));
        $this->hasColumn('srcan_value', 'string', null, array(

            ));
        $this->hasColumn('srcan_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('srcan_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('srcan_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('srcan_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'srcan_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE'
            ));
    }


    /**
     * Inherit from Source
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read(User $user) {
        return $this->Source->user_may_read($user);
    }


    /**
     * Need read to create; owner or manager to update/delete.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write(User $user) {
        if ($user->is_system()) {
            return AIR2_AUTHZ_IS_SYSTEM;
        }
        elseif ($this->Source->user_may_read($user)) {
            if (!$this->exists()) {
                return AIR2_AUTHZ_IS_NEW;
            }
            elseif ($this->srcan_cre_user == $user->user_id) {
                return AIR2_AUTHZ_IS_OWNER;
            }
            else {
                // may only write non-owned if MANAGER of owning user
                $ownr = Doctrine::getTable('User')->find($this->srcan_cre_user);
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
    public function user_may_manage(User $user) {
        return $this->user_may_write($user);
    }


}
