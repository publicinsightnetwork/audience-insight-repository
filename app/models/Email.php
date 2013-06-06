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
 * Email
 *
 * A template for sending an email to a source/bin
 *
 * @property integer    $email_id
 * @property integer    $email_org_id
 * @property integer    $email_usig_id
 * @property string     $email_uuid
 * @property string     $email_campaign_name
 *
 * @property string     $email_from_name
 * @property string     $email_from_email
 * @property string     $email_subject_line
 * @property string     $email_headline
 * @property string     $email_body
 *
 * @property string     $email_type
 * @property string     $email_status
 *
 * @property integer    $email_cre_user
 * @property integer    $email_upd_user
 * @property timestamp  $email_cre_dtim
 * @property timestamp  $email_upd_dtim
 *
 * @property Organization        $Organization
 * @property UserSignature       $UserSignature
 * @property Image               $Logo
 * @property Doctrine_Collection $EmailInquiry
 * @property Doctrine_Collection $SrcExport
 *
 * @author rcavis
 * @package default
 */
class Email extends AIR2_Record {

    public static $STATUS_ACTIVE   = 'A';
    public static $STATUS_DRAFT    = 'D';
    public static $STATUS_INACTIVE = 'F';

    public static $TYPE_QUERY     = 'Q';
    public static $TYPE_FOLLOW_UP = 'F';
    public static $TYPE_REMINDER  = 'R';
    public static $TYPE_THANK_YOU = 'T';
    public static $TYPE_OTHER     = 'O';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('email');

        // identifiers
        $this->hasColumn('email_id', 'integer', 4, array(
                'primary'       => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('email_org_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('email_usig_id', 'integer', 4, array());
        $this->hasColumn('email_uuid', 'string', 12, array(
                'fixed'   => true,
                'notnull' => true,
                'unique'  => true,
            ));
        $this->hasColumn('email_campaign_name', 'string', 255, array(
                'notnull' => true,
            ));

        // text
        $this->hasColumn('email_from_name', 'string', 255, array());
        $this->hasColumn('email_from_email', 'string', 255, array());
        $this->hasColumn('email_subject_line', 'string', 255, array());
        $this->hasColumn('email_headline', 'string', 255, array());
        $this->hasColumn('email_body', 'string', null, array());

        // meta
        $this->hasColumn('email_type', 'string', 1, array(
                'fixed'   => true,
                'notnull' => true,
                'default' => self::$TYPE_OTHER,
            ));
        $this->hasColumn('email_status', 'string', 1, array(
                'fixed'   => true,
                'notnull' => true,
                'default' => self::$STATUS_DRAFT,
            ));

        // user/timestamps
        $this->hasColumn('email_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('email_upd_user', 'integer', 4, array());
        $this->hasColumn('email_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('email_upd_dtim', 'timestamp', null, array());

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Organization', array(
                'local'   => 'email_org_id',
                'foreign' => 'org_id',
            ));
        $this->hasOne('UserSignature', array(
                'local'   => 'email_usig_id',
                'foreign' => 'usig_id',
            ));
        $this->hasOne('ImageEmailLogo as Logo', array(
                'local'   => 'email_id',
                'foreign' => 'img_xid',
            ));
        $this->hasMany('EmailInquiry', array(
                'local'   => 'email_id',
                'foreign' => 'einq_email_id',
            ));
        $this->hasMany('SrcExport', array(
                'local'   => 'email_id',
                'foreign' => 'se_email_id',
            ));
    }

}
