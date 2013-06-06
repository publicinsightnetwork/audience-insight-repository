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
 * SrcPhoneNumber
 *
 * Phone number for a Source
 *
 * @property integer $sph_id
 * @property string $sph_uuid
 * @property integer $sph_src_id
 * @property boolean $sph_primary_flag
 * @property string $sph_context
 * @property string $sph_country
 * @property string $sph_number
 * @property string $sph_ext
 * @property string $sph_status
 * @property integer $sph_cre_user
 * @property integer $sph_upd_user
 * @property timestamp $sph_cre_dtim
 * @property timestamp $sph_upd_dtim
 * @property Source $Source
 * @author rcavis
 * @package default
 */
class SrcPhoneNumber extends AIR2_Record {
    /* code_master values */
    public static $STATUS_ACTIVE = 'A';
    public static $STATUS_INVALID = 'I';
    public static $STATUS_INACTIVE = 'F';
    public static $CONTEXT_HOME = 'H';
    public static $CONTEXT_WORK = 'W';
    public static $CONTEXT_CELL = 'M';
    public static $CONTEXT_MOBILE = 'M';
    public static $CONTEXT_OTHER = 'O';
    public static $CONTEXT_SMS = 'S';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_phone_number');
        $this->hasColumn('sph_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('sph_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('sph_src_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sph_primary_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('sph_context', 'string', 1, array(
                'fixed' => true,
            ));
        $this->hasColumn('sph_country', 'string', 3, array(
                'length' => 3,
                'fixed' => true,
            ));
        // http://en.wikipedia.org/wiki/Telephone_numbering_plan
        // says max length of full int'l number is 15 digits.
        // we err on the side of powers of 2.
        $this->hasColumn('sph_number', 'string', 16, array(
                'notnull' => true,
            ));
        $this->hasColumn('sph_ext', 'string', 12, array(

            ));
        $this->hasColumn('sph_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_ACTIVE,
            ));
        $this->hasColumn('sph_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sph_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('sph_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sph_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'sph_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE'
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
     * Make sure the source doesn't get duplicate sph_numbers.
     *
     * @param array   $data
     * @param TankSource $tsrc
     * @param int     $op
     */
    public function discriminate($data, &$tsrc, $op=null) {
        // ignore if sph_number isn't set
        if (isset($data['sph_number'])) {
            // search for existing
            if ($op != AIR2_DISCRIM_ADD) {
                $q = $this->getTable()->createQuery();
                $q->where('sph_src_id = ?', $this->sph_src_id);
                $q->andWhere('sph_number = ?', $data['sph_number']);
                $existing_rec = $q->fetchOne(array(), Doctrine::HYDRATE_ARRAY);
                if ($existing_rec) {
                    $this->assignIdentifier($existing_rec['sph_id']);
                    $this->hydrate($existing_rec);
                }
                $q->free(); //cleanup
            }

            // just set primary --- actual logic in postsave hook
            if (isset($data['sph_primary_flag'])) {
                $this->sph_primary_flag = $data['sph_primary_flag'];
                unset($data['sph_primary_flag']);
            }

            // set remaining data with parent
            parent::discriminate($data, $tsrc, $op);
        }
    }


    /**
     * Make sure we only have 1 primary
     *
     * @param Doctrine_Event $event
     */
    public function postSave($event) {
        air2_fix_src_primary($this);
        parent::postSave($event);
    }


    /**
     * Look for a primary after delete
     *
     * @param DoctrineEvent $event
     */
    public function preDelete($event) {
        air2_fix_src_primary($this, true);
        parent::preDelete($event);
    }

    /**
     * Strip out non-numeric characters
     * 
     * @param Doctrine_Event $event
     */
    public function preValidate($event) {
        $this['sph_number'] = preg_replace('/\D/', '', $this['sph_number']);
        #Carper::carp($this['sph_number']);
        parent::preValidate($event);
    }



}
