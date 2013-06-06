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

/****************************************************************
 * TEST DISCRIMINATOR ADD-AS-PRIMARY                            *
 *                                                              *
 * Make sure discriminator add/add-as-primary ops include       *
 * all incoming data, whether or not those fields were included *
 * in the line-item operations.                                 *
 *                                                              *
 ****************************************************************/

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// setup
$s = new TestSource();
$s->SrcMailAddress[0]->smadd_line_1 = '1234 Fake Street';
$s->SrcMailAddress[0]->smadd_line_2 = 'Apt #1458';
$s->SrcMailAddress[0]->smadd_city = 'St. Paul';
$s->SrcMailAddress[0]->smadd_state = 'MN';
$s->SrcMailAddress[0]->smadd_zip = '55101';
$s->save();

$t = new TestTank();
$t->tank_user_id = 1;
$t->tank_type = Tank::$TYPE_FB;
$t->tank_status = Tank::$STATUS_READY;
$t->TankSource[0]->src_id = $s->src_id;
$t->save();
$ts = $t->TankSource[0];
$t->clearRelated();


plan(66);

/**********************
 * Create a conflict (by line-1)
 */
$ts->smadd_line_1 = '1234 fake street';
$ts->smadd_line_2 = 'PO Box 2';
$ts->smadd_city = 'Hudson';
$ts->smadd_state = 'WI';
$ts->smadd_zip = '55555';
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'conflict - ok' );
is( $t->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'conflict - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'conflict - tsrc_status' );
is( $report['conflict'], 1, 'conflict - conflict count' );
is( count($s->SrcMailAddress), 1, 'conflict - still 1 mail address' );
is( $s->SrcMailAddress[0]->smadd_primary_flag, true, 'conflict - 1st is primary' );

$errs = json_decode($ts->tsrc_errors, true);
ok( isset($errs['initial']), 'conflict - initial conflicts' );
$cons = $errs['initial'];

ok( !isset($cons['smadd_primary_flag']), 'conflict - !primary' );
ok( !isset($cons['smadd_context']),      'conflict - !context' );
ok( !isset($cons['smadd_line_1']),       'conflict - !line1' );
ok( isset($cons['smadd_line_2']),        'conflict - line2' );
ok( isset($cons['smadd_city']),          'conflict - city' );
ok( isset($cons['smadd_state']),         'conflict - state' );
ok( !isset($cons['smadd_cntry']),        'conflict - !cntry' );
ok( isset($cons['smadd_zip']),           'conflict - zip' );
ok( !isset($cons['smadd_lat']),          'conflict - !lat' );
ok( !isset($cons['smadd_long']),         'conflict - !long' );


/**********************
 * Resolve conflict through ADD_AS_PRIMARY
 */
$ops = array(
    'smadd_line_2' => 'P',
    'smadd_city'   => 'A',
    'smadd_state'  => 'R',
    'smadd_zip'    => 'I',
);
$stat = CallPerl::exec('AIR2::TankSource->discriminate', $ts->tsrc_id, $ops);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $stat, 'resolve - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'resolve - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_RESOLVED, 'resolve - tsrc_status' );
is( count($s->SrcMailAddress), 2, 'resolve - now 2 mail address' );

// existing record just replaces state
is( $s->SrcMailAddress[0]->smadd_primary_flag,  false,              'resolve - 1st primary' );
is( $s->SrcMailAddress[0]->smadd_line_1,        '1234 Fake Street', 'resolve - 1st line 1' );
is( $s->SrcMailAddress[0]->smadd_line_2,        'Apt #1458',        'resolve - 1st line 2' );
is( $s->SrcMailAddress[0]->smadd_city,          'St. Paul',         'resolve - 1st city' );
is( $s->SrcMailAddress[0]->smadd_state,         'WI',               'resolve - 1st state' );
is( $s->SrcMailAddress[0]->smadd_zip,           '55101',            'resolve - 1st zip' );

// new record gets copy of all data, no matter what the resolution
is( $s->SrcMailAddress[1]->smadd_primary_flag,  true,               'resolve - 2nd primary' );
is( $s->SrcMailAddress[1]->smadd_line_1,        '1234 fake street', 'resolve - 2nd line 1' );
is( $s->SrcMailAddress[1]->smadd_line_2,        'PO Box 2',         'resolve - 2nd line 2' );
is( $s->SrcMailAddress[1]->smadd_city,          'Hudson',           'resolve - 2nd city' );
is( $s->SrcMailAddress[1]->smadd_state,         'WI',               'resolve - 2nd state' );
is( $s->SrcMailAddress[1]->smadd_zip,           '55555',            'resolve - 2nd zip' );

