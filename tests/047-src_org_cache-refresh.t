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
require_once 'AirTestUtils.php';
require_once 'models/TestProject.php';
require_once 'models/TestOrganization.php';
require_once 'models/TestUser.php';
require_once 'models/TestSource.php';

plan(3);

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// test data
$s = new TestSource();
$s->src_username = 'PRIMEUSER1234';
$s->src_first_name = 'Harold';
$s->src_last_name = 'Blah';
$s->src_middle_initial = 'T';
$s->src_pre_name = null;
$s->src_post_name = 'Senior';
$s->src_status = Source::$STATUS_ENROLLED;
$s->src_has_acct = Source::$ACCT_NO;
$s->src_channel = Source::$CHANNEL_EVENT;
$s->save();

$o = new TestOrganization();
$o->save();

$so = new SrcOrg();
$so->so_org_id = $o->org_id;
$so->so_status = SrcOrg::$STATUS_OPTED_IN;
$so->so_home_flag =  true;
$s->SrcOrg[] = $so;
$s->save();


// test polymorphism
is( SrcOrgCache::refresh_cache($s), 1, "refresh with Source");
is( SrcOrgCache::refresh_cache($s->src_id), 1, "refresh with src_id");
is( SrcOrgCache::refresh_cache($s->src_uuid), 1, "refresh with src_uuid");
