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

require_once 'Test.php';
require_once 'app/init.php';
require_once 'AirHttpTest.php';
require_once 'classes/TestRecord.php';
require_once 'Encoding.php';

// set up the table(s)
AIR2_DBManager::init();
// clean up table from any prior aborted run
$conn = AIR2_DBManager::get_master_connection();
$conn->execute('drop table if exists test');
// create new table
Doctrine::createTablesFromArray(array('TestRecord'));

// create a non-utf8 string, and a valid utf8 string
$str_valid = "\"I'd be cooler with smart quotes\"";
$str_invalid = sprintf("Check out these neat %ccurly quotes", 145);

plan(8);

// check that the encoding works right
is( Encoding::is_utf8($str_valid), true, "check valid utf8 encoding");
is( Encoding::is_utf8($str_invalid), false, "check invalid utf8 encoding");

// try to save valid to model
$test = new TestRecord();
$test->test_string = $str_valid;
is( Encoding::is_utf8($test->test_string), true, "set valid string");
try {
    $test->save();
    pass("save valid string");
} catch (Exception $exc) {
    fail("save valid string");
}

// try to save invalid to model
$test->test_string = $str_invalid;
is( Encoding::is_utf8($test->test_string), false, "set invalid (non-UTF8) string");
try {
    $test->save();
    fail("save invalid (non-UTF8) string");
} catch (Exception $exc) {
    pass("save invalid (non-UTF8) string");
}

// try to convert the invalid string
$test->test_string = Encoding::convert_to_utf8($str_invalid);
is( Encoding::is_utf8($test->test_string), true, "set converted string");
try {
    $test->save();
    pass("save converted string");
} catch (Exception $exc) {
    fail("save converted string");
}

// clean up table
$conn->execute('drop table test');

?>
