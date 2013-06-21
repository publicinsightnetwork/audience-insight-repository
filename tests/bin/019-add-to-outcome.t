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
require_once "$tdir/models/TestUser.php";
require_once "$tdir/models/TestOrganization.php";
require_once "$tdir/models/TestBin.php";
require_once "$tdir/models/TestOutcome.php";
require_once "$tdir/models/TestSource.php";


/**********************
 * Init
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$user = new TestUser();
$user->save();
$api = new AIRAPI($user);

$baduser = new TestUser();
$baduser->save();
$badapi = new AIRAPI($baduser);


/**********************
 * Setup
 */
$org = new TestOrganization();
$org->add_users(array($user), AdminRole::WRITER);
$org->save();

$out = new TestOutcome();
$out->out_org_id = $org->org_id;
$out->out_cre_user = $user->user_id;
$out->save();

$sources = array();
$source_uuids = array();
for ($n=0; $n<25; $n++) {
    $sources[$n] = new TestSource();
    $sources[$n]->add_orgs(array($org));
    $sources[$n]->save();
    $source_uuids[$n] = $sources[$n]->src_uuid;
}

$bin = new TestBin();
$bin->bin_user_id = $user->user_id;
$bin->bin_shared_flag = true;
$bin->save();
$api->update("bin/$bin->bin_uuid", array('bulk_add' => $source_uuids));

plan(10);

/**
 * fetch
**/

$rs = $api->fetch("outcome/$out->out_uuid");
is( $rs['code'], AIRAPI::OKAY, 'fetch bin - ok' );
is( $rs['radix']['src_count'], 0, 'start with 0 sources' );

/**********************
 * bulk_add
 */

$radix = array(
    'sources' => array(
        'bin_uuid' => 'bogus',
        'sout_type' => 'cited',
    )
);

$rs = $api->update("outcome/$out->out_uuid", $radix);
is( $rs['code'], AIRAPI::BAD_DATA, 'bogus add via bin - fail' );

$rs = $api->fetch("outcome/$out->out_uuid");
is( $rs['code'], AIRAPI::OKAY, 'refetch bin - ok' );
is( $rs['radix']['src_count'], 0, 'still have 0 sources' );

//set a proper bin_uuid
$radix['sources']['bin_uuid'] = $bin->bin_uuid;

$rs = $badapi->update("outcome/$out->out_uuid", $radix);
is( $rs['code'], AIRAPI::BAD_DATA, 'bogus user add via bin - fail' );

$rs = $api->fetch("outcome/$out->out_uuid");
is( $rs['code'], AIRAPI::OKAY, 'refetch bin - ok' );
is( $rs['radix']['src_count'], 0, 'still have 0 sources' );

$rs = $api->update("outcome/$out->out_uuid", $radix);
is( $rs['code'], AIRAPI::OKAY, 'add via bin - ok' );
is( $rs['radix']['src_count'], 25, 'add - 25 sources' );
