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
require_once 'tank/CSVImporter.php';

// init
AIR2_DBManager::init();
$csv_dir = dirname(__FILE__).'/csv';

$t = new TestTank();
$t->tank_user_id = 1;
$t->tank_type = Tank::$TYPE_CSV;
$t->tank_status = Tank::$STATUS_CSV_NEW;
$t->save();

$t->tank_name = 'test_header.csv';
$file = "$csv_dir/test_header.csv";
$t->copy_file($file);
$t->save();


plan(46);
/**********************
 * Test CSV Importer
 */
$imp = new CSVImporter($t);

$c = $imp->get_line_count();
is( $c, 6, 'csv line count' );
$c = $imp->get_line_count(3);
is( $c, false, 'csv line count exceeds 3' );
$v = $imp->validate_headers();
is( $v, true, 'csv headers valid' );


/**********************
 * Test bad header definitions
 */
$t->copy_file("$csv_dir/test_duplicate_headers.csv");
$v = $imp->validate_headers();
ok( preg_match('/duplicate/i', $v), 'duplicate header error' );

$t->copy_file("$csv_dir/test_header_no_name.csv");
$v = $imp->validate_headers();
ok( preg_match('/username/i', $v), 'no-username header error' );

$t->copy_file("$csv_dir/test_invalid_header.csv");
$v = $imp->validate_headers();
ok( preg_match('/Not A Column/', $v), 'invalid header error' );


/**********************
 * Test previewing
 */
$pre = $imp->preview_file();
ok( isset($pre['header']) && isset($pre['lines']), 'preview header and lines' );
$header = $pre['header'];
$lines = $pre['lines'];
is( count($header), 4, 'preview header 4 columns' );
is( $header[0]['valid'], true, 'preview header col0 valid' );
is( $header[2]['valid'], false, 'preview header col2 invalid' );
is( count($lines), 3, 'preview 3 lines' );
is( count($lines[0]), 4, 'preview lines 4 columns' );

$pre = $imp->preview_file(5);
$lines = $pre['lines'];
is( count($lines), 5, 'preview 5 lines' );


/**********************
 * Import with bad mapped value (Gender = 'MMale')
 */
$t->copy_file("$csv_dir/test_map_bad.csv");
$n = $imp->import_file();
ok( is_string($n), 'bad mapped value isstring' );
ok( preg_match('/mmale/i', $n), 'bad mapped value error msg' );
ok( preg_match('/row 2/i', $n), 'bad mapped value rownum' );
ok( preg_match('/column 7/i', $n), 'bad mapped value colnum' );



/**********************
 * Import with bad data type (smadd_zip is too long!)
 */
$t->copy_file("$csv_dir/test_map_length.csv");
$n = $imp->import_file();
ok( is_string($n), 'bad data type isstring' );
ok( preg_match('/smadd_zip length/i', $n), 'bad data type error msg' );
ok( preg_match('/row 5/i', $n), 'bad data type rownum' );
ok( preg_match('/column 3/i', $n), 'bad data type colnum' );


/**********************
 * Test importing
 */
$t->copy_file("$csv_dir/test_map_columns.csv");
$n = $imp->import_file();
is( $n, 6, "wrote 6 lines to db file" );

$t->refresh();
is( count($t->TankSource), 6, "found 6 TankSources in database" );
$tfacts = 0;
foreach ($t->TankSource as $tsrc) {
    $tfacts += count($tsrc->TankFact);
}
is( $tfacts, 4, 'added 4 tank_facts to database' );


/**********************
 * Test some different ways of identifying sources
 */
// identify by username ONLY (no other columns)
$t2 = new TestTank();
$t2->tank_user_id = 1;
$t2->tank_type = Tank::$TYPE_CSV;
$t2->tank_status = Tank::$STATUS_CSV_NEW;
$t2->save();
$t2->copy_file("$csv_dir/ident_only.csv");
$imp2 = new CSVImporter($t2);
$n = $imp2->import_file();
is( $n, 6, 'ident only - wrote 6' );
is( count($t2->TankSource), 6, 'ident only - tsrc 6' );

// id by email
$t2->TankSource->delete();
$t2->clearRelated('TankSource');
$t2->tank_status = Tank::$STATUS_CSV_NEW;
$t2->copy_file("$csv_dir/ident_email.csv");
$n = $imp2->import_file();
is( $n, 6, 'ident email - wrote 6' );
is( count($t2->TankSource), 6, 'ident email - tsrc 6' );

// id by both
$t2->TankSource->delete();
$t2->clearRelated('TankSource');
$t2->tank_status = Tank::$STATUS_CSV_NEW;
$t2->copy_file("$csv_dir/ident_both.csv");
$n = $imp2->import_file();
is( $n, 6, 'ident both - wrote 6' );
is( count($t2->TankSource), 6, 'ident both - tsrc 6' );

// identifier missing!
$t2->TankSource->delete();
$t2->clearRelated('TankSource');
$t2->tank_status = Tank::$STATUS_CSV_NEW;
$t2->copy_file("$csv_dir/ident_missing.csv");
$n = $imp2->import_file();
ok( is_string($n), 'ident missing - error!' );
ok( preg_match('/no identifier/i', $n), 'ident missing - err string' );
is( count($t2->TankSource), 0, 'ident missing - tsrc 0' );

// unique-identifier column error
$t2->TankSource->delete();
$t2->clearRelated('TankSource');
$t2->tank_status = Tank::$STATUS_CSV_NEW;
$t2->copy_file("$csv_dir/ident_unique.csv");
$n = $imp2->import_file();
is( $n, 6, 'ident unique - NO MORE error!' );
is( count($t2->TankSource), 6, 'ident unique - tsrc 6' );


/**********************
 * Make sure blank rows don't get imported
 */
$t2->TankSource->delete();
$t2->clearRelated('TankSource');
$t2->tank_status = Tank::$STATUS_CSV_NEW;
$t2->copy_file("$csv_dir/blank_row_start.csv");
$n = $imp2->import_file();
ok( is_string($n), 'blank row start - error!' );
ok( preg_match('/no identifier/i', $n), 'blank row start - err string' );
is( count($t2->TankSource), 0, 'blank row start - tsrc 0' );

$t2->TankSource->delete();
$t2->clearRelated('TankSource');
$t2->tank_status = Tank::$STATUS_CSV_NEW;
$t2->copy_file("$csv_dir/blank_row_middle.csv");
$n = $imp2->import_file();
ok( is_string($n), 'blank row middle - error!' );
ok( preg_match('/no identifier/i', $n), 'blank row middle - err string' );
is( count($t2->TankSource), 0, 'blank row middle - tsrc 0' );

$t2->TankSource->delete();
$t2->clearRelated('TankSource');
$t2->tank_status = Tank::$STATUS_CSV_NEW;
$t2->copy_file("$csv_dir/blank_row_end.csv");
$n = $imp2->import_file();
ok( is_string($n), 'blank row end - error!' );
ok( preg_match('/no identifier/i', $n), 'blank row end - err string' );
is( count($t2->TankSource), 0, 'blank row end - tsrc 0' );

/**********************
 * Support various language values
 */
$t2->TankSource->delete();
$t2->clearRelated('TankSource');
$t2->tank_status = Tank::$STATUS_CSV_NEW;
$t2->copy_file("$csv_dir/test_map_language.csv");
$n = $imp2->import_file();
is( $n, 4, 'able to import all permutations of English/Spanish' );
is( count($t2->TankSource), 4, 'languague values - tsrc 4' );
