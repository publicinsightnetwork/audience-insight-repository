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

$t->tank_name = 'all_fields.csv';
$file = "$csv_dir/all_fields.csv";
$t->copy_file($file);
$t->save();


plan(9);
/**********************
 * Test CSV Importer
 */
$imp = new CSVImporter($t);

$c = $imp->get_line_count();
is( $c, 1, 'csv line count' );
$v = $imp->validate_headers();
is( $v, true, 'csv headers valid' );


/**********************
 * Test previewing
 */
$pre = $imp->preview_file();
ok( isset($pre['header']) && isset($pre['lines']), 'preview header and lines' );
$header = $pre['header'];
$lines = $pre['lines'];
is( count($header), 41, 'preview header 40 columns' );
is( count($lines), 1, 'preview 1 lines' );


/**********************
 * Test importing
 */
$n = $imp->import_file();
is( $n, 1, "wrote 1 lines to db file" );

$t->refresh(true);
is( count($t->TankSource), 1, "found 1 TankSources in database" );
$tfacts = 0;
$tvita = 0;
foreach ($t->TankSource as $tsrc) {
    $tfacts += count($tsrc->TankFact);
    $tvita += count($tsrc->TankVita);
}
is( $tfacts, 10, 'added 10 tank_facts to database' );
is( $tvita,  2,  'added 2 tank_vita to database' );
