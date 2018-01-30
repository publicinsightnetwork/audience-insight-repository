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
require_once 'models/TestUser.php';

// init db connection
$db = AIR2_DBManager::init();

plan(8);

// test users are automatically deleted when the model is destroyed
$pw = 'MyPasswordHere!';
$user1 = new TestUser();
$user1->user_password = $pw;
$user1->save();

isnt( $user1->user_password, $pw, 'Password encrypted' );

ok( !$user1->check_password('NotMyPassword'), 'Bad password check' );

ok( $user1->check_password($pw), 'Good password check' );


//change password
$user1->user_password = 'changedPassword';

ok( !$user1->check_password($pw), 'Changed password check' );

// transparent upgrade to bcrypt password
$user2 = new TestUser();
$user2->user_password = $pw;
$user2->save();

ok( $user2->user_encrypted_password, 'user_encrypted_password set when setting user_password' );
ok( $user2->check_password($pw), 'user_password check' );
$user2_copy = AIR2_Record::find('User', $user2->user_uuid);
ok( !$user2_copy->user_password, 'user_password unset' );
ok( $user2_copy->user_encrypted_password, 'user_encrypted_password set' );


?>
