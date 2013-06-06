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
 * SrcOutcome
 *
 * Sources that are associated with an outcome
 *
 * @property integer   $sout_src_id
 * @property integer   $sout_out_id
 * @property string    $sout_type
 * @property string    $sout_status
 * @property string    $sout_notes
 * @property integer   $sout_cre_user
 * @property integer   $sout_upd_user
 * @property timestamp $sout_cre_dtim
 * @property timestamp $sout_upd_dtim
 * @property Source    $Source
 * @property Outcome   $Outcome
 * @author rcavis
 * @package default
 */
class SrcOutcome extends AIR2_Record {

    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';
    public static $TYPE_INFORMED = 'I';
    public static $TYPE_CITED = 'C';
    public static $TYPE_FEATURED = 'F';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_outcome');
        $this->hasColumn('sout_src_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('sout_out_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('sout_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$TYPE_INFORMED,
            ));
        $this->hasColumn('sout_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('sout_notes', 'string', null, array(

            ));
        $this->hasColumn('sout_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sout_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('sout_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sout_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local'    => 'sout_src_id',
                'foreign'  => 'src_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('Outcome', array(
                'local' => 'sout_out_id',
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
