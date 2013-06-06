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
 * AdminRole
 *
 * Generic roles filled by users within an organization
 *
 * @property integer $ar_id
 * @property string $ar_code
 * @property string $ar_name
 * @property string $ar_status
 * @property integer $ar_cre_user
 * @property integer $ar_upd_user
 * @property timestamp $ar_cre_dtim
 * @property timestamp $ar_upd_dtim
 * @property Doctrine_Collection $AdminUserRole
 * @author rcavis
 * @package default
 */
class AdminRole extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';

    /* ar_id's as defined in fixture */
    const REPORTER = 1;
    const READER   = 2;
    const WRITER   = 3;
    const MANAGER  = 4;
    const NOACCESS = 5;
    const RDRPLUS  = 6;
    const FREEMIUM = 7;

    /* ar_codes as defined in fixture */
    public static $CODES = array(
        'X' => self::REPORTER,
        'R' => self::READER,
        'W' => self::WRITER,
        'M' => self::MANAGER,
        'N' => self::NOACCESS,
        'P' => self::RDRPLUS,
        'F' => self::FREEMIUM,
    );


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('admin_role');
        $this->hasColumn('ar_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('ar_code', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('ar_name', 'string', 128, array(
                'notnull' => true,
            ));
        $this->hasColumn('ar_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('ar_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('ar_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('ar_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('ar_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasMany('UserOrg', array(
                'local' => 'ar_id',
                'foreign' => 'uo_ar_id'
            ));
    }


    /**
     * Gets a bitmask representing this role.
     *
     * @return int
     */
    public function get_bitmask() {
        return self::to_bitmask($this->ar_code);
    }


    /**
     * Turn an ar_id or ar_code into an authorized-actions bitmask
     *
     * @param  mixed   $ar_id_or_code
     * @return integer $bitmask
     */
    public static function to_bitmask($ar_id_or_code) {
        $code = false;
        foreach (self::$CODES as $c => $i) {
            if ($ar_id_or_code == $c || $ar_id_or_code == $i) $code = $c;
        }
        if (!$code) {
            throw new Exception("Invalid ar_id or ar_code: $ar_id_or_code");
        }

        // bitmasks are defined by init.php - which reads the actions and roles ini files
        $bitmask = 0;
        if (defined("AIR2_AUTHZ_ROLE_$code")) {
            $bitmask = constant("AIR2_AUTHZ_ROLE_$code");
        }
        return $bitmask;
    }


}
