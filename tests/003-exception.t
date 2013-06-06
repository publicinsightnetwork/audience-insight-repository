#!/usr/bin/env php
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

require_once 'Test.php';
require_once 'app/init.php';
require_once 'AIR2_DBManager.php';
require_once 'models/TestSystemMessage.php';
require_once 'AIR2_Exception.php';

// init db connection
$db = AIR2_DBManager::init();

plan(4);

// test system messages are automatically deleted
// when the objects are destroyed.

/******************************************************
 * basic test for db fetch and stringification
 */
//diag("new TestSystemMessage");
$sysmsg1 = TestSystemMessage::make_new(123456, 'Something is wrong.');
ok( $exception = new AIR2_Exception($sysmsg1->smsg_id),
    "new AIR2_Exception");

is( "$exception", 'Error [123456]: Something is wrong.',
    "stringify exception");

/*******************************************************
 * sprintf() support
 */
$sysmsg2 = TestSystemMessage::make_new(234567, 'Something is wrong with %s and %s.');

ok( $exception = new AIR2_Exception($sysmsg2->smsg_id, array('foo', 'bar')),
    "new AIR2_Exception with sprintf");
is( "$exception", 'Error [234567]: Something is wrong with foo and bar.',
    "stringify exception");

?>
