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
 * SrcVita
 *
 * The knowledge/life/experiences of a source
 *
 * @property integer $sv_id
 * @property integer $sv_src_id
 * @property string $sv_uuid
 * @property integer $sv_seq
 * @property string $sv_type
 * @property string $sv_status
 * @property string $sv_origin
 * @property string $sv_conf_level
 * @property boolean $sv_lock_flag
 * @property date $sv_start_date
 * @property date $sv_end_date
 * @property float $sv_lat
 * @property float $sv_long
 * @property string $sv_value
 * @property string $sv_basis
 * @property string $sv_notes
 * @property integer $sv_cre_user
 * @property integer $sv_upd_user
 * @property timestamp $sv_cre_dtim
 * @property timestamp $sv_upd_dtim
 * @property Source $Source
 * @author rcavis
 * @package default
 */
class SrcVita extends AIR2_Record {
    /* code_master values */
    public static $TYPE_INTEREST = 'I';
    public static $TYPE_EXPERIENCE = 'E';
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';
    public static $ORIGIN_AIR2 = '2';
    public static $ORIGIN_AIR1_CONTACT = 'C';
    public static $ORIGIN_AIR1_SPECIALTY = 'S';
    public static $ORIGIN_MYPIN = 'M';
    public static $CONF_UNKNOWN = 'U';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_vita');
        $this->hasColumn('sv_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('sv_src_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sv_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('sv_seq', 'integer', 2, array(
                'notnull' => true,
                'default' => 10,
            ));
        $this->hasColumn('sv_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$TYPE_INTEREST,
            ));
        $this->hasColumn('sv_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('sv_origin', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$ORIGIN_AIR2,
            ));
        $this->hasColumn('sv_conf_level', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$CONF_UNKNOWN,
            ));
        $this->hasColumn('sv_lock_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('sv_start_date', 'date', null, array(
            ));
        $this->hasColumn('sv_end_date', 'date', null, array(
            ));
        $this->hasColumn('sv_lat', 'float', null, array(
            ));
        $this->hasColumn('sv_long', 'float', null, array(
            ));
        $this->hasColumn('sv_value', 'string', null, array(
            ));
        $this->hasColumn('sv_basis', 'string', null, array(
            ));
        $this->hasColumn('sv_notes', 'string', null, array(
            ));
        $this->hasColumn('sv_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sv_upd_user', 'integer', 4, array(
            ));
        $this->hasColumn('sv_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sv_upd_dtim', 'timestamp', null, array(
            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'sv_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE',
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
     * Inherit from Source
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write(User $user) {
        // if src_has_acct, start caring about sv_origin
        if ($this->Source->src_has_acct == Source::$ACCT_YES) {
            $okay_to_edit = array(
                SrcVita::$ORIGIN_AIR1_CONTACT,
                SrcVita::$ORIGIN_AIR1_SPECIALTY,
            );

            // ignore lock for AIR1 origins
            if (in_array($this->sv_origin, $okay_to_edit)) {
                return $this->Source->user_may_write($user, false);
            }
        }

        // normal authz
        return $this->Source->user_may_write($user);
    }


    /**
     * Same as writing
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage(User $user) {
        return $this->user_may_write($user);
    }


    /**
     * Set the correct sv_type based on which fields are populated.
     *
     * @param array   $data
     * @param TankSource $tsrc
     * @param int     $op
     */
    public function discriminate($data, &$tsrc, $op=null) {
        if (isset($data['sv_value']) || isset($data['sv_basis'])) {
            $this->sv_type = SrcVita::$TYPE_EXPERIENCE;
        }
        elseif (isset($data['sv_notes'])) {
            $this->sv_type = SrcVita::$TYPE_INTEREST;
        }
        parent::discriminate($data, $tsrc, $op);
    }


}
