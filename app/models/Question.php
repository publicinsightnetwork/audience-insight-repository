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
 * Question
 *
 * Single Questions sent to a Source as part of an Inquiry.
 *
 * @property integer    $ques_id
 * @property integer    $ques_inq_id
 * @property integer    $ques_pmap_id
 * @property string     $ques_uuid
 * @property integer    $ques_dis_seq
 * @property string     $ques_status
 * @property string     $ques_type
 * @property string     $ques_value
 * @property string     $ques_choices
 * @property string     $ques_locks
 * @property string     $ques_public_flag
 * @property string     $ques_resp_type
 * @property string     $ques_resp_opts
 * @property integer    $ques_cre_user
 * @property integer    $ques_upd_user
 * @property timestamp  $ques_cre_dtim
 * @property timestamp  $ques_upd_dtim
 * @property string     $ques_template
 * @property Inquiry $Inquiry
 * @property ProfileMap $ProfileMap
 * @property Doctrine_Collection $SrcResponse
 * @author rcavis
 * @package default
 */
class Question extends AIR2_Record {

    // question types
    public static $TYPE_TEXT        = 'T';
    public static $TYPE_TEXTAREA    = 'A';
    public static $TYPE_DATE        = 'D';
    public static $TYPE_DTIM        = 'I';
    public static $TYPE_FILE        = 'F';
    public static $TYPE_HIDDEN      = 'H';

    // querymaker treats lowercase types as hidden
    public static $TYPE_TEXT_HIDDEN = 't';

    // contributor types
    public static $TYPE_CONTRIBUTOR = 'Z';

    // singleselect types
    public static $TYPE_PICK_RADIO    = 'R';
    public static $TYPE_PICK_DROPDOWN = 'O';
    public static $TYPE_PICK_STATE    = 'S';
    public static $TYPE_PICK_COUNTRY  = 'Y';

    // multiselect types
    public static $TYPE_PICK_CHECKS   = 'C';
    public static $TYPE_PICK_LISTMULT = 'L';

    // display-only
    public static $TYPE_BREAK         = '2';
    public static $TYPE_DISPLAY       = '3';

    // standard permission question
    public static $TYPE_PERMISSION        = 'P';
    public static $TYPE_PERMISSION_HIDDEN = 'p';

    // question status
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INACTIVE = 'F';
    public static $STATUS_DELETED = 'X';

    // response data types (for validation)
    public static $DTYPE_STRING     = 'S';
    public static $DTYPE_FILE       = 'F';
    public static $DTYPE_NUMBER     = 'N';
    public static $DTYPE_DATE       = 'D';
    public static $DTYPE_DTIM       = 'T';
    public static $DTYPE_EMAIL      = 'E';
    public static $DTYPE_URL        = 'U';
    public static $DTYPE_PHONE      = 'P';
    public static $DTYPE_YEAR       = 'Y';
    public static $DTYPE_ZIP        = 'Z';

    // template keys
    public static $TKEY_FIRSTNAME = 'firstname';
    public static $TKEY_LASTNAME = 'lastname';
    public static $TKEY_EMAIL = 'email';
    public static $TKEY_STREET = 'street';
    public static $TKEY_CITY = 'city';
    public static $TKEY_STATE = 'state';
    public static $TKEY_COUNTRY = 'country';
    public static $TKEY_ZIP = 'zip';
    public static $TKEY_PHONE = 'phone';
    public static $TKEY_TWITTER = 'twitter';
    public static $TKEY_PERMISSION = 'publicflag';

    // checkbox/radio directions
    public static $DIRECTION_VERTICAL = 'V';
    public static $DIRECTION_HORIZONTAL = 'H';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('question');
        $this->hasColumn('ques_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('ques_inq_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('ques_pmap_id', 'integer', 4, array(

            ));
        $this->hasColumn('ques_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('ques_dis_seq', 'integer', 2, array(

            ));
        $this->hasColumn('ques_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('ques_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => Question::$TYPE_TEXT,
            ));
        $this->hasColumn('ques_value', 'string', null, array(
                'notnull' => true,
                'airvalidhtml' => array(
                    'display' => 'Question Value',
                    'message' => 'Not well formed html',
                ),
            ));
        $this->hasColumn('ques_choices', 'string', null, array(
                'airvalidhtml' => array(
                    'display' => 'Question Choices',
                    'message' => 'One of the options for this question contains html that is not well formed.',
                ),
            ));
        $this->hasColumn('ques_locks', 'string', 255, array(

            ));
        $this->hasColumn('ques_template', 'string', 40, array(

            ));
        $this->hasColumn('ques_public_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('ques_resp_type', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => Question::$DTYPE_STRING,
            ));
        $this->hasColumn('ques_resp_opts', 'string', 255, array(

            ));
        $this->hasColumn('ques_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('ques_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('ques_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('ques_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }



    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Inquiry', array(
                'local' => 'ques_inq_id',
                'foreign' => 'inq_id',
                'onDelete' => 'CASCADE',
            ));
        $this->hasOne('ProfileMap', array(
                'local' => 'ques_pmap_id',
                'foreign' => 'pmap_id',
            ));
        $this->hasMany('SrcResponse', array(
                'local' => 'ques_id',
                'foreign' => 'sr_ques_id'
            ));
    }


    /**
     * Inherit from Project
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_read($user) {
        return $this->Inquiry->user_may_read($user);
    }


    /**
     * Inherit from Project
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_write($user) {
        return $this->Inquiry->user_may_write($user);
    }


    /**
     * Same as writing
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage($user) {
        return $this->Inquiry->user_may_manage($user);
    }


    /**
     * Post save() hook provided by Doctrine.
     *
     *
     * @return void
     * @param Doctrine_Event $event
     * */
    public function postSave($event) {
        $this->Inquiry->check_permission_question();
    }


    /**
     * Return array of active ques_status values.
     *
     * @return array $active_status
     */
    public static function get_active_status() {
        return array(self::$STATUS_ACTIVE);
    }


    /**
     * Override basic exception string handling to make it friendlier for browser.
     *
     * @return string $message
     */
    public function getErrorStackAsString()
    {
        $errorStack = $this->getErrorStack();

        $message = '';

        if (count($errorStack)) {
            foreach ($errorStack as $field => $errors) {
                $message .= count($errors) . " validator" . (count($errors) > 1 ?  's' : null) . " failed on $field of Question: {$this->ques_value}<br /><br />(" . implode(", ", $errors) . ")<br /><br />";
            }
            return $message;
        } else {
            return false;
        }
    }

}
