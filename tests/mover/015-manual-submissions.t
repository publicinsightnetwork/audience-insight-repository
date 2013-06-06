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
require_once 'tank/CSVImporter.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$csv_dir = dirname(__FILE__).'/csv';

$p = new TestProject();
$p->save();

// cleanup previously aborted run (manual inquiry will be leftover)
$old_uuid = air2_str_to_uuid('me-'.$p->prj_name);
$n = $conn->exec('delete from tank where tank_user_id = 1');
$n = $conn->exec('delete from inquiry where inq_uuid = ?', array($old_uuid));


// make sure manual-entry inquiry gets cleaned up
$me = $p->get_manual_entry_inquiry();
$i = new TestInquiry();
$i->assignIdentifier($me->identifier());
$i->my_uuid = $me->inq_uuid;
//putenv('AIR_DEBUG=1');

$t = new TestTank();
$t->tank_user_id = 1;
$t->tank_type = Tank::$TYPE_CSV;
$t->tank_status = Tank::$STATUS_CSV_NEW;
$t->TankActivity[0]->tact_type = TankActivity::$TYPE_SOURCE;
$t->TankActivity[0]->tact_actm_id = ActivityMaster::SRCINFO_UPDATED;
$t->TankActivity[0]->tact_prj_id = $p->prj_id;
$t->TankActivity[0]->tact_dtim = air2_date();
$t->TankActivity[0]->tact_desc = 'test desc';
$t->TankActivity[0]->tact_notes = 'test notes';
$t->save();

$t->tank_name = 'manual_submission.csv';
$file = "$csv_dir/manual_submission.csv";
$t->copy_file($file);
$t->save();


plan(31);
/**********************
 * Validate CSV
 */
$imp = new CSVImporter($t);
$c = $imp->get_line_count();
is( $c, 6, 'csv line count' );
$v = $imp->validate_headers();
is( $v, true, 'csv headers valid' );


/**********************
 * Preview
 */
$pre = $imp->preview_file();
ok( isset($pre['header']) && isset($pre['lines']), 'preview header and lines' );
$header = $pre['header'];
$lines = $pre['lines'];
is( count($header), 5, 'preview header 5 columns' );
is( count($lines), 3, 'preview 3 lines' );
is( count($lines[0]), 5, 'preview lines 5 columns' );


/**********************
 * Import file
 */
$n = $imp->import_file();
is( $n, 6, 'submissions - imported 6' );

$tsrc_count = 0;
$trs_count = 0;
$tr_count = 0;
foreach ($t->TankSource as $tsrc) {
    $tsrc_count++;
    foreach ($tsrc->TankResponseSet as $trs) {
        $trs_count++;
        $tr_count += count($trs->TankResponse);
    }
}

is( $tsrc_count, 6, "found 6 TankSources in database" );
is( $trs_count, 6, "found 6 TankResponseSets in database" );
is( $tr_count, 18, "found 18 TankResponses in database" );


/**********************
 * Interrogate actual data
 */
$date = air2_date(strtotime('06/14/2012'));
$all_dates_okay = true;
foreach ($t->TankSource as $tsrc) {
    foreach ($tsrc->TankResponseSet as $trs) {
        if ($trs->srs_date != $date) {
            $all_dates_okay = false;
        }
    }
}
ok( $all_dates_okay, "all dates parsed correctly" );

$srs1 = $t->TankSource[0]->TankResponseSet[0];
is( $srs1->srs_type, SrcResponseSet::$TYPE_MANUAL_ENTRY, 'manual inquiry type' );
is( $srs1->srs_inq_id, $i->inq_id, 'manual inquiry id' );
is( $srs1->TankResponse[0]->sr_orig_value, 'Email', 'ques1 value' );
is( $srs1->TankResponse[1]->sr_orig_value, 'test title 1', 'ques2 value' );
is( $srs1->TankResponse[2]->sr_orig_value, 'test submission content 1', 'ques3 value' );

// avoid delete-constraint errors on tank_responses
$t->TankSource->delete();


/**********************
 * Check import activities
 */
$t->clearRelated('TankActivity');
is( count($t->TankActivity), 1, '1 activities created' );
is( $t->TankActivity[0]->tact_actm_id, ActivityMaster::SRCINFO_UPDATED, 'actv1 actm_id' );


/**********************
 * Invalid CSV's
 */
$t->clearRelated('TankSource');
$t->tank_status = Tank::$STATUS_CSV_NEW;
$t->copy_file("$csv_dir/manual_bad_date.csv");
$n = $imp->import_file();
ok( is_string($n), 'bad date - error!' );
ok( preg_match('/bad date/i', $n), 'bad date - err string' );
is( count($t->TankSource), 0, 'bad date - tsrc 0' );

$t->TankSource->delete();
$t->clearRelated('TankSource');
$t->tank_status = Tank::$STATUS_CSV_NEW;
$t->copy_file("$csv_dir/manual_bad_type.csv");
$n = $imp->import_file();
ok( is_string($n), 'bad type - error!' );
ok( preg_match('/invalid type/i', $n), 'bad type - err string' );
is( count($t->TankSource), 0, 'bad type - tsrc 0' );

$t->TankSource->delete();
$t->clearRelated('TankSource');
$t->tank_status = Tank::$STATUS_CSV_NEW;
$t->copy_file("$csv_dir/manual_missing_col.csv");
$n = $imp->import_file();
ok( is_string($n), 'missing col - error!' );
ok( preg_match('/missing/i', $n), 'missing col - err string' );
is( count($t->TankSource), 0, 'missing col - tsrc 0' );

$t->TankSource->delete();
$t->clearRelated('TankSource');
$t->tank_status = Tank::$STATUS_CSV_NEW;
$t->copy_file("$csv_dir/manual_no_text.csv");
$n = $imp->import_file();
ok( is_string($n), 'no text - error!' );
ok( preg_match('/description required/i', $n), 'no text - err string 1' );
ok( preg_match('/text value required/i', $n), 'no text - err string 2' );
is( count($t->TankSource), 0, 'no text - tsrc 0' );
