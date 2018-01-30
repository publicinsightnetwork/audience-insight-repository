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

require_once 'app/init.php';
require_once APPPATH.'../tests/Test.php';
require_once APPPATH.'../tests/AirHttpTest.php';
require_once APPPATH.'../tests/AirTestUtils.php';
require_once APPPATH.'../tests/models/TestUser.php';
require_once APPPATH.'../tests/models/TestTank.php';

define('MY_TEST_PASS', 'fooBar123.');

plan(6);

AIR2_DBManager::init();

// Create 2 users.
$users = array();
$count = 0;
while ($count++ < 2) {
    $u = new TestUser();
    $u->user_encrypted_password = MY_TEST_PASS;
    $u->save();
    $users[] = $u;
}

// test Tanks
$tanks = array();
$count = 0;
while ($count++ < 3) {
    $t = new TestTank();
    $t->tank_type = Tank::$TYPE_CSV;
    $t->tank_status = Tank::$STATUS_CSV_NEW;
    $tanks[] = $t;
}

$tanks[0]->tank_user_id = $users[0]->user_id;
$tanks[0]->save();
$tanks[1]->tank_user_id = $users[1]->user_id;
$tanks[1]->save();

// actual tests
is( $tanks[0]->user_may_read($users[0]), AIR2_AUTHZ_IS_OWNER, "owner may read");
is( $tanks[1]->user_may_read($users[0]), AIR2_AUTHZ_IS_DENIED, "non-owner may not read");
is( $tanks[0]->user_may_write($users[0]), AIR2_AUTHZ_IS_OWNER, "owner may write");
is( $tanks[1]->user_may_write($users[0]), AIR2_AUTHZ_IS_DENIED, "non-owner may not write");
is( $tanks[0]->user_may_manage($users[0]), AIR2_AUTHZ_IS_OWNER, "owner may manage");
is( $tanks[1]->user_may_manage($users[0]), AIR2_AUTHZ_IS_DENIED, "non-owner may not manage");
