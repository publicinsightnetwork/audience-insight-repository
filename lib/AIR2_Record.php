<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
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

require_once "AIR2Logger.php";
require_once 'AirValidHtml.php'; //custom validator extension
require_once 'AirValidNoHtml.php'; //custom validator extension

/**
 * AIR2_Record base class
 *
 * @author pkarman
 * @package default
 */
abstract class AIR2_Record extends Doctrine_Record {

    /* fields which the discriminator will treat as case-insensitive */
    protected static $DISC_CASE_INSENSITIVE_FLDS = array('src_username',
        'src_first_name', 'src_last_name', 'src_middle_initial', 'src_pre_name',
        'src_post_name', 'sa_name', 'sa_first_name', 'sa_last_name', 'sa_post_name',
        'smadd_line_1', 'smadd_line_2', 'smadd_city', 'sf_src_value');


    /**
     * tests validity of the record using the current data.
     *
     * (This is an override of base Doctrine functionality, to fix a bug with validation.)
     *
     * @param boolean $deep  (optional) run the validation process on the relations
     * @param boolean $hooks (optional) invoke save hooks before start
     * @return boolean        whether or not this record is valid
     */
    public function isValid($deep = false, $hooks = true) {
        if ( ! $this->_table->getAttribute(Doctrine_Core::ATTR_VALIDATE)) {
            return true;
        }

        if ($this->_state == self::STATE_LOCKED || $this->_state == self::STATE_TLOCKED) {
            return true;
        }

        if ($hooks) {
            $this->invokeSaveHooks('pre', 'save');
            $this->invokeSaveHooks('pre', $this->exists() ? 'update' : 'insert');
        }

        // Clear the stack from any previous errors.
        $this->getErrorStack()->clear();

        // Run validation process
        $event = new Doctrine_Event($this, Doctrine_Event::RECORD_VALIDATE);
        $this->preValidate($event);
        $this->getTable()->getRecordListener()->preValidate($event);

        if ( ! $event->skipOperation) {

            $validator = new Doctrine_Validator();
            $validator->validateRecord($this);
            $this->validate();
            if ($this->_state == self::STATE_TDIRTY || $this->_state == self::STATE_TCLEAN) {
                $this->validateOnInsert();
            }
            else {
                $this->validateOnUpdate();
            }
        }

        $this->getTable()->getRecordListener()->postValidate($event);
        $this->postValidate($event);

        $valid = $this->getErrorStack()->count() == 0 ? true : false;
        if ($valid && $deep) {
            $stateBeforeLock = $this->_state;
            $this->_state = $this->exists() ? self::STATE_LOCKED : self::STATE_TLOCKED;

            foreach ($this->_references as $reference) {
                if ($reference instanceof Doctrine_Record) {
                    if ( ! $valid = $reference->isValid($deep)) {
                        break;
                    }
                }
                elseif ($reference instanceof Doctrine_Collection) {
                    foreach ($reference as $record) {
                        if ( ! $valid = $record->isValid($deep, $hooks)) {
                            break;
                        }
                    }

                    // Bugfix.
                    if (!$valid) {
                        break;
                    }
                }
            }
            $this->_state = $stateBeforeLock;
        }

        return $valid;
    }


    /**
     * Save the record to the database
     *
     * @param object  $conn (optional)
     */
    public function save( Doctrine_Connection $conn=null ) {
        // unless explicitly passed, we find the _master connection
        // for the current env.
        if ( $conn === null ) {
            $conn = AIR2_DBManager::get_master_connection();
        }
        parent::save($conn);
    }


    /**
     * Insert or update record in the database.
     *
     * @param object  $conn (optional)
     */
    public function replace( Doctrine_Connection $conn=null ) {
        // unless explicitly passed, we find the _master connection
        // for the current env.
        if ( $conn === null ) {
            $conn = AIR2_DBManager::get_master_connection();
        }
        parent::replace($conn);
    }


    /**
     * All AIR2_Record tables should be UTF8
     */
    public function setTableDefinition() {
        // utf8 charset
        $this->option('collate', 'utf8_unicode_ci');
        $this->option('charset', 'utf8');
    }


    /**
     * Detect whether to add CreUser and UpdUser relations
     */
    public function setUp() {
        parent::setUp();

        $cols = $this->getTable()->getColumnNames();
        foreach ($cols as $name) {
            if (preg_match('/_cre_user$/', $name)) {
                $this->hasOne('UserStamp as CreUser',
                    array('local' => $name, 'foreign' => 'user_id')
                );
            }
            elseif (preg_match('/_upd_user$/', $name)) {
                $this->hasOne('UserStamp as UpdUser',
                    array('local' => $name, 'foreign' => 'user_id')
                );
            }
        }
    }



    /**
     * Custom AIR2 validation before update/save
     *
     * @param Doctrine_Event $event
     */
    public function preValidate($event) {
        air2_model_prevalidate($this);
    }


    /**
     * Determines if a record produced from the tank can be safely moved into
     * AIR2, or if it conflicts with existing AIR2 data.
     *
     * @param array   $data
     * @param TankSource $tsrc
     * @param int     $op
     */
    public function discriminate($data, &$tsrc, $op=null) {
        // update the record
        $exists = $this->exists();
        foreach ($data as $key => $val) {
            // trim any incoming string values
            if ($val && is_string($val)) {
                $val = trim($val);
            }

            // always update new records
            if (!$exists) {
                $this->$key = $val;
            }

            // replace NULLs
            elseif (is_null($this->$key)) {
                $this->$key = $val;
            }

            // check for conflict
            elseif ($this->disc_is_conflict($key, $this->$key, $val)) {
                // CONFLICT!  check the $op value
                if ($op == AIR2_DISCRIM_REPLACE) {
                    $this->$key = $val;
                }
                else {
                    $this->disc_add_conflict($tsrc, $key, $this->$key, $val);
                }
            }
        }
    }


