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
require_once "$tdir/models/TestTank.php";
require_once "$tdir/models/TestBin.php";
require_once "$tdir/models/TestSource.php";


/**********************
 * Init
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$u = new TestUser();
$u->save();
$api = new AIRAPI($u);


/**********************
 * Setup test data
 */
$o = new TestOrganization();
$o->add_users(array($u), AdminRole::READER);
$o->save();

$bin = new TestBin();
$bin->bin_user_id = $u->user_id;
$bin->save();
$uuid = $bin->bin_uuid;

$t = new TestTank();
$t->tank_user_id = $u->user_id;
$t->save();

$sources = array();
for ($i=0; $i<25; $i++) {
    $src = new TestSource();
    $src->add_orgs(array($o));
    $src->save();
    $t->TankSource[$i]->src_id = $src->src_id;
    if ($i < 5) {
        $t->TankSource[$i]->tsrc_status = TankSource::$STATUS_NEW;
    }
    elseif($i < 10) {
        $t->TankSource[$i]->tsrc_status = TankSource::$STATUS_CONFLICT;
    }
    elseif($i < 15) {
        $t->TankSource[$i]->tsrc_status = TankSource::$STATUS_RESOLVED;
    }
    elseif($i < 20) {
        $t->TankSource[$i]->tsrc_status = TankSource::$STATUS_DONE;
    }
    else {
        $t->TankSource[$i]->tsrc_status = TankSource::$STATUS_ERROR;
    }
}
$t->save();


plan(12);

/**********************
 * Initial count
 */
$rs = $api->fetch("bin/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'init - okay' );
is( $rs['radix']['src_count'], 0, 'init - 0 sources' );


/**********************
 * bulk_addtank
 */
$rs = $api->update("bin/$uuid", array('bulk_addtank' => $t->tank_uuid));
is( $rs['code'], AIRAPI::OKAY, 'add1 - okay' );
is( $rs['radix']['src_count'], 10, 'add1 - 10 sources' );
is( $rs['meta']['bulk_rs']['insert'], 10, 'add1 - 10 inserted' );
is( $rs['meta']['bulk_rs']['total'],  10, 'add1 - 10 total' );


/**********************
 * add with some duplicates/invalids
 */
$t->TankSource[0]->tsrc_status = TankSource::$STATUS_DONE;
$t->TankSource[1]->tsrc_status = TankSource::$STATUS_DONE;
$t->TankSource[2]->tsrc_status = TankSource::$STATUS_DONE;
$t->TankSource[3]->tsrc_status = TankSource::$STATUS_DONE;
$t->TankSource[3]->src_id = $t->TankSource[2]->src_id;
$t->TankSource[4]->tsrc_status = TankSource::$STATUS_DONE;
$t->TankSource[4]->src_id = 9999999;
$t->save();

$rs = $api->update("bin/$uuid", array('bulk_addtank' => $t->tank_uuid));
is( $rs['code'], AIRAPI::OKAY, 'add2 - okay' );
is( $rs['radix']['src_count'], 13, 'add2 - 13 sources' );
is( $rs['meta']['bulk_rs']['total'],     15, 'add2 - 15 total' );
is( $rs['meta']['bulk_rs']['insert'],    3,  'add2 - 3 inserted' );
is( $rs['meta']['bulk_rs']['duplicate'], 11, 'add2 - 11 duplicate' );
is( $rs['meta']['bulk_rs']['invalid'],   1,  'add2 - 1 invalid' );
