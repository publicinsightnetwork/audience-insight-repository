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

require_once 'air2reader/CSVReader.php';

// set directories
$csv_dir = dirname(__FILE__).'/csv';


plan(11);
/**********************
 * Test parsing a CSV file with only '\r' in it (OSX will sometimes do this)
 */
$reader = new CSVReader("$csv_dir/test_cr_only.csv");
$num_cols = 32;

$count = 0;
foreach ($reader as $idx => $line) {
    is( count($line['data']), $num_cols, "read correct num cols - $idx" );
    $count++;
}

is( $count, 10, 'read 10 lines total' );


?>
