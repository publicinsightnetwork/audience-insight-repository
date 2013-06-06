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
require_once APPPATH.'../tests/models/TestOrganization.php';
require_once APPPATH.'../tests/models/TestProject.php';
require_once APPPATH.'../tests/models/TestInquiry.php';

define('MY_TEST_PASS', 'fooBar123.');

plan(24);

AIR2_DBManager::init();

// Create 4 users in 3 different orgs.
$users = array();
$count = 0;
while ($count++ < 7) {
    $u = new TestUser();
    $u->user_password = MY_TEST_PASS;
    $u->save();
    $users[] = $u;
}

// test Orgs
$orgs = array();
$count = 0;
while ($count++ < 3) {
    $o = new TestOrganization();
    $o->save();
    $orgs[] = $o;
}
$orgs[0]->add_users(array($users[0]));
$orgs[0]->save();
$orgs[1]->add_users(array($users[2]), 3);  // 3==WRITER
$orgs[1]->save();
$orgs[2]->add_users(array($users[3]));
$orgs[2]->add_users(array($users[1]), 3);  // WRITER
$orgs[2]->save();

// parent/child/sibling orgs
$parent = new TestOrganization();
$parent->add_users(array($users[4]), 3); //WRITER
$parent->save();
$orgs[2]->org_parent_id = $parent->org_id;
$orgs[2]->save();
$child = new TestOrganization();
$child->org_parent_id = $orgs[2]->org_id;
$child->add_users(array($users[5]), 4); //WRITER
$child->save();
$sibling = new TestOrganization();
$sibling->org_parent_id = $parent->org_id;
$sibling->add_users(array($users[6]), 4); //WRITER
$sibling->save();

// project
$project = new TestProject();
$project->add_orgs( array( $orgs[1], $orgs[2] ) );
$project->save();

// inquiry
$inquiry = new TestInquiry();
$inquiry->add_projects(array($project));
$inquiry->save();

// actual tests
is( $inquiry->user_may_write( $users[0] ), AIR2_AUTHZ_IS_DENIED,
    "user cannot create new Inquiry for Org to which they do not belong");
is( $inquiry->user_may_write( $users[2] ), AIR2_AUTHZ_IS_ORG,
    "user may create new Inquiry for Org in which they are a WRITER");
is( $inquiry->user_may_write( $users[3] ), AIR2_AUTHZ_IS_DENIED,
    "user may not create new Inquiry if they are not a WRITER in the assigned Org");
is( $inquiry->user_may_manage( $users[2] ), AIR2_AUTHZ_IS_MANAGER,
    "user who is contact for a Project an Inquiry belongs to may manage it");
is( $inquiry->user_may_manage( $users[3] ), AIR2_AUTHZ_IS_DENIED,
    "users[3] may not manage Inquiry where they cannot even write");

// test child org
is($inquiry->user_may_read($users[4]), AIR2_AUTHZ_IS_ORG,
    "users[4] may read child orgs inquiry");
is($inquiry->user_may_write($users[4]), AIR2_AUTHZ_IS_ORG,
    "users[4] may write child orgs inquiry");

// test parent org
is($inquiry->user_may_read($users[5]), AIR2_AUTHZ_IS_ORG,
    "users[5] may read parent orgs inquiry");
is($inquiry->user_may_write($users[5]), AIR2_AUTHZ_IS_DENIED,
    "users[5] may not write parent orgs inquiry");

// test sibling org
is($inquiry->user_may_read($users[6]), AIR2_AUTHZ_IS_DENIED,
    "users[6] may not read sibling orgs inquiry");
is($inquiry->user_may_write($users[6]), AIR2_AUTHZ_IS_DENIED,
    "users[6] may not write sibling orgs inquiry");

// query authz
$q = AIR2_Query::create()->from('Inquiry i');
Inquiry::query_may_read($q, $users[0]);
is($q->count(), 0, "users[0] may not see inquiry with unshared parent Project");

$q = AIR2_Query::create()->from('Inquiry i');
Inquiry::query_may_read($q, $users[2]);
is($q->count(), 1, "users[2] may read inquiry since they belong to parent Project");

$q = AIR2_Query::create()->from('Inquiry i');
Inquiry::query_may_read($q, $users[3]);
is($q->count(), 1, "users[3] may read inquiry since they belong to parent Project");

$q = AIR2_Query::create()->from('Inquiry i');
Inquiry::query_may_write($q, $users[2]);
is( $q->count(), 1, "users[2] may write to the project inquiry they are in");

$q = AIR2_Query::create()->from('Inquiry i');
Inquiry::query_may_write($q, $users[3]);
is( $q->count(), 0, "users[3] may not write to shared project inquiries"); // TODO rules are not clear on this

$q = AIR2_Query::create()->from('Inquiry i');
Inquiry::query_may_manage($q, $users[2]);
is( $q->count(), 1, "users[2] may manage project inquiries where they are primary contact");

$q = AIR2_Query::create()->from('Inquiry i');
Inquiry::query_may_manage($q, $users[3]);
is( $q->count(), 0, "users[3] may not manage shared project inquiries");

// query child
$q = AIR2_Query::create()->from('Inquiry i');
Inquiry::query_may_read($q, $users[4]);
is( $q->count(), 1, "users[4] may query-read child orgs inquiry");
$q = AIR2_Query::create()->from('Inquiry i');
Inquiry::query_may_write($q, $users[4]);
is( $q->count(), 1, "users[4] may query-write child orgs inquiry");

// query parent
$q = AIR2_Query::create()->from('Inquiry i');
Inquiry::query_may_read($q, $users[5]);
is( $q->count(), 1, "users[5] may query-read parent orgs inquiry");
$q = AIR2_Query::create()->from('Inquiry i');
Inquiry::query_may_write($q, $users[5]);
is( $q->count(), 0, "users[5] may not query-write parent orgs inquiry");

// query siblings
$q = AIR2_Query::create()->from('Inquiry i');
Inquiry::query_may_read($q, $users[6]);
is( $q->count(), 0, "users[6] may not query-read sibling orgs inquiry");
$q = AIR2_Query::create()->from('Inquiry i');
Inquiry::query_may_write($q, $users[6]);
is( $q->count(), 0, "users[6] may not query-write sibling orgs inquiry");
