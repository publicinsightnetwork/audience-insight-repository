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
require_once APPPATH.'../tests/AirTestUtils.php';
require_once APPPATH.'../tests/models/TestUser.php';
require_once APPPATH.'../tests/models/TestOrganization.php';

plan(23);

AIR2_DBManager::init();

// create test users
$usr1_reader = new TestUser();
$usr1_reader->save();
$usr2_writer = new TestUser();
$usr2_writer->save();
$usr3_manager = new TestUser();
$usr3_manager->save();
$usr4_nonmember = new TestUser();
$usr4_nonmember->save();

// Organization
$org = new TestOrganization();
$org->add_users(array($usr1_reader),  2); //READER
$org->add_users(array($usr2_writer),  3); //WRITER
$org->add_users(array($usr3_manager), 4); //MANAGER
$org->save();

// child/parent/sibling users
$parent_usr = new TestUser();
$parent_usr->save();
$child_usr = new TestUser();
$child_usr->save();
$sibling_usr = new TestUser();
$sibling_usr->save();

// child/parent/sibling orgs
$parent = new TestOrganization();
$parent->add_users(array($parent_usr), 4); //MANAGER
$parent->save();
$org->org_parent_id = $parent->org_id;
$org->save();
$child = new TestOrganization();
$child->org_parent_id = $org->org_id;
$child->add_users(array($child_usr), 4); //MANAGER
$child->save();
$sibling = new TestOrganization();
$sibling->org_parent_id = $parent->org_id;
$sibling->add_users(array($sibling_usr), 4); //MANAGER
$sibling->save();

// we'll test this out on $usr1_reader
$uo = $usr1_reader->UserOrg[0];
$uo->uo_user_title = 'testtesttest';
$uo->uo_notify_flag = true;
$uo->uo_home_flag = true;

/**********************
 * Test record authz
 */
is( $uo->user_may_read($usr1_reader),   AIR2_AUTHZ_IS_PUBLIC, "usr1 - read");
is( $uo->user_may_write($usr1_reader),  AIR2_AUTHZ_IS_OWNER,  "usr1 - write title");
is( $uo->user_may_manage($usr1_reader), AIR2_AUTHZ_IS_OWNER,  "usr1 - manage title");

// change a disallowed field
$uo->uo_ar_id = 3; //CAUTION: this is a cached record!
is( $uo->user_may_write($usr1_reader),  AIR2_AUTHZ_IS_DENIED,  "usr1 - no write ar_id");
is( $uo->user_may_manage($usr1_reader), AIR2_AUTHZ_IS_DENIED,  "usr1 - no manage ar_id");

is( $uo->user_may_read($usr2_writer),   AIR2_AUTHZ_IS_PUBLIC, "usr2 - read");
is( $uo->user_may_write($usr2_writer),  AIR2_AUTHZ_IS_DENIED, "usr2 - no write");
is( $uo->user_may_manage($usr2_writer), AIR2_AUTHZ_IS_DENIED, "usr2 - no manage");

is( $uo->user_may_read($usr3_manager),   AIR2_AUTHZ_IS_PUBLIC,  "usr3 - read");
is( $uo->user_may_write($usr3_manager),  AIR2_AUTHZ_IS_MANAGER, "usr3 - write");
is( $uo->user_may_manage($usr3_manager), AIR2_AUTHZ_IS_MANAGER, "usr3 - manage");

is( $uo->user_may_read($usr4_nonmember),   AIR2_AUTHZ_IS_PUBLIC, "usr4 - read");
is( $uo->user_may_write($usr4_nonmember),  AIR2_AUTHZ_IS_DENIED, "usr4 - no write");
is( $uo->user_may_manage($usr4_nonmember), AIR2_AUTHZ_IS_DENIED, "usr4 - no manage");

/**********************
 * Test parent/child/sibling authz
 */
is( $uo->user_may_read($parent_usr),    AIR2_AUTHZ_IS_PUBLIC,  "parent - read");
is( $uo->user_may_write($parent_usr),   AIR2_AUTHZ_IS_MANAGER, "parent - write");
is( $uo->user_may_manage($parent_usr),  AIR2_AUTHZ_IS_MANAGER, "parent - manage");

is( $uo->user_may_read($child_usr),     AIR2_AUTHZ_IS_PUBLIC, "child - read");
is( $uo->user_may_write($child_usr),    AIR2_AUTHZ_IS_DENIED, "child - write");
is( $uo->user_may_manage($child_usr),   AIR2_AUTHZ_IS_DENIED, "child - manage");

is( $uo->user_may_read($sibling_usr),   AIR2_AUTHZ_IS_PUBLIC, "sibling - read");
is( $uo->user_may_write($sibling_usr),  AIR2_AUTHZ_IS_DENIED, "sibling - write");
is( $uo->user_may_manage($sibling_usr), AIR2_AUTHZ_IS_DENIED, "sibling - manage");
