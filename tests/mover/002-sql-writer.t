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
require_once 'air2writer/SqlWriter.php';

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$conn->execute('drop table if exists test_related');
$conn->execute('drop table if exists test');
Doctrine::createTablesFromArray(array('TestRecord'));

// set directories
$csv_dir = dirname(__FILE__).'/csv';


plan(6);
/**********************
 * Test writing SQL from a valid CSV file
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


// insert atomic
$writer = new SqlWriter($conn, $db_mapping);
$num = $writer->write_data($reader);
$errs = $writer->get_errors();

is( $num, 4, "imported correct number of records into db" );
is( count($errs), 0, "imported with no errors" );
foreach ($errs as $e) echo "  *** ".$e->getMessage()."\n";

// fetch the objects
$testobjs = Doctrine_Query::create()->from('TestRecord t')->execute();
is( count($testobjs), 4, "count test objects in database" );

// remove objects from table
$conn->execute('delete from test');

// insert non-atomic
$writer->set_mode(false);
$num = $writer->write_data($reader);
$errs = $writer->get_errors();

is( $num, 4, "imported non-atomic correct number of records into db" );
is( count($errs), 0, "imported non-atomic with no errors" );
foreach ($errs as $e) echo "  *** ".$e->getMessage()."\n";

// fetch the objects
$testobjs = Doctrine_Query::create()->from('TestRecord t')->execute();
is( count($testobjs), 4, "count test objects in database" );

// cleanup
$conn->execute('drop table if exists test');

?>
