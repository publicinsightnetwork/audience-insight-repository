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
require_once APPPATH.'../tests/models/TestOrganization.php';
require_once APPPATH.'../tests/models/TestUser.php';
require_once APPPATH.'../tests/models/TestSavedSearch.php';

plan(36);
AIR2_DBManager::init();

// create test users
$usr = new TestUser();
$usr->save();
$manager = new TestUser();
$manager->save();
$noaccess = new TestUser();
$noaccess->save();

// test organization
$org = new TestOrganization();
$org->add_users(array($usr), 2);     //reader
$org->add_users(array($manager), 4); //manager
$org->save();

// searches
$ss_private = new TestSavedSearch();
$ss_private->ssearch_shared_flag = false;
$ss_private->ssearch_cre_user = $usr->user_id;
$ss_private->save();

$ss_public = new TestSavedSearch();
$ss_public->ssearch_shared_flag = true;
$ss_public->ssearch_cre_user = $usr->user_id;
$ss_public->save();

$ss_noaccess = new TestSavedSearch();
$ss_noaccess->ssearch_shared_flag = true;
$ss_noaccess->ssearch_cre_user = $noaccess->user_id;
$ss_noaccess->save();

// helper to do query counts
function query_count_as($usr, $type="read", $specific) {
    $q = AIR2_Query::create()->from('SavedSearch');
    if ($type == "read")      SavedSearch::query_may_read($q, $usr);
    elseif ($type == "write") SavedSearch::query_may_write($q, $usr);
    else                      throw new Exception("unknown type $type");
    if ($specific)            $q->addWhere("ssearch_id = ?", $specific->ssearch_id);
    return $q->count();
}


/**********************
 * Private SavedSearch
 */
is( $ss_private->user_may_read($usr),       AIR2_AUTHZ_IS_OWNER,  "private - owner read" );
is( $ss_private->user_may_read($manager),   AIR2_AUTHZ_IS_DENIED, "private - manager read" );
is( $ss_private->user_may_read($noaccess),  AIR2_AUTHZ_IS_DENIED, "private - noaccess read" );
is( $ss_private->user_may_write($usr),      AIR2_AUTHZ_IS_OWNER,  "private - owner write" );
is( $ss_private->user_may_write($manager),  AIR2_AUTHZ_IS_DENIED, "private - manager write" );
is( $ss_private->user_may_write($noaccess), AIR2_AUTHZ_IS_DENIED, "private - noaccess write" );

is( query_count_as($usr,      'read',  $ss_private), 1, "private - owner query-read" );
is( query_count_as($manager,  'read',  $ss_private), 0, "private - manager query-read" );
is( query_count_as($noaccess, 'read',  $ss_private), 0, "private - noaccess query-read" );
is( query_count_as($usr,      'write', $ss_private), 1, "private - owner query-write" );
is( query_count_as($manager,  'write', $ss_private), 0, "private - manager query-write" );
is( query_count_as($noaccess, 'write', $ss_private), 0, "private - noaccess query-write" );


/**********************
 * Public SavedSearch
 */
is( $ss_public->user_may_read($usr),       AIR2_AUTHZ_IS_OWNER,  "public - owner read" );
is( $ss_public->user_may_read($manager),   AIR2_AUTHZ_IS_PUBLIC, "public - manager read" );
is( $ss_public->user_may_read($noaccess),  AIR2_AUTHZ_IS_PUBLIC, "public - noaccess read" );
is( $ss_public->user_may_write($usr),      AIR2_AUTHZ_IS_OWNER,  "public - owner write" );
is( $ss_public->user_may_write($manager),  AIR2_AUTHZ_IS_DENIED, "public - manager write" );
is( $ss_public->user_may_write($noaccess), AIR2_AUTHZ_IS_DENIED, "public - noaccess write" );

is( query_count_as($usr,      'read',  $ss_public), 1, "public - owner query-read" );
is( query_count_as($manager,  'read',  $ss_public), 1, "public - manager query-read" );
is( query_count_as($noaccess, 'read',  $ss_public), 1, "public - noaccess query-read" );
is( query_count_as($usr,      'write', $ss_public), 1, "public - owner query-write" );
is( query_count_as($manager,  'write', $ss_public), 0, "public - manager query-write" );
is( query_count_as($noaccess, 'write', $ss_public), 0, "public - noaccess query-write" );


/**********************
 * NoAccess SavedSearch (no shared projects)
 */
is( $ss_noaccess->user_may_read($usr),       AIR2_AUTHZ_IS_PUBLIC, "noaccess - usr read" );
is( $ss_noaccess->user_may_read($manager),   AIR2_AUTHZ_IS_PUBLIC, "noaccess - manager read" );
is( $ss_noaccess->user_may_read($noaccess),  AIR2_AUTHZ_IS_OWNER,  "noaccess - noaccess read" );
is( $ss_noaccess->user_may_write($usr),      AIR2_AUTHZ_IS_DENIED, "noaccess - usr write" );
is( $ss_noaccess->user_may_write($manager),  AIR2_AUTHZ_IS_DENIED, "noaccess - manager write" );
is( $ss_noaccess->user_may_write($noaccess), AIR2_AUTHZ_IS_OWNER,  "noaccess - noaccess write" );

is( query_count_as($usr,      'read',  $ss_noaccess), 1, "noaccess - usr query-read" );
is( query_count_as($manager,  'read',  $ss_noaccess), 1, "noaccess - manager query-read" );
is( query_count_as($noaccess, 'read',  $ss_noaccess), 1, "noaccess - noaccess query-read" );
is( query_count_as($usr,      'write', $ss_noaccess), 0, "noaccess - usr query-write" );
is( query_count_as($manager,  'write', $ss_noaccess), 0, "noaccess - manager query-write" );
is( query_count_as($noaccess, 'write', $ss_noaccess), 1, "noaccess - noaccess query-write" );
