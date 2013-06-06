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
 * SrAnnotation
 *
 * User Annotation on a Source Response
 *
 * @property integer $sran_id
 * @property integer $sran_sr_id
 * @property string $sran_value
 * @property integer $sran_cre_user
 * @property integer $sran_upd_user
 * @property timestamp $sran_cre_dtim
 * @property timestamp $sran_upd_dtim
 * @property SrcResponse $SrcResponse
 * @author rcavis
 * @package default
 */
class SrAnnotation extends AIR2_Record {

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('sr_annotation');
        $this->hasColumn('sran_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('sran_sr_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sran_value', 'string', null, array(

            ));
        $this->hasColumn('sran_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sran_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('sran_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sran_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('SrcResponse', array(
                'local' => 'sran_sr_id',
                'foreign' => 'sr_id',
                'onDelete' => 'CASCADE',
            ));
    }


    /**
     * Inherit from SrcResponse
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read(User $user) {
        return $this->SrcResponse->user_may_read($user);
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
        elseif ($this->SrcResponse->user_may_read($user)) {
            if (!$this->exists()) {
                return AIR2_AUTHZ_IS_NEW;
            }
            elseif ($this->sran_cre_user == $user->user_id) {
                return AIR2_AUTHZ_IS_OWNER;
            }
            else {
                // may only write non-owned if MANAGER of owning user
                $ownr = Doctrine::getTable('User')->find($this->sran_cre_user);
                if ($ownr && $ownr->user_may_manage($user)) {
                    return AIR2_AUTHZ_IS_MANAGER;
                }
            }
        }
        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     * Same as Writing.
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage(User $user) {
        return $this->user_may_write($user);
    }


}
