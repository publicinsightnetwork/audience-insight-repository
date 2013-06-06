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

/***********************************
 * Test CI exception handling
 */
$browser = new AirHttpTest();
$browser->set_test_user();
$browser->set_content_type(AirHttpTest::$HTML);


/*
 * Note that PROD environments will return 404's for any test URL... just pass.
 */
if (AIR2_ENVIRONMENT == 'prod') {
    plan(1);
    $browser->http_get('test/exception');
    is($browser->resp_code(), 404, 'PROD test url returns 404');
    exit;
}


/*
 * Normal testing
 */
plan(6);

$page = $browser->http_get('test/exception');
is($browser->resp_code(), 500, 'HTTP error 500');
is($browser->resp_content_type(), AirHttpTest::$HTML, 'Returned content type');

// ask for content type AIR can't return
$page = $browser->http_get('test/exception.nosuchtype');
is($browser->resp_code(), 415, ".nosuchtype is unsupported");
is($browser->resp_content_type(), 'text/plain',
    'unsupported content-type returns text/plain response');
//diag( $page );


// trigger an exception in the View
$browser = new AirHttpTest();
$browser->set_user('testuser', array());
$page = $browser->http_get('test/view_exception');
is($browser->resp_code(), 500, "internal server error in View exception");
is($browser->resp_content_type(), 'text/html',
    'text/html content_type for View exception');
//diag($page);


?>

