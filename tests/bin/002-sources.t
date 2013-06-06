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
require_once "$tdir/models/TestProject.php";
require_once "$tdir/models/TestInquiry.php";
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
 * Setup
 */
$o = new TestOrganization();
$o->add_users(array($u), AdminRole::WRITER);
$o->save();

$p = new TestProject();
$p->add_orgs(array($o));
$p->save();

$i = new TestInquiry();
$i->add_projects(array($p));
$i->save();

$sources = array();
for ($n=0; $n<25; $n++) {
    $sources[$n] = new TestSource();
    $sources[$n]->add_orgs(array($o));
    $sources[$n]->save();
}

$responses = array();
for ($n=0; $n<5; $n++) {
    $responses[$n] = new SrcResponseSet();
    $responses[$n]->Source = $sources[$n];
    $responses[$n]->Inquiry = $i;
    $responses[$n]->srs_date = air2_date();
    $responses[$n]->save();
}

$b = new TestBin();
$b->bin_user_id = $u->user_id;
$b->bin_shared_flag = true;
$b->save();
$uuid = $b->bin_uuid;


plan(15);

/**********************
 * Check
 */
$rs = $api->query("bin/$uuid/source");
is( $rs['code'], AIRAPI::OKAY, 'query - okay' );
is( count($rs['radix']), 0, 'query - count' );


/**********************
 * Add RESTfully
 */
$s1id = $sources[0]->src_uuid;
$rs = $api->create("bin/$uuid/source", array('src_uuid' => 'NOBODY'));
is( $rs['code'], AIRAPI::BAD_DATA, 'create - bad data' );

$rs = $api->create("bin/$uuid/source", array('src_uuid' => $s1id));
is( $rs['code'], AIRAPI::OKAY, 'create - okay' );

$rs = $api->fetch("bin/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'create - bin okay' );
is( $rs['radix']['src_count'], 1, 'create - bin src_count' );

$rs = $api->query("bin/$uuid/source");
is( $rs['code'], AIRAPI::OKAY, 'query - okay' );
is( count($rs['radix']), 1, 'query - count' );


/**********************
 * Update RESTfully (notes)
 */
$rs = $api->update("bin/$uuid/source/$s1id", array('src_first_name' => 'SOMETHING'));
is( $rs['code'], AIRAPI::BAD_DATA, 'update - bad data' );

$rs = $api->update("bin/$uuid/source/$s1id", array('bsrc_notes' => 'SOMETHING'));
is( $rs['code'], AIRAPI::OKAY, 'update - okay' );
is( $rs['radix']['bsrc_notes'], 'SOMETHING', 'update - notes changed' );


/**********************
 * Remove RESTfully
 */
$rs = $api->fetch("bin/$uuid/source/$s1id");
is( $rs['code'], AIRAPI::OKAY, 'delete - starts existing' );

$rs = $api->delete("bin/$uuid/source/$s1id");
is( $rs['code'], AIRAPI::OKAY, 'delete - okay' );

$rs = $api->fetch("bin/$uuid/source/$s1id");
is( $rs['code'], AIRAPI::BAD_IDENT, 'delete - gone now' );

$rs = $api->fetch("source/$s1id");
is( $rs['code'], AIRAPI::OKAY, 'delete - src still exists' );
