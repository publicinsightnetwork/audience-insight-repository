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
$tbl_fact = Doctrine::getTable('Fact');
$tbl_fv = Doctrine::getTable('FactValue');

// setup
$s = new TestSource();
$s->save();
$t = new TestTank();
$t->tank_user_id = 1;
$t->tank_type = Tank::$TYPE_FB;
$t->tank_status = Tank::$STATUS_READY;
$t->TankSource[0]->src_id = $s->src_id;
$t->save();
$ts = $t->TankSource[0];
$t->clearRelated();

// get some fact/fact_value ids
function get_fact_id($fact_ident) {
    global $conn;
    return $conn->fetchOne('select fact_id from fact where fact_identifier = ?',
        array($fact_ident), 0);
}
function get_fact_values($fact_id, $num=2) {
    global $conn;
    return $conn->fetchColumn("select fv_id from fact_value where fv_fact_id = ? limit $num",
        array($fact_id), 0);
}
// multiple values
$f_gender = get_fact_id('gender');
$fv_gender = get_fact_values($f_gender);
$f_eth = get_fact_id('ethnicity');
$fv_eth = get_fact_values($f_eth);
$f_rel = get_fact_id('religion');
$fv_rel = get_fact_values($f_rel);

// foreign-key only
$f_income = get_fact_id('household_income');
$fv_income = get_fact_values($f_income);
$f_edu = get_fact_id('education_level');
$fv_edu = get_fact_values($f_edu);
$f_pol = get_fact_id('political_affiliation');
$fv_pol = get_fact_values($f_pol);
$f_life = get_fact_id('lifecycle');
$fv_life = get_fact_values($f_life);

// text only
$f_born = get_fact_id('birth_year');
$f_site = get_fact_id('source_website');
$f_time = get_fact_id('timezone');


plan(46);

/**********************
 * 1) blank fact values
 */
$ts->TankFact[0]->tf_fact_id = $f_gender;
$ts->TankFact[0]->sf_fv_id = $fv_gender[0];
$ts->TankFact[0]->sf_src_value = 'Gender1';
$ts->TankFact[0]->sf_src_fv_id = $fv_gender[0];
$ts->TankFact[1]->tf_fact_id = $f_eth;
$ts->TankFact[1]->sf_fv_id = $fv_eth[0];
$ts->TankFact[1]->sf_src_value = 'Ethnicity1';
$ts->TankFact[1]->sf_src_fv_id = $fv_eth[0];
$ts->TankFact[2]->tf_fact_id = $f_rel;
$ts->TankFact[2]->sf_fv_id = $fv_rel[0];
$ts->TankFact[2]->sf_src_value = 'Religion1';
$ts->TankFact[2]->sf_src_fv_id = $fv_rel[0];
$ts->TankFact[3]->tf_fact_id = $f_income;
$ts->TankFact[3]->sf_fv_id = $fv_income[0];
$ts->TankFact[3]->sf_src_fv_id = $fv_income[0];
$ts->TankFact[4]->tf_fact_id = $f_edu;
$ts->TankFact[4]->sf_fv_id = $fv_edu[0];
$ts->TankFact[4]->sf_src_fv_id = $fv_edu[0];
$ts->TankFact[5]->tf_fact_id = $f_pol;
$ts->TankFact[5]->sf_fv_id = $fv_pol[0];
$ts->TankFact[5]->sf_src_fv_id = $fv_pol[0];
$ts->TankFact[6]->tf_fact_id = $f_life;
$ts->TankFact[6]->sf_fv_id = $fv_life[0];
$ts->TankFact[6]->sf_src_fv_id = $fv_life[0];
$ts->TankFact[7]->tf_fact_id = $f_born;
$ts->TankFact[7]->sf_src_value = 'Birthyear1';
$ts->TankFact[8]->tf_fact_id = $f_site;
$ts->TankFact[8]->sf_src_value = 'Website1';
$ts->TankFact[9]->tf_fact_id = $f_time;
$ts->TankFact[9]->sf_src_value = 'Timezone1';
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'blank - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'blank - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'blank - tsrc_status' );
is( $report['done_upd'], 1, 'blank - done count' );
is( count($s->SrcFact), 10, 'blank - 10 facts' );


