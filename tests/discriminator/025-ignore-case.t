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
require_once 'phperl/callperl.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// some facts
$tbl_fact = Doctrine::getTable('Fact');
$tbl_fact_value = Doctrine::getTable('FactValue');
$fact_gender = $tbl_fact->findOneBy('fact_identifier', 'gender');
$fact_born   = $tbl_fact->findOneBy('fact_identifier', 'birth_year');
$fv_gender_1 = $tbl_fact_value->findOneBy('fv_value', 'Male');
$fv_gender_2 = $tbl_fact_value->findOneBy('fv_value', 'Female');
$fv_gender_3 = $tbl_fact_value->findOneBy('fv_value', 'Transgender');


/**********************
 * Setup
 */
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

$uname = air2_generate_uuid().'@test.com';
$s = new TestSource();
$s->src_username = $uname;
$s->src_first_name = 'Firstname';
$s->src_last_name = 'Lastname';
$s->src_middle_initial = 'T';
$s->src_pre_name = 'Prename';
$s->src_post_name = 'Postname';
$s->save();

$sa = new SrcAlias();
$sa->Source = $s;
$sa->sa_name = 'Aliasname';
$sa->sa_first_name = 'Aliasfirst';
$sa->sa_last_name = 'Aliaslast';
$sa->sa_post_name = 'Aliaspost';
$sa->save();

$sm = new SrcMailAddress();
$sm->Source = $s;
$sm->smadd_line_1 = 'Mail Line 1';
$sm->smadd_line_2 = 'Mail Line 2';
$sm->smadd_city = 'Cityname';
$sm->save();

$sf1 = new SrcFact();
$sf1->Source = $s;
$sf1->Fact = $fact_born;
$sf1->sf_src_value = '1812ad';
$sf1->save();

$sf2 = new SrcFact();
$sf2->Source = $s;
$sf2->Fact = $fact_gender;
$sf2->AnalystFV = $fv_gender_1;
$sf2->SourceFV = $fv_gender_2;
$sf2->sf_src_value = 'Gender';
$sf2->save();


/**********************
 * Change case of lots of stuff
 */
$tsrc = new TankSource();
$tsrc->tsrc_tank_id = $tank->tank_id;
$tsrc->tsrc_status = TankSource::$STATUS_NEW;
$tsrc->src_id = $s->src_id;

$tsrc->src_username = preg_replace('/test\.com/', 'TEST.com', $uname);
$tsrc->src_first_name = 'FIRSTname';
$tsrc->src_last_name = 'AliasLAST';
$tsrc->src_middle_initial = 't';
$tsrc->src_pre_name = 'PreNAME';
$tsrc->src_post_name = 'postnamE';

$tsrc->smadd_line_1 = 'Mail LINE 1';
$tsrc->smadd_line_2 = 'mail line 2';
$tsrc->smadd_city = 'CITYNAME';

$tsrc->TankFact[0]->Fact = $fact_born;
$tsrc->TankFact[0]->sf_src_value = '1812AD';
$tsrc->TankFact[1]->Fact = $fact_gender;
$tsrc->TankFact[1]->sf_src_value = 'GENDER';
$tsrc->save();


plan(18);

/**********************
 * Discriminate
 */
$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
$tank->clearRelated();
$tank->refresh();
$tsrc = $tank->TankSource[0];

ok( $report, 'case - ok' );
is( $tank->tank_status, Tank::$STATUS_READY, 'case - tank_status' );
is( $tsrc->tsrc_status, TankSource::$STATUS_DONE, 'case - tsrc_status' );
is( $report['done_upd'], 1, 'case - done count' );
is( $report['error'], 0, 'case - error count' );
is( $report['conflict'], 0, 'case - conflict count' );

// check actual values
$s->clearRelated();
$s->refresh();
is( $s->src_username, $uname, 'case - src_username' );
is( $s->src_first_name, 'Firstname', 'case - src_first_name' );
is( $s->src_last_name, 'Lastname', 'case - src_last_name' );
is( $s->src_middle_initial, 'T', 'case - src_middle_initial' );
is( $s->src_pre_name, 'Prename', 'case - src_pre_name' );
is( $s->src_post_name, 'Postname', 'case - src_post_name' );

$sa->refresh();
is( $sa->sa_last_name, 'Aliaslast', 'case - sa_last_name' );

$sm->refresh();
is( $sm->smadd_line_1, 'Mail Line 1', 'case - smadd_line_1' );
is( $sm->smadd_line_2, 'Mail Line 2', 'case - smadd_line_2' );
is( $sm->smadd_city, 'Cityname', 'case - smadd_city' );

$sf1->refresh();
is( $sf1->sf_src_value, '1812ad',  'case - sf_src_value 1' );

$sf2->refresh();
is( $sf2->sf_src_value, 'Gender',  'case - sf_src_value 2' );
