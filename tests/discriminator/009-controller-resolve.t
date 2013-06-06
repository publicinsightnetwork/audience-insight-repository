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
require_once APPPATH.'/../tests/AirHttpTest.php';
require_once APPPATH.'/../tests/models/TestTank.php';
require_once APPPATH.'/../tests/models/TestSource.php';
require_once 'phperl/callperl.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$browser = new AirHttpTest();
$browser->set_test_user();
$browser->set_content_type(AirHttpTest::$JSON);

$tbl_fact = Doctrine::getTable('Fact');
$tbl_fv = Doctrine::getTable('FactValue');
plan(51);

/* get some fact/fact_value ids */
$f_gender = $tbl_fact->findOneBy('fact_identifier', 'gender')->fact_id;
$fv_gender_1 = $tbl_fv->findOneBy('fv_value', 'Male')->fv_id;
$fv_gender_2 = $tbl_fv->findOneBy('fv_value', 'Female')->fv_id;

function reset_source() {
    global $s, $f_gender, $fv_gender_1;
    if ($s) $s->delete();
    $s = new TestSource();
    $s->src_first_name = 'Testfirstname';
    $s->src_last_name = 'Testlastname';
    $s->SrcFact[0]->sf_fact_id = $f_gender;
    $s->SrcFact[0]->sf_fv_id = $fv_gender_1;
    $s->save();
}
function reset_tank() {
    global $tank, $ts, $ts2, $s;
    if ($tank) $tank->delete();

    $tank = new TestTank();
    $tank->tank_user_id = 1;
    $tank->tank_type = Tank::$TYPE_FB;
    $tank->tank_status = Tank::$STATUS_READY;
    $tank->TankSource[0]->src_id = $s->src_id;
    $tank->TankSource[1]->src_id = $s->src_id;
    $tank->save();

    $ts = $tank->TankSource[0];
    $ts2 = $tank->TankSource[1];
    $tank->clearRelated();
}
function reset_all() {
    reset_source();
    reset_tank();
    refresh_all();
}
function refresh_all() {
    global $tank, $ts, $ts2, $s;
    $tank->clearRelated();
    $tank->refresh();
    $s->clearRelated();
    $s->refresh();
    $ts->clearRelated();
    $ts->refresh();
    $ts2->clearRelated();
    $ts2->refresh();
}


/**********************
 * Test status codes
 */
reset_all();
$nav = '/tank/'.$tank->tank_uuid.'/source/'.$ts->tsrc_id;
ok( $resp = $browser->http_get($nav), 'GET resolver' );
is( $browser->resp_code(), 200, 'GET resolver - resp code');
ok( $resp = $browser->http_put($nav), 'PUT resolver' );
is( $browser->resp_code(), 200, 'PUT resolver - resp code');
ok( $resp = $browser->http_delete($nav), 'DELETE resolver' );
is( $browser->resp_code(), 405, 'DELETE resolver - resp code');
ok( $resp = $browser->http_post($nav), 'POST resolver' );
is( $browser->resp_code(), 405, 'POST resolver - resp code');

$bad_nav1 = '/tank/DOESNOTEXIST/source/'.$ts->tsrc_id;
$bad_nav2 = '/tank/'.$tank->tank_uuid.'/source/DOESNOTEXIST';
ok( $resp = $browser->http_put($bad_nav1), 'resolver bad_nav1' );
is( $browser->resp_code(), 404, 'resolver bad_nav1 - resp code');
ok( $resp = $browser->http_put($bad_nav2), 'resolver bad_nav2' );
is( $browser->resp_code(), 404, 'resolver bad_nav2 - resp code');


/**********************
 * Create a conflicts
 */
