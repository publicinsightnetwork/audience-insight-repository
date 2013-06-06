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


plan(32);
/**********************
 * Test parsing a valid CSV file
 */
$reader = new CSVReader("$csv_dir/test_valid.csv", ';');
$expected = array(
    array('MYUUID0001', 'this is a test string', '2020-02-20 20:20:20'),
    array('MYUUID0002', 'this is a \'test\' string', '2020-02-20 20:20:20'),
    array('MYUUID0003', "this\nis\na\nmultiline\ntest\nstring", '2020-02-20 20:20:20'),
    array('MYUUID0004', 'last', '2020-02-20 20:20:20'),
);

$count = 0;
foreach ($reader as $idx => $line) {
    ok( isset($line['row']), "csv-valid-$idx row number set" );
    ok( isset($line['data']), "csv-valid-$idx data set" );
    is( $idx, $count, "csv-valid-$idx correct index" );
    is( $line['row'], $count + 1, "csv-valid-$idx correct row" );

    // check the data count
    is( count($line['data']), 3, "csv-valid-$idx has 3 items per data line" );

    // check against expected data
    foreach ($line['data'] as $col => $data) {
        is( $data, $expected[$idx][$col], "csv-valid-$idx correct data at ($idx, $col)" );
    }

    $count++;
}


?>
