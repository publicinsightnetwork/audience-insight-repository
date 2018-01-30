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

define('MY_TEST_PASS', 'fooBar123.');

//plan('no plan');
plan(34);

AIR2_DBManager::init();

// Create 4 users in 3 different orgs.
$users = array();
$count = 0;
while ($count++ < 8) {
    $u = new TestUser();
    $u->user_encrypted_password = MY_TEST_PASS;
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
$orgs[1]->add_users(array($users[2]), 4);  // MANAGER
$orgs[1]->save();
$orgs[2]->add_users(array($users[3]));
$orgs[2]->add_users(array($users[1]), 3);  // WRITER
$orgs[2]->add_users(array($users[7]), 6);  // READERPLUS
$orgs[2]->save();

// parent/child/sibling orgs
$parent = new TestOrganization();
$parent->add_users(array($users[4]), 4); //MANAGER
$parent->save();
$orgs[2]->org_parent_id = $parent->org_id;
$orgs[2]->save();
$child = new TestOrganization();
$child->org_parent_id = $orgs[2]->org_id;
$child->add_users(array($users[5]), 4); //MANAGER
$child->save();
$sibling = new TestOrganization();
$sibling->org_parent_id = $parent->org_id;
$sibling->add_users(array($users[6]), 4); //MANAGER
$sibling->save();

// source
$source = new TestSource();
$source->save();
$source->add_orgs(array($orgs[1], $orgs[2]));
$source->save();

//actual tests
is($source->user_may_read($users[1]), AIR2_AUTHZ_IS_ORG,
    "users[1] may read Source if associated by Organization");
is($source->user_may_read($users[0]), AIR2_AUTHZ_IS_DENIED,
    "users[0] may not read if not associated by Organizatio");
is($source->user_may_write($users[1]), AIR2_AUTHZ_IS_ORG,
    "users[1] may write if in Organization and WRITER");
is($source->user_may_write($users[3]), AIR2_AUTHZ_IS_DENIED,
    "users[3] may not write if not in Organization");
is($source->user_may_write($users[7]), AIR2_AUTHZ_IS_ORG,
    "users[7] may write with readerplus role");
is($source->user_may_manage($users[2]), AIR2_AUTHZ_IS_ORG,
    "user[2] in organization may manage.");
is($source->user_may_manage($users[3]), AIR2_AUTHZ_IS_DENIED,
    "users[3] may not manange if they cannot even write");
is($source->user_may_manage($users[7]), AIR2_AUTHZ_IS_DENIED,
    "users[7] may not manage with readerplus role");

// test child org
is($source->user_may_read($users[4]), AIR2_AUTHZ_IS_ORG,
    "users[4] may read child orgs sources");
is($source->user_may_write($users[4]), AIR2_AUTHZ_IS_ORG,
    "users[4] may write child orgs sources");
is($source->user_may_manage($users[4]), AIR2_AUTHZ_IS_ORG,
    "users[4] may manage child orgs sources");

// test parent org
is($source->user_may_read($users[5]), AIR2_AUTHZ_IS_ORG,
    "users[5] may read parent orgs sources");
is($source->user_may_write($users[5]), AIR2_AUTHZ_IS_ORG,
    "users[5] may write parent orgs sources");
is($source->user_may_manage($users[5]), AIR2_AUTHZ_IS_ORG,
    "users[5] may manage parent orgs sources");

// test sibling org
is($source->user_may_read($users[6]), AIR2_AUTHZ_IS_DENIED,
    "users[6] may not read sibling orgs sources");
is($source->user_may_write($users[6]), AIR2_AUTHZ_IS_DENIED,
    "users[6] may not write sibling orgs sources");
is($source->user_may_manage($users[6]), AIR2_AUTHZ_IS_DENIED,
    "users[6] may not manage sibling orgs sources");

// test querying
$q = AIR2_Query::create();
$q->from('Source s');
Source::query_may_read($q, $users[0]);
is( $q->count(), 0, "users[0] may not view if not associated by org.");

$q = AIR2_Query::create();
$q->from('Source s');
Source::query_may_read($q, $users[3]);
is( $q->count(), 1, "users[3] may view if associated by org.");

$q = AIR2_Query::create();
$q->from('Source s');
Source::query_may_write($q, $users[3]);
is( $q->count(), 0, "users[3] may not write if not associated by org.");

$q = AIR2_Query::create();
$q->from('Source s');
Source::query_may_write($q, $users[1]);
is( $q->count(), 1, "users[1] may write if associated by org and writer.");

$q = AIR2_Query::create();
$q->from('Source s');
Source::query_may_write($q, $users[7]);
is( $q->count(), 1, "users[7] may write with readerplus role.");

$q = AIR2_Query::create();
$q->from('Source s');
Source::query_may_manage($q, $users[1]);
is( $q->count(), 0, "users[1] may not manage if associated by org but not manager");

$q = AIR2_Query::create();
$q->from('Source s');
Source::query_may_manage($q, $users[2]);
is( $q->count(), 1, "users[2] may write if associated by org and writer.");

$q = AIR2_Query::create();
$q->from('Source s');
Source::query_may_manage($q, $users[7]);
is( $q->count(), 0, "users[7] may not manage with readerplus role.");

// query child
$q = AIR2_Query::create()->from('Source s');
Source::query_may_read($q, $users[4]);
is( $q->count(), 1, "users[4] may query-read child orgs sources");
$q = AIR2_Query::create()->from('Source s');
Source::query_may_write($q, $users[4]);
is( $q->count(), 1, "users[4] may query-write child orgs sources");
$q = AIR2_Query::create()->from('Source s');
Source::query_may_manage($q, $users[4]);
is( $q->count(), 1, "users[4] may query-manage child orgs sources");

// query parent
$q = AIR2_Query::create()->from('Source s');
Source::query_may_read($q, $users[5]);
is( $q->count(), 1, "users[5] may query-read parent orgs sources");
$q = AIR2_Query::create()->from('Source s');
Source::query_may_write($q, $users[5]);
is( $q->count(), 1, "users[5] may query-write parent orgs sources");
$q = AIR2_Query::create()->from('Source s');
Source::query_may_manage($q, $users[5]);
is( $q->count(), 1, "users[5] may query-manage parent orgs sources");

// query siblings
$q = AIR2_Query::create()->from('Source s');
Source::query_may_read($q, $users[6]);
is( $q->count(), 0, "users[6] may not query-read sibling orgs sources");
$q = AIR2_Query::create()->from('Source s');
Source::query_may_write($q, $users[6]);
is( $q->count(), 0, "users[6] may not query-write sibling orgs sources");
$q = AIR2_Query::create()->from('Source s');
Source::query_may_manage($q, $users[6]);
is( $q->count(), 0, "users[6] may not query-manage sibling orgs sources");
