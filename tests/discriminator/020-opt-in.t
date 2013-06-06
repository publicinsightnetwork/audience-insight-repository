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
require_once APPPATH.'/../tests/models/TestUser.php';
require_once APPPATH.'/../tests/models/TestTank.php';
require_once APPPATH.'/../tests/models/TestSource.php';
require_once APPPATH.'/../tests/models/TestOrganization.php';
require_once 'phperl/callperl.php';

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// setup
$u1 = new TestUser();
$u1->save();
$u2 = new TestUser();
$u2->save();
$o1 = new TestOrganization();
$o1->add_users(array($u1), 3);
$o1->save();
$o2 = new TestOrganization();
$o2->add_users(array($u2), 3);
$o2->save();
$s = new TestSource();
$s->src_first_name = 'Harold';
$s->save();
$t = new TestTank();
$t->tank_user_id = 1;
$t->tank_type = Tank::$TYPE_FB;
$t->tank_status = Tank::$STATUS_READY;
$t->TankSource[0]->src_id = $s->src_id;
$t->TankSource[0]->src_first_name = 'Harold'; //no conflict
$t->save();
$ts = $t->TankSource[0];
$t->clearRelated();


plan(22);

/**********************
 * 0) check authz of users
 */
ok( !$s->user_may_read($u1), 'user1 may not read' );
ok( !$s->user_may_write($u1), 'user1 may not write' );
ok( !$s->user_may_read($u2), 'user2 may not read' );
ok( !$s->user_may_write($u2), 'user2 may not write' );


/**********************
 * 1) add source to new org
 */
$t->TankOrg[0]->to_org_id = $o1->org_id;
$t->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'new org - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'new org - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'new org - tsrc_status' );
is( $report['done_upd'], 1, 'new org - done count' );
$count = $conn->fetchOne('select count(*) from src_org where so_src_id = ?', array($s->src_id), 0);
is( $count, 2, 'new org - 2 SrcOrg' );


/**********************
 * 2) check the authz again
 */
ok( $s->user_may_read($u1), 'user1 may read' );
ok( $s->user_may_write($u1), 'user1 may write' );
ok( !$s->user_may_read($u2), 'user2 may not read' );
ok( !$s->user_may_write($u2), 'user2 may not write' );


/**********************
 * 3) create a conflict, and import to org2
 */
$t->TankOrg[0]->to_org_id = $o2->org_id;
$t->save();
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->src_first_name = 'Haroldy'; //conflict!
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'second org - ok' );
is( $t->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'second org - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'second org - tsrc_status' );
is( $report['conflict'], 1, 'second org - conflict count' );
$count = $conn->fetchOne('select count(*) from src_org where so_src_id = ?', array($s->src_id), 0);
is( $count, 3, 'second org - 3 SrcOrg' );


/**********************
 * 4) check the authz again. (user 2 should be able to read, even before the
 * conflict has been resolved)
 */
ok( $s->user_may_read($u1), 'user1 may read' );
ok( $s->user_may_write($u1), 'user1 may write' );
ok( $s->user_may_read($u2), 'user2 may read' );
ok( $s->user_may_write($u2), 'user2 may write' );

