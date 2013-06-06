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
require_once 'phperl/callperl.php';

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
plan(15);

$t = new TestTank();
$t->tank_user_id = 1;
$t->tank_type = Tank::$TYPE_FB;
$t->tank_status = Tank::$STATUS_READY;
$t->save();
$s = new TestSource();
$s->save();
$ts = new TankSource();
$ts->tsrc_tank_id = $t->tank_id;
$ts->src_username = $s->src_username;
$ts->save();

$tank_id = $t->tank_id;
$src_id = $s->src_id;
$tsrc_id = $ts->tsrc_id;

function reset_tank() {
    global $tank_id, $tsrc_id, $conn;
    $q = "update tank_source set tsrc_status = ? where tsrc_id = ?";
    $conn->exec($q, array(TankSource::$STATUS_NEW, $tsrc_id));
    $q = "delete from tank_vita where tv_tsrc_id = ?";
    $conn->exec($q, array($tsrc_id));
}


/**********************
 * Create new SrcVita
 */
$tv1 = new TankVita();
$tv1->tv_tsrc_id = $tsrc_id;
$tv1->sv_type = SrcVita::$TYPE_EXPERIENCE;
$tv1->sv_value = 'I did something';
$tv1->sv_basis = 'basis of that';
$tv1->sv_start_date = air2_date(strtotime("-1 day"));
$tv1->sv_end_date = air2_date(strtotime("+1 day"));
$tv1->save();
$tv1->refresh();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);

ok( $report, 'new vita - ok' );
is( $report['done_upd'], 1, 'new vita - done count' );
is( $report['conflict'], 0, 'new vita - conflict count' );
is( $report['error'], 0, 'new vita - error count' );

$s->clearRelated();
$s->refresh();
is( count($s->SrcVita), 1, 'new vita - SrcVita count');
is( $s->SrcVita[0]->sv_type, $tv1->sv_type, 'new vita - type' );
is( $s->SrcVita[0]->sv_value, $tv1->sv_value, 'new vita - value' );
is( $s->SrcVita[0]->sv_basis, $tv1->sv_basis, 'new vita - basis' );
is( $s->SrcVita[0]->sv_start_date, $tv1->sv_start_date, 'new vita - start date' );
is( $s->SrcVita[0]->sv_end_date, $tv1->sv_end_date, 'new vita - end date' );


/**********************
 * Create even more SrcVita
 */
reset_tank();
$tv2 = new TankVita();
$tv2->tv_tsrc_id = $tsrc_id;
$tv2->sv_type = SrcVita::$TYPE_EXPERIENCE;
$tv2->sv_value = 'a value';
$tv2->sv_basis = 'a basis';
$tv2->sv_start_date = air2_date();
$tv2->sv_end_date = air2_date();
$tv2->save();
$tv3 = new TankVita();
$tv3->tv_tsrc_id = $tsrc_id;
$tv3->sv_type = SrcVita::$TYPE_INTEREST;
$tv3->sv_notes = 'this is what i like';
$tv3->save();
$tv4 = new TankVita();
$tv4->tv_tsrc_id = $tsrc_id;
$tv4->sv_type = SrcVita::$TYPE_EXPERIENCE;
$tv4->sv_value = 'a value';
$tv4->sv_basis = 'a basis';
$tv4->sv_start_date = air2_date();
$tv4->sv_end_date = air2_date();
$tv4->sv_origin = SrcVita::$ORIGIN_MYPIN;
$tv4->sv_lat = 100;
$tv4->sv_long = 120;
$tv4->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);

ok( $report, 'more vita - ok' );
is( $report['done_upd'], 1, 'more vita - done count' );
is( $report['conflict'], 0, 'more vita - conflict count' );
is( $report['error'], 0, 'more vita - error count' );

$s->clearRelated();
$s->refresh();
is( count($s->SrcVita), 4, 'more vita - SrcVita count');
