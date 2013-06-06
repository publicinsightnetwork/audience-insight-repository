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
require_once "$tdir/models/TestProject.php";
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
$o->org_default_prj_id = $p->prj_id;
$o->save();

$i = $p->get_manual_entry_inquiry();
$iclean = new TestCleanup('inquiry', 'inq_id', $i->inq_id);

$s1 = new TestSource();
$s1->add_orgs(array($o));
$s1->save();
$uuid = $s1->src_uuid;


plan(38);

/**********************
 * Initial values
 */
$rs = $api->fetch("source/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'fetch - okay' );
is( $rs['radix']['src_uuid'], $uuid, 'fetch - uuid' );
ok( $rs['authz']['may_read'], 'fetch - may_read' );
ok( $rs['authz']['may_write'], 'fetch - may_write' );
ok( !$rs['authz']['may_manage'], 'fetch - !may_manage' );
ok( $rs['authz']['unlock_write'], 'fetch - unlock_write' );
ok( !$rs['authz']['unlock_manage'], 'fetch - !unlock_manage' );

$rs = $api->query("source/$uuid/submission");
is( $rs['code'], AIRAPI::OKAY, 'query subm - okay' );
is( count($rs['radix']), 0, 'query subm - count' );
is( $rs['meta']['total'], 0, 'query subm - total' );


/**********************
 * Create submission
 */
$rs = $api->create("source/$uuid/submission", array());
is( $rs['code'], AIRAPI::BAD_DATA, 'create empty - code' );

$data = array(
    'prj_uuid' => 'nothing',
    'srs_date' => air2_date(),
    'manual_entry_type' => 'E',
    'manual_entry_desc' => 'this is the description',
    'manual_entry_text' => 'this is the text',
);
$rs = $api->create("source/$uuid/submission", $data);
is( $rs['code'], AIRAPI::BAD_DATA, 'create badprj - code' );
like( $rs['message'], '/invalid project/i', 'create badprj - message' );

$data['prj_uuid'] = $p->prj_uuid;
$rs = $api->create("source/$uuid/submission", $data);
is( $rs['code'], AIRAPI::OKAY, 'create subm - code' );
is( $rs['radix']['srs_date'], $data['srs_date'], 'create subm - date' );
is( $rs['radix']['srs_type'], SrcResponseSet::$TYPE_MANUAL_ENTRY, 'create subm - srs_type' );
is( $rs['radix']['manual_entry_type'], 'Email', 'create subm - type' );
is( $rs['radix']['manual_entry_desc'], $data['manual_entry_desc'], 'create subm - desc' );
is( $rs['radix']['manual_entry_text'], $data['manual_entry_text'], 'create subm - text' );
is( $rs['radix']['Inquiry']['inq_uuid'], $i->inq_uuid, 'create subm - inq_uuid' );
$srs_uuid = $rs['radix']['srs_uuid'];

$rs = $api->query("source/$uuid/submission");
is( $rs['code'], AIRAPI::OKAY, 'query subm - okay' );
is( count($rs['radix']), 1, 'query subm - count' );
is( $rs['meta']['total'], 1, 'query subm - total' );

$rs = $api->fetch("source/$uuid/submission/$srs_uuid");
is( $rs['code'], AIRAPI::OKAY, 'fetch subm - okay' );

$rs = $api->query("submission/$srs_uuid/response");
is( $rs['code'], AIRAPI::OKAY, 'query resp - okay' );
is( count($rs['radix']), 3, 'query resp - count' );
is( $rs['meta']['total'], 3, 'query resp - total' );


/**********************
 * With MyPIN account lock
 */
$s1->src_has_acct = Source::$ACCT_YES;
$s1->save();

$rs = $api->fetch("source/$uuid");
is( $rs['code'], AIRAPI::OKAY, 'fetch - okay' );
is( $rs['radix']['src_uuid'], $uuid, 'fetch - uuid' );
ok( $rs['authz']['may_read'], 'fetch - may_read' );
ok( !$rs['authz']['may_write'], 'fetch - may_write' );
ok( !$rs['authz']['may_manage'], 'fetch - !may_manage' );
ok( $rs['authz']['unlock_write'], 'fetch - unlock_write' );
ok( !$rs['authz']['unlock_manage'], 'fetch - !unlock_manage' );

// create 2nd submission
$rs = $api->create("source/$uuid/submission", $data);
is( $rs['code'], AIRAPI::OKAY, 'create subm2 - code' );

$rs = $api->query("source/$uuid/submission");
is( $rs['code'], AIRAPI::OKAY, 'query subm2 - okay' );
is( count($rs['radix']), 2, 'query subm2 - count' );
is( $rs['meta']['total'], 2, 'query subm2 - total' );
