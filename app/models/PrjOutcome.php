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
 * PrjOutcome
 *
 * Projects that are associated with an outcome
 *
 * @property integer   $pout_inq_id
 * @property integer   $pout_out_id
 * @property string    $pout_type
 * @property string    $pout_status
 * @property string    $pout_notes
 * @property integer   $pout_cre_user
 * @property integer   $pout_upd_user
 * @property timestamp $pout_cre_dtim
 * @property timestamp $pout_upd_dtim
 * @property Project   $Project
 * @property Outcome   $Outcome
 * @author rcavis
 * @package default
 */
class PrjOutcome extends AIR2_Record {

    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';
    public static $TYPE_INFORMED = 'I';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('prj_outcome');
        $this->hasColumn('pout_prj_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('pout_out_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('pout_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$TYPE_INFORMED,
            ));
        $this->hasColumn('pout_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('pout_notes', 'string', null, array(

            ));
        $this->hasColumn('pout_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('pout_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('pout_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('pout_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Project', array(
                'local'    => 'pout_prj_id',
                'foreign'  => 'prj_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('Outcome', array(
                'local' => 'pout_out_id',
                'foreign' => 'out_id',
                'onDelete' => 'CASCADE',
            ));
    }


    /**
     * Inherit from Outcome
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        return $this->Outcome->user_may_read($user);
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
