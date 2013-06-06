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
require_once 'air2validator/ColumnCountValidator.php';
require_once 'air2validator/DoctrineTableValidator.php';

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$conn->execute('drop table if exists test');
Doctrine::createTablesFromArray(array('TestRecord'));

// setup db connection
$cred = AIR2_DBManager::$master;
$rsc = mysql_connect($cred['hostname'], $cred['username'], $cred['password']);
mysql_select_db($cred['dbname'], $rsc);

// set directories
$csv_dir = dirname(__FILE__).'/csv';
$tmp_dir = dirname(__FILE__).'/csv/tmp';

// setup writer
$db_mapping = array(
    'test' => array(
        'test_uuid' => array('map' => 0),
        'test_string' => array('map' => 1),
        'test_cre_user' => array('val' => 10),
        'test_cre_dtim' => array('map' => 2),
    ),
);
$writer = new MySqlImporter($tmp_dir, $db_mapping, $rsc);

// create some validators
$valid1 = new ColumnCountValidator(3);
$valid2 = array(
    new ColumnCountValidator(3),
    new DoctrineTableValidator(array(
        'TestRecord:test_uuid',
        'TestRecord:test_string',
        'TestRecord:test_cre_dtim',
    )),
);


plan(19);
/**********************
 * Test column count validation on invalid csv
 */
$reader = new CSVReader("$csv_dir/test_invalid_1.csv", ';');
$num = $writer->write_data($reader, $valid1);
$errs = $writer->get_errors();

// atomic, non-breaking
is( $num, 0, "invalid_1 imported 0" );
is( count($errs), 2, "invalid_1 returns 2 errors" );
ok( preg_match('/row 2/', $errs[0]->getMessage()), 'invalid_1 error on row 2' );

// non-atomic, non-breaking
$writer->set_mode(false, false);
$num = $writer->write_data($reader, $valid1);
$errs = $writer->get_errors();
is( $num, 2, "invalid_1 non-atomic imported 2" );
is( count($errs), 2, "invalid_1 non-atomic returns 2 errors" );

// atomic, breaking
$writer->set_mode(true, true);
$num = $writer->write_data($reader, $valid1);
$errs = $writer->get_errors();
is( $num, 0, "invalid_1 atomic-breaking imported 0" );
is( count($errs), 1, "invalid_1 atomic-breaking returns 1 error" );

// non-atomic, breaking
$writer->set_mode(false, true);
$num = $writer->write_data($reader, $valid1);
$errs = $writer->get_errors();
is( $num, 1, "invalid_1 non-atomic-breaking imported 1" );
is( count($errs), 1, "invalid_1 non-atomic-breaking returns 1 error" );


/**********************
 * Test doctrine validation on invalid csv
 */
// add doctrine mappings to a new writer
$db_mapping['test']['test_uuid']['doc'] = 'TestRecord';
$db_mapping['test']['test_string']['doc'] = 'TestRecord';
$db_mapping['test']['test_cre_dtim']['doc'] = 'TestRecord';
$writer2 = new MySqlImporter($tmp_dir, $db_mapping, $rsc);
$reader = new CSVReader("$csv_dir/test_invalid_2.csv", ';');

// atomic, non-breaking
$num = $writer2->write_data($reader, $valid2);
$errs = $writer2->get_errors();
is( $num, 0, "invalid_2 imported 0" );
is( count($errs), 2, "invalid_2 returns 2 errors" );

// check error lines and types
$e1 = isset($errs[0]) ? $errs[0]->getMessage() : '';
$e2 = isset($errs[1]) ? $errs[1]->getMessage() : '';
ok( preg_match('/row 3/', $e1), 'invalid_2 error on row 3' );
ok( preg_match('/column 1/', $e1), 'invalid_2 error on column 1' );
ok( preg_match('/row 5/', $e2), 'invalid_2 error on row 5' );
ok( preg_match('/column 3/', $e2), 'invalid_2 error on column 3' );
ok( preg_match('/test_uuid.+length/', $e1), 'invalid_2 error on test_uuid length' );
ok( preg_match('/test_cre_dtim.+type/', $e2), 'invalid_2 error on test_cre_dtim type' );

// non-atomic, non-breaking
$writer2->set_mode(false, false);
$num = $writer2->write_data($reader, $valid2);
$errs = $writer2->get_errors();
is( $num, 4, "invalid_2 non-atomic imported 4" );
is( count($errs), 2, "invalid_2 non-atomic returns 2 errors" );



// cleanup
$conn->execute('drop table if exists test');
unlink("$tmp_dir/test");
rmdir($tmp_dir);

?>
