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

/*
 * Script to check the availability of a doctrine connection.
 *
 */

plan(5);

ok( AIR2_DBManager::init(), "init db handles");

// test connection
$conn = AIR2_DBManager::get_master_connection();
try {
    $res = $conn->connect();
    //diag( $air2_dbmanager->get_name($conn) );
    pass('Doctrine db-connect test');
} catch (Doctrine_Connection_Exception $e) {
    fail('Doctrine db-connect test');
    diag("    ".$e->getMessage());
}

// test replication
// NOTE that if this environment is not configured with a *_master profile
// then this test is a no-op 
if (!AIR2_DBManager::uses_replication()) {
    pass("replication not in effect");
}
else {

    // writing to the slave should throw an exception
    $slave = AIR2_DBManager::get_slave_connection();
    try {
        $slave->execute("create table nowaycanibewritten()");
    }
    catch (Doctrine_Connection_Exception $e) {
        ok( $e, "caught exception trying to write to slave");
    }
}

// verify Doctrine "conservative" loading model feature
ok( !in_array('User', get_declared_classes()), "User class does not yet exist");
ok( $user = new User(), "class exists on use");


?>
