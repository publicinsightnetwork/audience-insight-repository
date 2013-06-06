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
require_once APPPATH.'../tests/models/TestSource.php';
require_once APPPATH.'../tests/AirTestUtils.php';
require_once APPPATH.'../tests/models/TestUser.php';
require_once APPPATH.'../tests/models/TestOrganization.php';

plan(49);

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
$usr5_rdplus = new TestUser();
$usr5_rdplus->save();

// Organization
$org = new TestOrganization();
$org->add_users(array($usr1_reader),  2); //READER
$org->add_users(array($usr2_writer),  3); //WRITER
$org->add_users(array($usr3_manager), 4); //MANAGER
$org->add_users(array($usr5_rdplus), 6);  //READERPLUS
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
$parent->add_users(array($child_usr)); //READER
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

/**********************
 * Test record authz
 */
is( $org->user_may_read($usr1_reader),   AIR2_AUTHZ_IS_PUBLIC, "usr1 - read");
is( $org->user_may_write($usr1_reader),  AIR2_AUTHZ_IS_DENIED, "usr1 - no write");
is( $org->user_may_manage($usr1_reader), AIR2_AUTHZ_IS_DENIED, "usr1 - no manage");

is( $org->user_may_read($usr2_writer),   AIR2_AUTHZ_IS_PUBLIC, "usr2 - read");
is( $org->user_may_write($usr2_writer),  AIR2_AUTHZ_IS_DENIED, "usr2 - no write");
is( $org->user_may_manage($usr2_writer), AIR2_AUTHZ_IS_DENIED, "usr2 - no manage");

is( $org->user_may_read($usr3_manager),   AIR2_AUTHZ_IS_PUBLIC,  "usr3 - read");
is( $org->user_may_write($usr3_manager),  AIR2_AUTHZ_IS_MANAGER, "usr3 - write");
is( $org->user_may_manage($usr3_manager), AIR2_AUTHZ_IS_MANAGER, "usr3 - manage");

is( $org->user_may_read($usr4_nonmember),   AIR2_AUTHZ_IS_PUBLIC, "usr4 - read");
is( $org->user_may_write($usr4_nonmember),  AIR2_AUTHZ_IS_DENIED, "usr4 - no write");
is( $org->user_may_manage($usr4_nonmember), AIR2_AUTHZ_IS_DENIED, "usr4 - no manage");

is( $org->user_may_read($usr5_rdplus),   AIR2_AUTHZ_IS_PUBLIC, "usr5 - read");
is( $org->user_may_write($usr5_rdplus),  AIR2_AUTHZ_IS_DENIED, "usr5 - no write");
is( $org->user_may_manage($usr5_rdplus), AIR2_AUTHZ_IS_DENIED, "usr5 - no manage");

/**********************
 * Test org creation
 */
$new_org = new TestOrganization();
is( $new_org->user_may_write($usr1_reader),    AIR2_AUTHZ_IS_DENIED, "usr1 - no create");
is( $new_org->user_may_write($usr2_writer),    AIR2_AUTHZ_IS_DENIED, "usr2 - no create");
is( $new_org->user_may_write($usr3_manager),   AIR2_AUTHZ_IS_DENIED, "usr3 - no create");
is( $new_org->user_may_write($usr4_nonmember), AIR2_AUTHZ_IS_DENIED, "usr4 - no create");

// add parent
$new_org->org_parent_id = $org->org_id;
is( $new_org->user_may_write($usr1_reader),    AIR2_AUTHZ_IS_DENIED,  "usr1 - no create");
is( $new_org->user_may_write($usr2_writer),    AIR2_AUTHZ_IS_DENIED,  "usr2 - no create");
is( $new_org->user_may_write($usr3_manager),   AIR2_AUTHZ_IS_MANAGER, "usr3 - create!");
is( $new_org->user_may_write($usr4_nonmember), AIR2_AUTHZ_IS_DENIED,  "usr4 - no create");

