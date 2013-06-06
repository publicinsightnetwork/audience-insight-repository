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
 * Assumes slave as configured is unavailable, so automatic roll over to master.
 */

plan(5);

ok( AIR2_DBManager::init('nosuchdbhost'), "init db handles");

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

// we are using master for everything
ok( $master = AIR2_DBManager::get_master_connection(), "get master");
ok( $slave  = AIR2_DBManager::get_slave_connection(), "get slave");
is( AIR2_DBManager::get_name($master), AIR2_DBManager::get_name($slave),
   "master == slave");
//diag(AIR2_DBManager::get_name($master));

?>
