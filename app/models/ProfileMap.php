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
 * ProfileMap
 *
 * Helper to configure translations between flat data and source profile
 * information.
 *
 * @property integer   $pmap_id
 * @property string    $pmap_name
 * @property string    $pmap_display_name
 * @property string    $pmap_meta
 * @property string    $pmap_status
 * @property integer   $pmap_cre_user
 * @property integer   $pmap_upd_user
 * @property timestamp $pmap_cre_dtim
 * @property timestamp $pmap_upd_dtim
 * @property Doctrine_Collection $Question
 * @author rcavis
 * @package default
 */
class ProfileMap extends AIR2_Record {

    /* status */
    public static $STATUS_ACTIVE   = 'A';
    public static $STATUS_INACTIVE = 'F';

    /* static fixture values */
    public static $SRC_NAME_SMART   = 1;
    public static $SRC_FIRST        = 2;
    public static $SRC_LAST         = 3;
    public static $SRC_EMAIL        = 10;
    public static $SRC_PHONE        = 20;
    public static $SRC_MAIL_SMART   = 30;
    public static $SRC_MAIL_STREET  = 31;
    public static $SRC_CITY         = 32;
    public static $SRC_STATE        = 33;
    public static $SRC_ZIP          = 34;
    public static $SRC_COUNTRY      = 35;
    public static $SRC_PREF_LANG    = 40;
    public static $SRC_GENDER       = 60;
    public static $SRC_INCOME       = 61;
    public static $SRC_EDUCATION    = 62;
    public static $SRC_POLITICAL    = 63;
    public static $SRC_ETHNICITY    = 64;
    public static $SRC_RELIGION     = 65;
    public static $SRC_BIRTH        = 66;
    public static $SRC_WEBSITE      = 67;
    public static $SRC_LIFECYCLE    = 68;
    public static $SRC_TIMEZONE     = 69;
    public static $SRC_EXPERIENCE   = 80;
    public static $SRC_EMPLOYER     = 81;
    public static $SRC_OCCUPATION   = 82;
    public static $SRC_INTEREST     = 83;
    public static $SRC_RESP_PUBLIC  = 90;


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('profile_map');
        $this->hasColumn('pmap_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('pmap_name', 'string', 32, array(
                'notnull' => true,
                'unique'  => true,
                'airvalid' => array(
                    '/^[a-zA-Z0-9\-\_]+$/' => 'Invalid character(s)! Use [A-Za-z0-9], dashes and underscores',
                ),
            ));
        $this->hasColumn('pmap_display_name', 'string', 255, array(
                'notnull' => true,
                'unique'  => true,
            ));
        $this->hasColumn('pmap_meta', 'string', null, array(

            ));
        $this->hasColumn('pmap_status', 'string', 1, array(
                'fixed'   => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('pmap_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('pmap_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('pmap_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('pmap_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasMany('Question', array(
                'local' => 'pmap_id',
                'foreign' => 'ques_pmap_id',
            ));
    }


}
