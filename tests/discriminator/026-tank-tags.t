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
require_once APPPATH.'/../tests/Test.php';
require_once APPPATH.'/../tests/models/TestTank.php';
require_once APPPATH.'/../tests/models/TestUser.php';
require_once APPPATH.'/../tests/models/TestSource.php';
require_once APPPATH.'/../tests/models/TestOrganization.php';
require_once APPPATH.'/../tests/models/TestTagMaster.php';
require_once 'phperl/callperl.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

$tm1 = new TestTagMaster();
$tm1->tm_name = 'tag-'.air2_generate_uuid();
$tm1->save();
$tag1 = $tm1->tm_name;
$tm2 = new TestTagMaster();
$tm2->tm_name = 'tag-'.air2_generate_uuid();
$tm2->save();
$tag2 = $tm2->tm_name;
$tm3 = new TestTagMaster();
$tm3->tm_name = 'tag-'.air2_generate_uuid();
$tm3->save();
$tag3 = $tm3->tm_name;

$eml = "testemail".air2_generate_uuid()."@test.com";
$src = new TestSource();
$src->Tags[0]->tag_tm_id = $tm1->tm_id;
$src->SrcEmail[0]->sem_email = $eml;
$src->SrcEmail[0]->sem_primary_flag = true;
$src->save();

$u = new TestUser();
$u->save();

$o = new TestOrganization();
$o->add_users(array($u), 3); //WRITER
$o->save();

$tank = new TestTank();
$tank->tank_user_id = $u->user_id;
$tank->tank_type = 'F';
$tank->tank_status = Tank::$STATUS_READY;
$tank->save();

$tsrc = new TankSource();
$tsrc->tsrc_tank_id = $tank->tank_id;
$tsrc->tsrc_status = TankSource::$STATUS_NEW;
$tsrc->sem_email = $eml;
$tsrc->tsrc_tags = "$tag1,$tag2, $tag3 ";
$tsrc->save();


plan(10);

/**********************
 * Discriminate
 */
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->clearRelated();
$tank->refresh();
$tsrc = $tank->TankSource[0];

ok( $report, 'tags - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'tags - tank_status' );
is( $tsrc->tsrc_status, TankSource::$STATUS_DONE, 'tags - tsrc_status' );
is( $report['done_upd'], 1, 'tags - done count' );
is( $report['error'], 0, 'tags - error count' );
is( $report['conflict'], 0, 'tags - conflict count' );

// check actual values
$src->clearRelated();
$src->refresh();
is( $src->Tags->count(), 3, 'tags - source has 3 tags' );
is( $src->Tags[0]->TagMaster->tm_name, $tag1, 'tags - source tag1' );
is( $src->Tags[1]->TagMaster->tm_name, $tag2, 'tags - source tag2' );
is( $src->Tags[2]->TagMaster->tm_name, $tag3, 'tags - source tag3' );
