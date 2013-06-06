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
require_once APPPATH.'/../tests/classes/TestRecord.php';

require_once 'air2reader/CSVReader.php';
require_once 'air2writer/MySqlImporter.php';

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$conn->execute('drop table if exists test');
Doctrine::createTablesFromArray(array('TestRecord'));

// set directories
$csv_dir = dirname(__FILE__).'/csv';
$tmp_dir = dirname(__FILE__).'/csv/tmp';


plan(21);
/**********************
 * Test parsing a valid CSV file
 */
$reader = new CSVReader("$csv_dir/test_valid.csv", ';');
$db_mapping = array(
    'test' => array(
        'test_uuid' => array('map' => 0),
        'test_string' => array('map' => 1),
        'test_cre_user' => array('val' => 10),
        'test_cre_dtim' => array('map' => 2),
    ),
);

$writer = new MySqlImporter($tmp_dir, $db_mapping, $conn);
$num = $writer->write_data($reader);
$errs = $writer->get_errors();

is( $num, 4, "wrote correct number of recs to file" );
is( count($errs), 0, "imported with no errors" );
foreach ($errs as $e) echo "  *** ".$e->getMessage()."\n";

$testobjs = Doctrine_Query::create()->from('TestRecord t')->execute();
is( count($testobjs), 0, "nothing written to DB yet" );

$num_db = $writer->exec_load_infile();
is( $num_db, 4, "imported correct number of records into db" );


// fetch the objects
$expected = array(
    array('MYUUID0001', 'this is a test string', '2020-02-20 20:20:20'),
    array('MYUUID0002', 'this is a \'test\' string', '2020-02-20 20:20:20'),
    array('MYUUID0003', "this\nis\na\nmultiline\ntest\nstring", '2020-02-20 20:20:20'),
    array('MYUUID0004', 'last', '2020-02-20 20:20:20'),
);
$testobjs = Doctrine_Query::create()->from('TestRecord t')->execute();

is( count($testobjs), 4, "count test objects in database" );
foreach ($testobjs as $idx => $obj) {
    is( $obj->test_uuid, $expected[$idx][0], "object $idx test_uuid" );
    is( $obj->test_string, $expected[$idx][1], "object $idx test_string" );
    is( $obj->test_cre_dtim, $expected[$idx][2], "object $idx test_cre_dtim" );
    is( $obj->test_cre_user, 10, "object $idx test_cre_user" );
}


// cleanup
$conn->execute('drop table if exists test');
unlink("$tmp_dir/test");
rmdir($tmp_dir);

?>