    /**
     * Compares 2 values, and determines if there is a conflict.  Returning
     * false will NOT update the field, so do it yourself if that's what you
     * want.
     *
     * @param string  $field
     * @param mixed   $oldval
     * @param mixed   $newval
     * @return boolean
     */
    protected function disc_is_conflict($field, $oldval, $newval) {
        // check for case-insensitive fields
        if (in_array($field, self::$DISC_CASE_INSENSITIVE_FLDS)) {
            $oldval = strtolower($oldval);
            $newval = strtolower($newval);
        }
        $result = ($oldval != $newval); // default php comparison
        return $result;
    }


    /**
     * Add a conflict to the tank_source
     *
     * @param TankSource $tsrc
     * @param string  $field
     * @param mixed   $oldval
     * @param mixed   $newval
     */
    protected function disc_add_conflict($tsrc, $field, $oldval, $newval) {
        $cls = $this->getTable()->getClassnameToReturn();
        $uuidcol = air2_get_model_uuid_col($cls);
        $uuid = $this->$uuidcol;
        $tsrc->add_conflict($cls, $field, 'Conflicting tank value', $uuid);
    }


    /**
     * Determine if a User has permission to read this record.
     *
     * @param User    $u
     * @return authz integer
     */
    public function user_may_read(User $u) {
        throw new Exception('user_may_read not implemented for ' . get_class($this));
        return false;
    }


    /**
     * Determine if a User has permission to write to this record.
     *
     * @param User    $u
     * @return authz integer
     */
    public function user_may_write(User $u) {
        throw new Exception('user_may_write not implemented for ' . get_class($this));
        return false;
    }


    /**
     * Determine if a User has permission to manage this record.
     *
     * @param User    $u
     * @return authz integer
     */
    public function user_may_manage(User $u) {
        throw new Exception('user_may_manage not implemented for ' . get_class($this));
        return false;
    }


    /**
     * Determine if a User has permission delete this record.
     * By default calls through to user_may_manage().
     *
     * @param User    $u
     * @return authz integer
     */
    public function user_may_delete(User $u) {
        return $this->user_may_manage($u);
    }


    /**
     * Record a visit against this record by a given user, at a given IPv4 address.
     *
     * @return void
     * @author sgilbertson
     * @param array   $config Keys: user (@see User); ip (string|int).
     * */
    public function visit($config) {
        $user = null;
        $ip = null;
        extract($config);

        UserVisit::create_visit(
            array(
                'record' => $this,
                'user'   => $user,
                'ip'     => $ip,
            )
        );
    }


    /**
     * Add User reading-authorization conditions to a Doctrine Query.  By
     * default, any restrictions must come from subclasses.
     *
     * @param AIR2_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     */
    public static function query_may_read(AIR2_Query $q, User $u, $alias=null) {
        //TODO: alter query in subclasses
    }


    /**
     * Add User write-authorization conditions to a Doctrine Query.
     * TODO: by default, this is the same as read permissions.
     *
     * @param AIR2_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     */
    public static function query_may_write(AIR2_Query $q, User $u, $alias=null) {
        self::query_may_read($q, $u, $alias);
    }


    /**
     * Add User managing-authorization conditions to a Doctrine Query.
     * TODO: by default, this is the same as write permissions.
     *
     * @param AIR2_Query $q
     * @param User    $u
     * @param string  $alias (optional)
     */
    public static function query_may_manage(AIR2_Query $q, User $u, $alias=null) {
        self::query_may_write($q, $u, $alias);
    }


    /**
     *
     *
     * @param string  $model_name
     * @param string  $uuid
     * @return AIR2_Record object for $model_name
     */
    public static function find($model_name, $uuid) {
        $tbl = Doctrine::getTable($model_name);
        $col = air2_get_model_uuid_col($model_name);
        return $tbl->findOneBy($col, $uuid);
    }


    /**
     * Preinsert hook for transactional activity logging.
     *
     * @param Doctrine_Event $event
     */
    public function preInsert($event) {
        parent::preInsert($event);
        AIR2Logger::log($this, 'insert');
    }


    /**
     * Preupdate hook for transactional activity logging.
     *
     * @param Doctrine_Event $event
     */
    public function preUpdate($event) {
        parent::preUpdate($event);
        AIR2Logger::log($this, 'update');
    }


    /**
     * Postdelete hook for transactional activity logging.
     *
     * @param Doctrine_Event $event
     */
    public function postDelete($event) {
        AIR2Logger::log($this, 'delete');
        parent::postDelete($event);
    }



    /**
     * Returns object as JSON string. Only immediate columns
     * (no related objects) are encoded.
     *
     * @return $json
     */
    public function asJSON() {
        $cols = $this->toArray(false);
        return Encoding::json_encode_utf8($cols);
    }


    /**
     * Custom mutator to reset timestamp to NULL value.
     *
     * @param unknown $field
     * @param timestamp $value
     */
    public function _set_timestamp($field, $value) {
        if (empty($value) || !isset($value)) {
            $this->_set($field, null);
        }
        else {
            $this->_set($field, $value);
        }
    }


}
