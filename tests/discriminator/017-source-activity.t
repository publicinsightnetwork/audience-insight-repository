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
require_once APPPATH.'/../tests/models/TestSource.php';
require_once APPPATH.'/../tests/models/TestUser.php';
require_once APPPATH.'/../tests/models/TestProject.php';
require_once 'phperl/callperl.php';

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// setup
$u = new TestUser();
$u->save();
$s = new TestSource();
$s->save();
$p = new TestProject();
$p->save();
$t = new TestTank();
$t->tank_user_id = $u->user_id;
$t->tank_type = Tank::$TYPE_FB;
$t->tank_status = Tank::$STATUS_READY;
$t->TankSource[0]->src_id = $s->src_id;
$t->save();
$ts = $t->TankSource[0];
$t->clearRelated();

// get some actm_id's
$q = Doctrine_Query::create()->from('ActivityMaster');
$q->where('actm_table_type = ?', ActivityMaster::$TABLE_TYPE_SOURCE);
$q->andWhere('actm_status = ?', ActivityMaster::$STATUS_ACTIVE);
$q->limit(3);
$actm = $q->execute();

plan(12);

/**********************
 * 1) import source and check activity log
 */
$t->TankActivity[0]->tact_actm_id = $actm[0]->actm_id;
$t->TankActivity[0]->tact_prj_id = $p->prj_id;
$t->TankActivity[0]->tact_dtim = air2_date(strtotime('-1 week'));
$t->TankActivity[0]->tact_desc = "{SRC} did something {XID}";
$t->TankActivity[0]->tact_notes = 'these are some notes';
$t->save();

// self referencing xid
$t->TankActivity[0]->tact_xid = $t->tank_id;
$t->TankActivity[0]->tact_ref_type = SrcActivity::$REF_TYPE_TANK;

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'actm - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'actm - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'actm - tsrc_status' );
is( $report['done_upd'], 1, 'actm - done count' );
is( count($s->SrcActivity), 1, 'actm - 1 SrcActivity' );
$sa = $s->SrcActivity[0];
$s->clearRelated();
is( $sa->sact_actm_id, $actm[0]->actm_id, 'actm - actm_id' );
is( $sa->sact_prj_id, $p->prj_id, 'actm - prj_id' );
is( $sa->sact_dtim, $t->TankActivity[0]->tact_dtim, 'actm - sact_dtim' );
is( $sa->sact_desc, $t->TankActivity[0]->tact_desc, 'new org - desc' );
is( $sa->sact_notes, $t->TankActivity[0]->tact_notes, 'new org - notes' );
is( $sa->sact_cre_user, $u->user_id, 'actm - cre_user' );
is( $sa->sact_upd_user, $u->user_id, 'actm - upd_user' );

