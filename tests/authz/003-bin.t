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
require_once APPPATH.'../tests/models/TestOrganization.php';
require_once APPPATH.'../tests/models/TestUser.php';
require_once APPPATH.'../tests/models/TestBin.php';
require_once APPPATH.'../tests/models/TestSource.php';

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

// Create test Source to place in a Bin
$source = new TestSource();
$source->add_orgs(array($org));
$source->save();

// bins
$b_private = new TestBin();
$b_private->bin_user_id = $usr->user_id;
$b_private->bin_shared_flag = false;
$b_private->BinSource[]->bsrc_src_id = $source->src_id;
$b_private->save();

$b_public = new TestBin();
$b_public->bin_user_id = $usr->user_id;
$b_public->bin_shared_flag = true;
$b_public->BinSource[]->bsrc_src_id = $source->src_id;
$b_public->save();

$b_noaccess = new TestBin();
$b_noaccess->bin_user_id = $noaccess->user_id;
$b_noaccess->bin_shared_flag = true;
$b_noaccess->BinSource[]->bsrc_src_id = $source->src_id;
$b_noaccess->save();

// helper to do query counts
function query_count_as($usr, $type="read", $specific) {
    $q = AIR2_Query::create()->from('Bin');
    if ($type == "read")      Bin::query_may_read($q, $usr);
    elseif ($type == "write") Bin::query_may_write($q, $usr);
    else                      throw new Exception("unknown type $type");
    if ($specific)            $q->addWhere("bin_id = ?", $specific->bin_id);
    return $q->count();
}


/**********************
 * Private Bin
 */
is( $b_private->user_may_read($usr),       AIR2_AUTHZ_IS_OWNER,  "private - owner read" );
is( $b_private->user_may_read($manager),   AIR2_AUTHZ_IS_DENIED, "private - manager read" );
is( $b_private->user_may_read($noaccess),  AIR2_AUTHZ_IS_DENIED, "private - noaccess read" );
is( $b_private->user_may_write($usr),      AIR2_AUTHZ_IS_OWNER,  "private - owner write" );
is( $b_private->user_may_write($manager),  AIR2_AUTHZ_IS_DENIED, "private - manager write" );
is( $b_private->user_may_write($noaccess), AIR2_AUTHZ_IS_DENIED, "private - noaccess write" );

is( query_count_as($usr,      'read',  $b_private), 1, "private - owner query-read" );
is( query_count_as($manager,  'read',  $b_private), 0, "private - manager query-read" );
is( query_count_as($noaccess, 'read',  $b_private), 0, "private - noaccess query-read" );
is( query_count_as($usr,      'write', $b_private), 1, "private - owner query-write" );
is( query_count_as($manager,  'write', $b_private), 0, "private - manager query-write" );
is( query_count_as($noaccess, 'write', $b_private), 0, "private - noaccess query-write" );


/**********************
 * Public Bin
 */
is( $b_public->user_may_read($usr),       AIR2_AUTHZ_IS_OWNER,  "public - owner read" );
is( $b_public->user_may_read($manager),   AIR2_AUTHZ_IS_PUBLIC, "public - manager read" );
is( $b_public->user_may_read($noaccess),  AIR2_AUTHZ_IS_PUBLIC, "public - noaccess read" );
is( $b_public->user_may_write($usr),      AIR2_AUTHZ_IS_OWNER,  "public - owner write" );
is( $b_public->user_may_write($manager),  AIR2_AUTHZ_IS_DENIED, "public - manager write" );
is( $b_public->user_may_write($noaccess), AIR2_AUTHZ_IS_DENIED, "public - noaccess write" );

is( query_count_as($usr,      'read',  $b_public), 1, "public - owner query-read" );
is( query_count_as($manager,  'read',  $b_public), 1, "public - manager query-read" );
is( query_count_as($noaccess, 'read',  $b_public), 1, "public - noaccess query-read" );
is( query_count_as($usr,      'write', $b_public), 1, "public - owner query-write" );
is( query_count_as($manager,  'write', $b_public), 0, "public - manager query-write" );
is( query_count_as($noaccess, 'write', $b_public), 0, "public - noaccess query-write" );


/**********************
 * NoAccess Bin
 */
is( $b_noaccess->user_may_read($usr),       AIR2_AUTHZ_IS_PUBLIC, "noaccess - usr read" );
is( $b_noaccess->user_may_read($manager),   AIR2_AUTHZ_IS_PUBLIC, "noaccess - manager read" );
is( $b_noaccess->user_may_read($noaccess),  AIR2_AUTHZ_IS_OWNER,  "noaccess - noaccess read" );
is( $b_noaccess->user_may_write($usr),      AIR2_AUTHZ_IS_DENIED, "noaccess - usr write" );
is( $b_noaccess->user_may_write($manager),  AIR2_AUTHZ_IS_DENIED, "noaccess - manager write" );
is( $b_noaccess->user_may_write($noaccess), AIR2_AUTHZ_IS_OWNER,  "noaccess - noaccess write" );

is( query_count_as($usr,      'read',  $b_noaccess), 1, "noaccess - usr query-read" );
is( query_count_as($manager,  'read',  $b_noaccess), 1, "noaccess - manager query-read" );
is( query_count_as($noaccess, 'read',  $b_noaccess), 1, "noaccess - noaccess query-read" );
is( query_count_as($usr,      'write', $b_noaccess), 0, "noaccess - usr query-write" );
is( query_count_as($manager,  'write', $b_noaccess), 0, "noaccess - manager query-write" );
is( query_count_as($noaccess, 'write', $b_noaccess), 1, "noaccess - noaccess query-write" );
