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


plan(9);

/**********************
 * Creation
 */
$rs = $api->create("bin", array('bin_name' => 'test bin 001'));
is( $rs['code'], AIRAPI::OKAY, 'create - okay' );
$uuid = $rs['uuid'];

$b = AIR2_Record::find('Bin', $uuid);
$b->BinSource[0]->Source = $sources[0];
$b->BinSource[1]->Source = $sources[1];
$b->BinSource[2]->Source = $sources[2];
$b->BinSrcResponseSet[0]->SrcResponseSet = $responses[2];
$b->BinSrcResponseSet[0]->Inquiry = $i;
$b->BinSrcResponseSet[0]->Source = $sources[2];
$b->save();


/**********************
 * Fetch
 */
$rs = $api->fetch("bin/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'fetch - okay' );
is( $rs['radix']['src_count'], 3, 'fetch - src_count' );
is( $rs['radix']['subm_count'], 1, 'fetch - subm_count' );
is( $rs['radix']['owner_flag'], true, 'fetch - owner' );


/**********************
 * Query
 */
$rs = $api->query("bin", array('owner_flag' => 1));
is( $rs['code'], AIRAPI::OKAY, 'query - okay' );
is( count($rs['radix']), 1, 'query - count 1' );


/**********************
 * Delete
 */
$rs = $api->delete("bin/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'delete - okay' );
$rs = $api->fetch("bin/$uuid");
is( $rs['code'], AIRAPI::BAD_IDENT, 'delete - DNE' );
