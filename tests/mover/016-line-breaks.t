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
require_once APPPATH.'/../tests/models/TestProject.php';
require_once APPPATH.'/../tests/models/TestInquiry.php';
require_once APPPATH.'/../tests/models/TestUser.php';
require_once 'tank/CSVImporter.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$csv_dir = dirname(__FILE__).'/csv';

// helper function to write data to csv file
function write_csv_data($tank, $data) {
    $path = "/tmp/".$tank->tank_uuid.".csv";
    $fp = fopen($path, "w");
    fputcsv($fp, array_keys($data));
    fputcsv($fp, array_values($data));
    fclose($fp);
    $tank->copy_file($path);
    unlink($path);
}

// helper to get submission content from a tank
function get_subm_content($tank) {
    $tank->clearRelated('TankSource');
    if (count($tank->TankSource) == 1) {
        if (count($tank->TankSource[0]->TankResponseSet) == 1) {
            $trs = $tank->TankSource[0]->TankResponseSet[0];
            if (count($trs->TankResponse) == 3) {
                return $trs->TankResponse[2]->sr_orig_value;
            }
        }
    }
    return false;
}

// test data
$u = new TestUser();
$u->save();

$p = new TestProject();
$p->save();

// make sure manual-entry inquiry gets cleaned up
$me = $p->get_manual_entry_inquiry();
$i = new TestInquiry();
$i->assignIdentifier($me->identifier());
$i->my_uuid = $me->inq_uuid;

$t = new TestTank();
$t->tank_type = Tank::$TYPE_CSV;
$t->set_meta_field('csv_delim', ',');
$t->set_meta_field('csv_encl', '"');
$t->tank_user_id = $u->user_id;
$t->tank_status = Tank::$STATUS_CSV_NEW;
$t->TankActivity[0]->tact_type = TankActivity::$TYPE_SOURCE;
$t->TankActivity[0]->tact_actm_id = ActivityMaster::EMAIL_IN;
$t->TankActivity[0]->tact_prj_id = $p->prj_id;
$t->TankActivity[0]->tact_dtim = air2_date();
$t->TankActivity[0]->tact_desc = 'blah blah test';
$t->save();

plan(14);
/**********************
 * Test a bunch o' quotes
 */
$quotes = "This \"string\" contain's a bunch-o' \"quotes.";
$csv = array(
    'Email Address'      => 'testsource@test.test',
    'Submission Date'    => '11/5/10',
    'Submission Type'    => 'Email',
    'Submission Title'   => 'Email test yeah!',
    'Submission Content' => $quotes,
);
write_csv_data($t, $csv);

$imp = new CSVImporter($t);
$c = $imp->get_line_count();
is( $c, 1, 'csv quotes - line count' );
$v = $imp->validate_headers();
is( $v, true, 'csv quotes - headers valid' );
$n = $imp->import_file();
is( $n, 1, 'csv quotes - imported 1' );

$content = get_subm_content($t);
ok( $content, 'csv quotes - has content' );
is( strlen($content), strlen($quotes), 'csv quotes - length same' );
is( $content, $quotes, 'csv quotes - same string' );


/**********************
 * Now do newlines
 */
$t->TankSource->delete();
$t->refresh();
$t->tank_status = Tank::$STATUS_CSV_NEW;
$t->save();
$newlines   = "test line 1\ntest line 2\r test line 3\r\ntest line 4\n";
$normalized = "test line 1\ntest line 2\n test line 3\ntest line 4\n";
$csv['Submission Content'] = $newlines;
write_csv_data($t, $csv);

$imp = new CSVImporter($t);
$c = $imp->get_line_count();
is( $c, 1, 'csv newlines - line count' );
$v = $imp->validate_headers();
is( $v, true, 'csv newlines - headers valid' );
$n = $imp->import_file();
is( $n, 1, 'csv newlines - imported 1' );

$content = get_subm_content($t);
ok( $content, 'csv newlines - has content' );
isnt( strlen($content), strlen($newlines), 'csv newlines - length changed' );
isnt( $content, $newlines, 'csv newlines - content changed' );
isnt( strlen($content), strlen($normalized), 'csv newlines - length normalized' );
isnt( $content, $normalized, 'csv newlines - content normalized' );
