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
require_once 'rframe/AIRAPI.php';
$tdir = APPPATH.'../tests';
require_once "$tdir/Test.php";
require_once "$tdir/models/TestCleanup.php";
require_once "$tdir/models/TestUser.php";
require_once "$tdir/models/TestOrganization.php";
require_once "$tdir/models/TestInquiry.php";
require_once "$tdir/models/TestSource.php";

plan(4);

/**********************
 * Init
 */
AIR2_DBManager::init();

$u = new TestUser();
$u->save();

$homeOrg      = new TestOrganization();
$homeOrg->add_users(array($u), 4);
$homeOrg->save();

$unrelatedOrg = new TestOrganization();
$unrelatedOrg->save();


$i = new TestInquiry();
$i->inq_cre_user = $u->user_id;
$i->inq_rss_intro = 'blah';
$i->save();

ok( $api = new AIRAPI($u), "get API object");


ok( $uuid = $i->inq_uuid, "get new inquiry uuid" );

/**********************
 * 1) Add home org
 */
// $rs = $api->fetch("inquiry/$uuid");
$rs = $api->create("inquiry/$uuid/organization", array('org_uuid' => $homeOrg->org_uuid));
is( $rs['code'], AIRAPI::OKAY, 'add home org - okay' );

/**********************
 * 2) Add unrelated org
 */

$rs = $api->create("inquiry/$uuid/organization", array('org_uuid' => $unrelatedOrg->org_uuid));
is( $rs['code'], AIRAPI::OKAY, 'add home org - okay' );
diag_dump($rs);
