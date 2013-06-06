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

require_once 'TestRelatedRecord.php';
require_once 'TestTag.php';

/**
 * TestRecord
 *
 * @property integer $test_id
 * @property string $test_uuid
 * @property string $test_string
 * @property integer $test_cre_user
 * @property integer $test_upd_user
 * @property timestamp $test_cre_dtim
 * @property timestamp $test_upd_dtim
 * @property Doctrine_Collection $TestRelatedRecord
 * @author rcavis
 * @package default
 */
class TestRecord extends AIR2_Record {

    /**
     * Setup the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('test');
        $this->hasColumn('test_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('test_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('test_string', 'string', 128, array(
            ));

        // for testing cre/upd user/time stamps
        $this->hasColumn('test_cre_user', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('test_upd_user', 'integer', 4, array(
            ));
        $this->hasColumn('test_cre_dtim', 'timestamp', null, array(
                'notnull' => true,
            ));
        $this->hasColumn('test_upd_dtim', 'timestamp', null, array(
            ));

        parent::setTableDefinition();
    }


    /**
     * Setup relationships
     */
    public function setUp() {
        parent::setUp();
        $this->hasMany('TestRelatedRecord', array(
                'local' => 'test_id',
                'foreign' => 'tr_test_id'
            ));

        // Tagging
        $this->hasMany('TagTestRecord as Tags', array(
                'local' => 'test_id',
                'foreign' => 'tag_xid'
            ));
    }


    /**
     *
     *
     * @param unknown $user
     * @return unknown
     */
    public function user_may_read($user) {
        if ($this->test_cre_user == $user->user_id) {
            return AIR2_AUTHZ_IS_OWNER;
        }

        return AIR2_AUTHZ_IS_DENIED;
    }


    /**
     *
     *
     * @param unknown $user
     * @return unknown
     */
    public function user_may_write($user) {
        if (!$this->test_id) {
            return AIR2_AUTHZ_IS_NEW;
        }
        return $this->user_may_read($user);
    }


    /**
     *
     *
     * @param unknown $user
     * @return unknown
     */
    public function user_may_manage($user) {
        return $this->user_may_write($user);
    }


}
