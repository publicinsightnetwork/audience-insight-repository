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

require_once 'TestRecord.php';

/**
 * TestRelatedRecord
 *
 * @property integer $tr_id
 * @property integer $tr_test_id
 * @property string $tr_uuid
 * @property string $tr_string_1
 * @property string $tr_string_2
 * @property TestRecord $TestRecord
 * @author rcavis
 * @package default
 */
class TestRelatedRecord extends AIR2_Record {

    /**
     * Setup the table columns
     */
    public function setTableDefinition() {
        $this->setTableName('test_related');
        $this->hasColumn('tr_id', 'integer', 4, array(
                'primary' => true,
                'autoincrement' => true,
            ));
        $this->hasColumn('tr_test_id', 'integer', 4, array(
                'notnull' => true,
            ));
        $this->hasColumn('tr_uuid', 'string', 12, array(
                'fixed' => true,
                'notnull' => true,
                'unique' => true,
            ));
        $this->hasColumn('tr_string_1', 'string', 128, array(
            ));
        $this->hasColumn('tr_string_2', 'string', 128, array(
            ));

        parent::setTableDefinition();
    }


    /**
     * Setup relationships
     */
    public function setUp() {
        parent::setUp();
        $this->hasOne('TestRecord', array(
                'local' => 'tr_test_id',
                'foreign' => 'test_id'
            ));
    }


    /**
     *
     *
     * @param unknown $user
     * @return unknown
     */
    public function user_may_read($user) {
        if ($this->TestRecord->test_cre_user == $user->user_id) {
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
