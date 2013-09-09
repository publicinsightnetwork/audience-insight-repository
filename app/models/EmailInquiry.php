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
 * EmailInquiry
 *
 * Associate 1 or more inquiries with an email template
 *
 * @property integer    $einq_email_id
 * @property integer    $einq_inq_id
 * @property string     $einq_status
 *
 * @property integer    $einq_cre_user
 * @property integer    $einq_upd_user
 * @property timestamp  $einq_cre_dtim
 * @property timestamp  $einq_upd_dtim
 *
 * @property Email      $Email
 * @property Inquiry    $Inquiry
 *
 * @author rcavis
 * @package default
 */
class EmailInquiry extends AIR2_Record {

    public static $STATUS_ACTIVE   = 'A';
    public static $STATUS_INACTIVE = 'F';


    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('email_inquiry');

        // identifiers
        $this->hasColumn('einq_email_id', 'integer', 4, array(
                'primary' => true,
            ));
        $this->hasColumn('einq_inq_id', 'integer', 4, array(
                'primary' => true,
            ));

        // meta
        $this->hasColumn('einq_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('einq_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('einq_upd_user', 'integer', 4, array());
        $this->hasColumn('einq_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('einq_upd_dtim', 'timestamp', null, array());

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Email', array(
                'local'   => 'einq_email_id',
                'foreign' => 'email_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('Inquiry', array(
                'local'   => 'einq_inq_id',
                'foreign' => 'inq_id',
                'onDelete' => 'CASCADE',
            ));
    }


    /**
     * Inherit from Email
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        return $this->Email->user_may_read($user);
    }


    /**
     * Inherit from Email
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        return $this->Email->user_may_write($user);
    }


    /**
     * Inherit from Email
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        return $this->Email->user_may_manage($user);
    }

}
