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

require_once 'Inquiry.php';
require_once 'trec_utils.php';

/**
* Temporary SrcResponseSet model, along with convenience functionality.
*
* @package default
* @see SrcResponseSet
* @author sgilbertson
**/
class TestSrcResponseSet extends SrcResponseSet {
    /**
    * Public data required for automatic cleanup functionality.
    */
    public static $UUID_COL = 'srs_uuid';
    public static $UUIDS =
    array(
        'TESTSRS1',
        'TESTSRS2',
        'TESTSRS3',
        'TESTSRS4',
        'TESTSRS4S8',
        'TESTSRS9',
        'TESTSRS10',
        'TESTSRS11',
        'TESTSRS12',
        'TESTSRS13',
        'TESTSRS14',
        'TESTSRS15',
        'TESTSRS16',
        'TESTSRS17',
        'TESTSRS18',
        'TESTSRS19',
    );
    public $my_uuid;

    /**
    * Whether to create a SrcActivity record when inserting 'manual entry' Srs records.
    *
    * @var boolean Default false.
    **/
    public $create_activity = false;

    /**
     * Destructor. Makes sure data gets cleaned up.
     *
     * @return void
     * @author sgilbertson
     **/
    public function __destruct() {
        trec_destruct($this);
    }

    /**
    * SrcResponseSet creates activities when inserting a SrcResponseSet.
    * Here, we give callers a chance to not do this, so data isn't left around.
    *
    * @return void
    * @author Sean Gilbertson
    **/
    public function postInsert($ev) {
        if ($this->create_activity) {
            parent::postInsert($ev);
        }
    }

    /**
    * Initialize automatic cleanup functionality.
    *
    * @see trec_make_new()
    * @return void
    * @author sgilbertson
    **/
    public function preInsert() {
        trec_make_new($this);
    }
} // END class TestSrcResponseSet extends SrcResponseSet