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
require_once "$tdir/models/TestSource.php";
require_once "$tdir/models/TestEmail.php";

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

/**********************
 * Init
 */

// users with different roles
$reader = new TestUser();
$reader->UserSignature[0]->usig_text = 'test signature';
$reader->save();
$writer = new TestUser();
$writer->UserSignature[0]->usig_text = 'test signature';
$writer->save();

// organization
$org = new TestOrganization();
$org->add_users(array($reader),  2); // READER
$org->add_users(array($writer),  3); // WRITER
$org->save();

$s1 = new TestSource();
$s1->add_orgs(array($org));
$s1->SrcEmail[]->sem_email = $s1->src_username;
$s1->save();

$cleanup = new TestCleanup('email', 'email_campaign_name', '009-transactional-authz.t');

plan(4);

/**********************
 * 1) reader reply
 */
$data = array(
    'email_campaign_name' => '009-transactional-authz.t',
    'email_subject_line'  => '009-transactional-authz.t',
    'email_body'          => 'test test test test',
    'email_type'          => Email::$TYPE_OTHER,
    'org_uuid'            => $org->org_uuid,
    'usig_uuid'           => $reader->UserSignature[0]->usig_uuid,
    'src_uuid'            => $s1->src_uuid,
    'no_export'           => true,
);
$api = new AIRAPI($reader);
$rs = $api->create("email", $data);

// lookup the email
$q = Doctrine_Query::create()->from('Email')->where('email_campaign_name = ?', '009-transactional-authz.t');
$e = $q->fetchOne();

is( $rs['code'], AIRAPI::BGND_CREATE, 'create reader email - okay' );
is( $rs['message'], $e->email_uuid, 'create reader email - returns uuid' );

$e->delete();


/**********************
 * 2) writer reply
 */
$data = array(
    'email_campaign_name' => '009-transactional-authz.t',
    'email_subject_line'  => '009-transactional-authz.t',
    'email_body'          => 'test test test test',
    'email_type'          => Email::$TYPE_OTHER,
    'org_uuid'            => $org->org_uuid,
    'usig_uuid'           => $writer->UserSignature[0]->usig_uuid,
    'src_uuid'            => $s1->src_uuid,
    'no_export'           => true,
);
$api = new AIRAPI($writer);
$rs = $api->create("email", $data);

// lookup the email
$q = Doctrine_Query::create()->from('Email')->where('email_campaign_name = ?', '009-transactional-authz.t');
$e = $q->fetchOne();

is( $rs['code'], AIRAPI::BGND_CREATE, 'create writer email - okay' );
is( $rs['message'], $e->email_uuid, 'create writer email - returns uuid' );