/**********************
 * 2) duplicate facts
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'dup - lock' );
is( $t->tank_status, Tank::$STATUS_READY, 'dup - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_DONE, 'dup - tsrc_status' );
is( $report['done_upd'], 1, 'dup - done count' );
is( count($s->SrcFact), 10, 'dup - 10 facts' );


/**********************
 * 3) conflicts
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->tsrc_errors = null;
$ts->TankFact[0]->sf_fv_id = $fv_gender[1];
$ts->TankFact[0]->sf_src_value = 'Gender2';
$ts->TankFact[0]->sf_src_fv_id = $fv_gender[1];
$ts->TankFact[1]->sf_fv_id = $fv_eth[1];
$ts->TankFact[1]->sf_src_value = 'Ethnicity2';
$ts->TankFact[1]->sf_src_fv_id = $fv_eth[1];
$ts->TankFact[2]->sf_fv_id = $fv_rel[1];
$ts->TankFact[2]->sf_src_value = 'Religion2';
$ts->TankFact[2]->sf_src_fv_id = $fv_rel[1];
$ts->TankFact[3]->sf_fv_id = $fv_income[1];
$ts->TankFact[3]->sf_src_fv_id = $fv_income[1];
$ts->TankFact[4]->sf_fv_id = $fv_edu[1];
$ts->TankFact[4]->sf_src_fv_id = $fv_edu[1];
$ts->TankFact[5]->sf_fv_id = $fv_pol[1];
$ts->TankFact[5]->sf_src_fv_id = $fv_pol[1];
$ts->TankFact[6]->sf_fv_id = $fv_life[1];
$ts->TankFact[6]->sf_src_fv_id = $fv_life[1];
$ts->TankFact[7]->sf_src_value = 'Birthyear2';
$ts->TankFact[8]->sf_src_value = 'Website2';
$ts->TankFact[9]->sf_src_value = 'Timezone2';
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'conflict1 - ok' );
is( $t->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'conflict1 - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'conflict1 - tsrc_status' );
is( $report['conflict'], 1, 'conflict1 - conflict count' );
is( count($s->SrcFact), 10, 'conflict1 - 10 facts' );

// check conflicts
$errs = json_decode($ts->tsrc_errors, true);
ok( isset($errs['initial']), 'conflict1 - initial conflicts' );
$cons = $errs['initial'];

// multiple values
ok( isset($cons['gender.sf_fv_id']),     'conflict1 - gender map' );
ok( isset($cons['gender.sf_src_value']), 'conflict1 - gender value' );
ok( isset($cons['gender.sf_src_fv_id']), 'conflict1 - gender src map' );
ok( isset($cons['ethnicity.sf_fv_id']),     'conflict1 - ethnicity map' );
ok( isset($cons['ethnicity.sf_src_value']), 'conflict1 - ethnicity value' );
ok( isset($cons['ethnicity.sf_src_fv_id']), 'conflict1 - ethnicity src map' );
ok( !isset($cons['religion.sf_fv_id']),     'conflict1 - !religion map' );
ok( !isset($cons['religion.sf_src_value']), 'conflict1 - !religion value' );
ok( !isset($cons['religion.sf_src_fv_id']), 'conflict1 - !religion src map' );

// foreign-key only
ok( !isset($cons['household_income.sf_fv_id']),     'conflict1 - !household_income map' );
ok( !isset($cons['household_income.sf_src_value']), 'conflict1 - !household_income value' );
ok( !isset($cons['household_income.sf_src_fv_id']), 'conflict1 - !household_income src map' );
ok( !isset($cons['education_level.sf_fv_id']),     'conflict1 - !education_level map' );
ok( !isset($cons['education_level.sf_src_value']), 'conflict1 - !education_level value' );
ok( !isset($cons['education_level.sf_src_fv_id']), 'conflict1 - !education_level src map' );
ok( !isset($cons['political_affiliation.sf_fv_id']),     'conflict1 - !political_affiliation map' );
ok( !isset($cons['political_affiliation.sf_src_value']), 'conflict1 - !political_affiliation value' );
ok( !isset($cons['political_affiliation.sf_src_fv_id']), 'conflict1 - !political_affiliation src map' );
ok( !isset($cons['lifecycle.sf_fv_id']),     'conflict1 - !lifecycle map' );
ok( !isset($cons['lifecycle.sf_src_value']), 'conflict1 - !lifecycle value' );
ok( !isset($cons['lifecycle.sf_src_fv_id']), 'conflict1 - !lifecycle src map' );

// text only
ok( !isset($cons['birth_year.sf_fv_id']),     'conflict1 - !birth_year map' );
ok( isset($cons['birth_year.sf_src_value']),  'conflict1 - birth_year value' );
ok( !isset($cons['birth_year.sf_src_fv_id']), 'conflict1 - !birth_year src map' );
ok( !isset($cons['source_website.sf_fv_id']),     'conflict1 - !source_website map' );
ok( !isset($cons['source_website.sf_src_value']), 'conflict1 - !source_website value' );
ok( !isset($cons['source_website.sf_src_fv_id']), 'conflict1 - !source_website src map' );
ok( !isset($cons['timezone.sf_fv_id']),     'conflict1 - !timezone map' );
ok( !isset($cons['timezone.sf_src_value']), 'conflict1 - !timezone value' );
ok( !isset($cons['timezone.sf_src_fv_id']), 'conflict1 - !timezone src map' );