/**********************
 * Test parent/child/sibling authz
 */
is( $org->user_may_read($parent_usr),       AIR2_AUTHZ_IS_PUBLIC,  "parent - read");
is( $org->user_may_write($parent_usr),      AIR2_AUTHZ_IS_MANAGER, "parent - write");
is( $org->user_may_manage($parent_usr),     AIR2_AUTHZ_IS_MANAGER, "parent - manage");
is( $new_org->user_may_manage($parent_usr), AIR2_AUTHZ_IS_MANAGER, "parent - create");

is( $org->user_may_read($child_usr),       AIR2_AUTHZ_IS_PUBLIC, "child - read");
is( $org->user_may_write($child_usr),      AIR2_AUTHZ_IS_DENIED, "child - write");
is( $org->user_may_manage($child_usr),     AIR2_AUTHZ_IS_DENIED, "child - manage");
is( $new_org->user_may_manage($child_usr), AIR2_AUTHZ_IS_DENIED, "child - create");

is( $org->user_may_read($sibling_usr),       AIR2_AUTHZ_IS_PUBLIC, "sibling - read");
is( $org->user_may_write($sibling_usr),      AIR2_AUTHZ_IS_DENIED, "sibling - write");
is( $org->user_may_manage($sibling_usr),     AIR2_AUTHZ_IS_DENIED, "sibling - manage");
is( $new_org->user_may_manage($sibling_usr), AIR2_AUTHZ_IS_DENIED, "sibling - create");

/**********************
 * Test changing org_name
 */
$o2 = new TestOrganization();
$o2->org_parent_id = $org->org_id;
is( $o2->user_may_write($usr3_manager), AIR2_AUTHZ_IS_MANAGER, "org_name - create new");
$o2->save();

Organization::clear_org_map();
$usr3_manager->clear_authz();
$o2->org_display_name = 'new display name';
is( $o2->user_may_write($usr3_manager), AIR2_AUTHZ_IS_MANAGER, "org_name - write display");
$o2->org_name = 'new name';
is( $o2->user_may_write($usr3_manager), AIR2_AUTHZ_IS_DENIED, "org_name - write display");
$o2->delete();

/**********************
 * Brief test of query authz
 */
$q = AIR2_Query::create()->from('Organization');
Organization::query_may_read($q, $usr1_reader);
ok( $q->count() >= 1, "usr1 - query read");
$q = AIR2_Query::create()->from('Organization');
Organization::query_may_write($q, $usr1_reader);
is( $q->count(), 0, "usr1 - no query write");

$q = AIR2_Query::create()->from('Organization');
Organization::query_may_write($q, $usr2_writer);
is( $q->count(), 0, "usr2 - no query write");

$q = AIR2_Query::create()->from('Organization');
Organization::query_may_write($q, $usr3_manager);
is( $q->count(), 2, "usr3 - query write");

$q = AIR2_Query::create()->from('Organization');
Organization::query_may_write($q, $parent_usr);
is( $q->count(), 4, "parent - query write");

$q = AIR2_Query::create()->from('Organization');
Organization::query_may_write($q, $child_usr);
is( $q->count(), 1, "child - query write");

$q = AIR2_Query::create()->from('Organization');
Organization::query_may_write($q, $sibling_usr);
is( $q->count(), 1, "sibling - query write");

/**********************
 * Test authz on setting org_max_users
 */
is( $org->user_may_write($usr3_manager), AIR2_AUTHZ_IS_MANAGER, "org manager - may normally write");
is( $org->user_may_write($parent_usr),   AIR2_AUTHZ_IS_MANAGER, "parent manager - may normally write");
$org->org_max_users = 10;
is( $org->user_may_write($usr3_manager), AIR2_AUTHZ_IS_DENIED,  "org manager - may NOT write org_max_users");
is( $org->user_may_write($parent_usr),   AIR2_AUTHZ_IS_MANAGER, "parent manager - may write org_max_users");