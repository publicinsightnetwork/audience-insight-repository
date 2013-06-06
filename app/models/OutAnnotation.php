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
 * OutAnnotation
 *
 * Annotations for PINfluence
 *
 * @property integer   $oa_id
 * @property integer   $oa_out_id
 * @property string    $oa_value
 * @property integer   $oa_cre_user
 * @property integer   $oa_upd_user
 * @property timestamp $oa_cre_dtim
 * @property timestamp $oa_upd_dtim
 * @property Outcome   $Outcome
 * @author echristiansen
 * @package default
 */

class OutAnnotation extends AIR2_Record {
	/**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('out_annotation');
        $this->hasColumn('oa_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('oa_out_id', 'integer', 4, array(
                'notnull' => true,
                'default' => 1,
            ));
        $this->hasColumn('oa_value', 'string', 255, array(
                'notnull' => true,
            ));
        $this->hasColumn('oa_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('oa_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('oa_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('oa_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }

    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Outcome', array(
            'local' => 'oa_out_id',
            'foreign' => 'out_id',
            'onDelete' => 'CASCADE',
        ));
        
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
     * Inherit from Outcome
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        return $this->Outcome->user_may_write($user);
    }

    /**
     * Inherit from Outcome
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        return $this->Outcome->user_may_manage($user);
    }

}