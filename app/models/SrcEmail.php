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
 * SrcEmail
 *
 * Email belonging to a Source
 *
 * @property integer $sem_id
 * @property string $sem_uuid
 * @property integer $sem_src_id
 * @property boolean $sem_primary_flag
 * @property string $sem_context
 * @property string $sem_email
 * @property date $sem_effective_date
 * @property date $sem_expire_date
 * @property string $sem_status
 * @property integer $sem_cre_user
 * @property integer $sem_upd_user
 * @property timestamp $sem_cre_dtim
 * @property timestamp $sem_upd_dtim
 * @property Source $Source
 * @author rcavis
 * @package default
 */
class SrcEmail extends AIR2_Record {
    /* code_master values */
    public static $STATUS_GOOD = 'G';
    public static $STATUS_BOUNCED = 'B';
    public static $STATUS_CONFIRMED_BAD = 'C';
    public static $STATUS_UNSUBSCRIBED = 'U';
    public static $CONTEXT_PERSONAL = 'P';
    public static $CONTEXT_WORK = 'W';
    public static $CONTEXT_OTHER = 'O';

    /**
     * Set the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('src_email');
        $this->hasColumn('sem_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('sem_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('sem_src_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sem_primary_flag', 'boolean', null, array(
                'notnull' => true,
                'default' => false,
            ));
        $this->hasColumn('sem_context', 'string', 1, array(
                'fixed' => true,
            ));
        $this->hasColumn('sem_email', 'string', 255, array(
                'notnull' => true,
                'unique'  => true,
            ));
        $this->hasColumn('sem_effective_date', 'date', null, array(

            ));
        $this->hasColumn('sem_expire_date', 'date', null, array(

            ));
        $this->hasColumn('sem_status', 'string', 1, array(
                'fixed' => true,
                'notnull' => true,
                'default' => self::$STATUS_GOOD,
            ));
        $this->hasColumn('sem_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('sem_upd_user', 'integer', 4, array(

            ));
        $this->hasColumn('sem_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('sem_upd_dtim', 'timestamp', null, array(

            ));

        parent::setTableDefinition();
    }


    /**
     * Set table relations
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('Source', array(
                'local' => 'sem_src_id',
                'foreign' => 'src_id',
                'onDelete' => 'CASCADE'
            ));
        $this->hasMany('SrcOrgEmail', array(
                'local'  => 'sem_id',
                'foreign' => 'soe_sem_id',
                'onDelete' => 'CASCADE',
            )
        );
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
        return $this->Source->user_may_write($user, false);
    }


    /**
     * Same as write
     *
     * @param User    $user
     * @return authz integer
     */
    public function user_may_manage(User $user) {
        return $this->user_may_write($user);
    }


    /**
     * Make sure the source doesn't get duplicate sem_emails
     *
     * @param array   $data
     * @param TankSource $tsrc
     * @param unknown $op   (optional)
     */
    public function discriminate($data, &$tsrc, $op=null) {
        // ignore if sem_email isn't set
        if (isset($data['sem_email'])) {
            // search for existing
            if ($op != AIR2_DISCRIM_ADD) {
                $q = $this->getTable()->createQuery();
                $q->where('sem_src_id = ?', $this->sem_src_id);
                $q->andWhere('sem_email = ?', $data['sem_email']);
                $existing_rec = $q->fetchOne(array(), Doctrine::HYDRATE_ARRAY);
                if ($existing_rec) {
                    $this->assignIdentifier($existing_rec['sem_id']);
                    $this->hydrate($existing_rec);
                }
                $q->free(); //cleanup
            }

            // just set primary --- actual logic in postsave hook
            if (isset($data['sem_primary_flag'])) {
                $this->sem_primary_flag = $data['sem_primary_flag'];
                unset($data['sem_primary_flag']);
            }

            // email addresses should ALWAYS be lowercased
            $data['sem_email'] = strtolower($data['sem_email']);
            if ($this->sem_email) {
                $this->sem_email = strtolower($this->sem_email);
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
     * Lowercase any email address
     *
     * @param Doctrine_Event $event
     */
    public function preValidate($event) {
        $this->sem_email = strtolower($this->sem_email);
        parent::preValidate($event);
    }


    /**
     * Override save() to update the parent Source's status
     * and queue any actions necessary.
     *
     * @param object  $conn (optional)
     * @return return value from parent::save($conn)
     */
    public function save(Doctrine_Connection $conn=null) {
        $modified = $this->getModified();
        $ret = parent::save($conn);
        $src = $this->Source;
        $src->set_and_save_src_status();

        // if EITHER the status or email has changed, TODO
        $email_changed  = array_key_exists('sem_email', $modified)  ? $modified['sem_email'] : false;
        $status_changed = array_key_exists('sem_status', $modified) ? $modified['sem_status'] : false;

        return $ret;
    }


}