// cleanup
$s->SrcMailAddress[1]->delete();
$s->SrcMailAddress[0]->smadd_primary_flag = true;
$s->SrcMailAddress[0]->smadd_line_2 = null;
$s->SrcMailAddress[0]->save();
$s->clearRelated();
$ts->delete();
$t->clearRelated();

$t->TankSource[0]->src_id = $s->src_id;
$t->save();
$ts = $t->TankSource[0];
$t->clearRelated();


/**********************
 * Create another conflict (by line-1)
 */
$ts->smadd_line_1 = '1234 fake street';
$ts->smadd_line_2 = 'PO Box 3';
$ts->smadd_city = 'Denver';
$ts->smadd_state = 'CO';
$ts->smadd_zip = '55556';
$ts->save();

$report = CallPerl::exec('AIR2::Tank->discriminate', $t->tank_id);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $report, 'conflict2 - ok' );
is( $t->tank_status, Tank::$STATUS_TSRC_CONFLICTS, 'conflict2 - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_CONFLICT, 'conflict2 - tsrc_status' );
is( $report['conflict'], 1, 'conflict2 - conflict count' );
is( count($s->SrcMailAddress), 1, 'conflict2 - still 1 mail address' );
is( $s->SrcMailAddress[0]->smadd_primary_flag, true, 'conflict2 - 1st is primary' );

$errs = json_decode($ts->tsrc_errors, true);
ok( isset($errs['initial']), 'conflict2 - initial conflicts' );
$cons = $errs['initial'];

ok( !isset($cons['smadd_primary_flag']), 'conflict2 - !primary' );
ok( !isset($cons['smadd_context']),      'conflict2 - !context' );
ok( !isset($cons['smadd_line_1']),       'conflict2 - !line1' );
ok( !isset($cons['smadd_line_2']),       'conflict2 - !line2' );
ok( isset($cons['smadd_city']),          'conflict2 - city' );
ok( isset($cons['smadd_state']),         'conflict2 - state' );
ok( !isset($cons['smadd_cntry']),        'conflict2 - !cntry' );
ok( isset($cons['smadd_zip']),           'conflict2 - zip' );
ok( !isset($cons['smadd_lat']),          'conflict2 - !lat' );
ok( !isset($cons['smadd_long']),         'conflict2 - !long' );


/**********************
 * ADD_AS_PRIMARY, but with no replace.  Should NOT alter the
 * existing address in any way.
 */
$ops = array(
    // 'smadd_line_2' => 'P',
    'smadd_city'   => 'P',
    'smadd_state'  => 'R',
    'smadd_zip'    => 'I',
);
$stat = CallPerl::exec('AIR2::TankSource->discriminate', $ts->tsrc_id, $ops);
$s->clearRelated();
$s->refresh();
$t->refresh();
$ts = $t->TankSource[0];
$t->clearRelated();

ok( $stat, 'resolve2 - ok' );
is( $t->tank_status, Tank::$STATUS_READY, 'resolve2 - tank_status' );
is( $ts->tsrc_status, TankSource::$STATUS_RESOLVED, 'resolve2 - tsrc_status' );
is( count($s->SrcMailAddress), 2, 'resolve2 - now 2 mail address' );

// existing record just replaces zip
is( $s->SrcMailAddress[0]->smadd_primary_flag,  false,              'resolve2 - 1st primary' );
is( $s->SrcMailAddress[0]->smadd_line_1,        '1234 Fake Street', 'resolve2 - 1st line 1' );
is( $s->SrcMailAddress[0]->smadd_line_2,        null,               'resolve2 - 1st line 2' );
is( $s->SrcMailAddress[0]->smadd_city,          'St. Paul',         'resolve2 - 1st city' );
is( $s->SrcMailAddress[0]->smadd_state,         'CO',               'resolve2 - 1st state' );
is( $s->SrcMailAddress[0]->smadd_zip,           '55101',            'resolve2 - 1st zip' );

// new record gets copy of all data, no matter what the resolution
is( $s->SrcMailAddress[1]->smadd_primary_flag,  true,               'resolve2 - 2nd primary' );
is( $s->SrcMailAddress[1]->smadd_line_1,        '1234 fake street', 'resolve2 - 2nd line 1' );
is( $s->SrcMailAddress[1]->smadd_line_2,        'PO Box 3',         'resolve2 - 2nd line 2' );
is( $s->SrcMailAddress[1]->smadd_city,          'Denver',           'resolve2 - 2nd city' );
is( $s->SrcMailAddress[1]->smadd_state,         'CO',               'resolve2 - 2nd state' );
is( $s->SrcMailAddress[1]->smadd_zip,           '55556',            'resolve2 - 2nd zip' );