$ts->tsrc_status = TankSource::$STATUS_NEW;
$ts->src_first_name = 'Harold';
$ts->src_last_name = 'Aliaslast';
$ts->TankFact[0]->tf_fact_id = $f_gender;
$ts->TankFact[0]->sf_fv_id = $fv_gender_2;
$ts->save();
$ts2->tsrc_status = TankSource::$STATUS_NEW;
$ts2->src_first_name = 'Harold2';
$ts2->src_last_name = 'Aliaslast2';
$ts2->TankFact[0]->tf_fact_id = $f_gender;
$ts2->TankFact[0]->sf_fv_id = $fv_gender_2;
$ts2->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $tank->tank_id);
ok( $report, 'setup report - ok' );
is( $report['conflict'], 2, 'setup report - 2 conflict' );


/**********************
 * Make sure we've got some "conflict with" data
 */
ok( $resp = $browser->http_get($nav), 'get with' );
is( $browser->resp_code(), 200, 'get with - resp code');
ok( $json = json_decode($resp,true), 'get with - json' );
is( $json['success'], true, 'get with - success' );
ok( isset($json['radix']['next_conflict']), 'get with - next_conflict' );
is( $json['radix']['next_conflict'], $ts2->tsrc_id, 'get with - next tsrc_id' );

ok( isset($json['radix']['tsrc_withs']), 'get with - tsrc_withs' );
is( count($json['radix']['tsrc_withs']), 3, 'get with - 3 withs' );
ok( isset($json['radix']['tsrc_withs']['src_first_name']), 'get with - with first' );
ok( isset($json['radix']['tsrc_withs']['src_last_name']), 'get with - with last' );
ok( isset($json['radix']['tsrc_withs']['gender.sf_fv_id']), 'get with - with gender' );


/**********************
 * Resolve half the conflict
 */
$params = array(
    'resolve' => array('Source' => 'R'),
);
ok( $resp = $browser->http_put($nav, array('radix' => json_encode($params))), 'half-resolver' );
is( $browser->resp_code(), 200, 'half-resolver - resp code');
ok( $json = json_decode($resp,true), 'half-resolver - json' );
is( $json['success'], true, 'half-resolver - success' );
ok( isset($json['radix']), 'half-resolver - radix');
$errs = json_decode($json['radix']['tsrc_errors'], true);
ok( $errs, 'half-resolver - errors');
is( count($errs['initial']), 3, 'half-resolver - 3 initial conflicts' );
is( count($errs['last']), 1, 'half-resolver - 1 last conflict' );
ok( isset($errs['last']['gender.sf_fv_id']), 'half-resolver - conflict match' );


/**********************
 * Check the actual data
 */
refresh_all();
is( $tank->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'unresolved - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'unresolved - tsrc_status' );
isnt( $s->src_first_name, $ts->src_first_name, 'unresolved - first name not imported' );


/**********************
 * Resolve the entire conflict
 */
$params = array(
    'resolve' => array(
        'src_first_name' => 'R',
        'src_last_name'  => 'A',
        'gender'         => 'I',
    ),
);
ok( $resp = $browser->http_put($nav, array('radix' => json_encode($params))), 'whole-resolver' );
is( $browser->resp_code(), 200, 'whole-resolver - resp code');
ok( $json = json_decode($resp,true), 'whole-resolver - json' );
is( $json['success'], true, 'whole-resolver - success' );
ok( isset($json['radix']), 'whole-resolver - radix');
ok( !$json['radix']['tsrc_errors'], 'whole-resolver - no errors');
is( $json['radix']['tsrc_status'], TankSource::$STATUS_RESOLVED, 'whole-resolver - status');


/**********************
 * Check the actual data
 */
refresh_all();
is( $tank->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'resolved - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_RESOLVED, 'resolved - tsrc_status' );
is( $s->src_first_name, $ts->src_first_name, 'resolved - first name imported' );
is( count($s->SrcAlias), 1, 'resolved - SrcAlias count' );
is( $s->SrcAlias[0]->sa_last_name, 'Aliaslast', 'resolved - SrcAlias value' );
is( $s->SrcFact[0]->sf_fact_id, $f_gender, 'resolved - fact_id' );
is( $s->SrcFact[0]->sf_fv_id, $fv_gender_1, 'resolved - fv_id ignored' );

