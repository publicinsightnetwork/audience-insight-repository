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
 * TestTag
 *
 * @author rcavis
 * @package default
 */
class TestTag extends Tag {

    /**
     * Setup the table columns
     */
    public function setTableDefinition() {
        parent::setTableDefinition();

        // setup mapping for tag_xid
        $this->setSubclasses(
            array('TagTestRecord'  => array('tag_ref_type' => '0'))
        );
    }


}


/**
 * TestTagRecord
 *
 * @author rcavis
 * @package default
 */
class TagTestRecord extends TestTag {

    /**
     * Setup relationships
     */
    public function setUp() {
        parent::setUp();
        $this->setAttribute(Doctrine::ATTR_EXPORT, Doctrine::EXPORT_NONE);
        $this->hasColumn('tag_ref_type', 'string', 1, array('default' => '0'));
        $this->hasOne('TestRecord',
            array('local' => 'tag_xid', 'foreign' => 'test_id', 'onDelete' => 'CASCADE')
        );
    }


}
