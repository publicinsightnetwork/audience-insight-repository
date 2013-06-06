#!/usr/bin/env php
<?php
/*******************************************************************************
 *
 *  Copyright (c) 2011, Ryan Cavis
 *  All rights reserved.
 *
 *  This file is part of the rframe project <http://code.google.com/p/rframe/>
 *
 *  Rframe is free software: redistribution and use with or without
 *  modification are permitted under the terms of the New/Modified
 *  (3-clause) BSD License.
 *
 *  Rframe is provided as-is, without ANY express or implied warranties.
 *  Implied warranties of merchantability or fitness are disclaimed.  See
 *  the New BSD License for details.  A copy should have been provided with
 *  rframe, and is also at <http://www.opensource.org/licenses/BSD-3-Clause/>
 *
 ******************************************************************************/

require_once 'includes.php';

/**
 * Tests for fetching API resources.
 *
 * @version 0.1
 * @author ryancavis
 */
$api_path = dirname(__FILE__).'/testapi01';
$api = new Rframe($api_path, 'TestAPI01');
plan(50);

// setup the test objects
$__TEST_OBJECTS = array(
    new FooRecord(12, 'purple1'),
    new FooRecord(34, 'purple2'),
    new FooRecord(56, 'purple3'),
);
$bar1 = new BarRecord('abc', 'purplegreen1');
$bar1->add_foo(new FooRecord('999', 'purplegreenblue1'));
$bar2 = new BarRecord('def', 'purplegreen2');
$__TEST_OBJECTS[0]->add_bar($bar1);
$__TEST_OBJECTS[0]->add_bar($bar2);


/**********************
 * 1) Basic tests
 */
// bad path
$rsp = $api->fetch('bad/path');
is( $rsp['code'], Rframe::BAD_PATH, 'bad path - code' );
is( $rsp['success'], false, 'bad path - success' );
like( $rsp['message'], '/invalid path/i', 'bad fetch path - message');

// no root
$rsp = $api->fetch('');
is( $rsp['code'], Rframe::BAD_PATH, 'no root - code' );
is( $rsp['success'], false, 'no root - success' );
like( $rsp['message'], '/invalid path/i', 'no root - message');

// bad path for fetch (no uuid)
$rsp = $api->fetch('purple/');
is( $rsp['code'], Rframe::BAD_PATHMETHOD, 'bad fetch path - code' );
is( $rsp['success'], false, 'bad fetch path - success' );
like( $rsp['message'], '/invalid path for fetch/i', 'bad fetch path - message');

// bad ident
$rsp = $api->fetch('purple/1234');
is( $rsp['code'], Rframe::BAD_IDENT, 'bad ident - code' );
is( $rsp['success'], false, 'bad ident - success' );
like( $rsp['message'], '/not found/i', 'bad ident - message');

// good ident
$rsp = $api->fetch('purple/12');
is( $rsp['code'], Rframe::OKAY, 'good ident - code' );
is( $rsp['success'], true, 'good ident - success' );

// extra slashes
$rsp = $api->fetch('/purple/12/');
is( $rsp['code'], Rframe::OKAY, 'extra slashes - code' );
is( $rsp['success'], true, 'extra slashes - success' );


/**********************
 * 2) Second level tests
 */
$rsp = $api->fetch('/purple/13/green/abc');
is( $rsp['code'], Rframe::BAD_IDENT, 'fetch green - bad purple - code' );
is( $rsp['success'], false, 'fetch green - bad purple - success' );
like( $rsp['message'], '/purple 13 not found/i', 'fetch green - bad purple - message');

$rsp = $api->fetch('/purpl/12/green/abc');
is( $rsp['code'], Rframe::BAD_PATH, 'fetch green - no purple - code' );
is( $rsp['success'], false, 'fetch green - no purple - success' );
like( $rsp['message'], '/invalid path/i', 'fetch green - no purple - message');

$rsp = $api->fetch('/purple/12/green');
is( $rsp['code'], Rframe::BAD_PATHMETHOD, 'fetch green - no id - code' );
is( $rsp['success'], false, 'fetch green - no id - success' );
like( $rsp['message'], '/invalid path for fetch/i', 'fetch green - no id - message');

$rsp = $api->fetch('/purple/12/green/bad');
is( $rsp['code'], Rframe::BAD_IDENT, 'fetch green - bad id - code' );
is( $rsp['success'], false, 'fetch green - bad id - success' );
like( $rsp['message'], '/green bad not found/i', 'fetch green - bad id - message');

$rsp = $api->fetch('/purple/12/green/abc');
is( $rsp['code'], Rframe::OKAY, 'fetch green - good id - code' );
is( $rsp['success'], true, 'fetch green - good id - success' );

$rsp = $api->fetch('/purple/34/green/abc');
is( $rsp['code'], Rframe::BAD_IDENT, 'fetch green - wrong purple - code' );
is( $rsp['success'], false, 'fetch green - wrong purple - success' );
like( $rsp['message'], '/green abc not found/i', 'fetch green - wrong purple - message');


/**********************
 * 3) Third level tests
 */
$rsp = $api->fetch('/purple/13/green/abc/blue/999');
is( $rsp['code'], Rframe::BAD_IDENT, 'fetch blue - bad purple - code' );
is( $rsp['success'], false, 'fetch blue - bad purple - success' );
like( $rsp['message'], '/purple 13 not found/i', 'fetch blue - bad purple - message');

$rsp = $api->fetch('/purple/12/green/555/blue/999');
is( $rsp['code'], Rframe::BAD_IDENT, 'fetch blue - bad green - code' );
is( $rsp['success'], false, 'fetch blue - bad green - success' );
like( $rsp['message'], '/green 555 not found/i', 'fetch blue - bad green - message');

$rsp = $api->fetch('/purple/green/abc/blue/999');
is( $rsp['code'], Rframe::BAD_PATH, 'fetch blue - bad path - code' );
is( $rsp['success'], false, 'fetch blue - bad path - success' );
like( $rsp['message'], '/invalid path/i', 'fetch blue - bad path - message');

$rsp = $api->fetch('purple/12/green/abc/blue/999');
is( $rsp['code'], Rframe::OKAY, 'fetch blue - good id - code' );
is( $rsp['success'], true, 'fetch blue - good id - success' );

$rsp = $api->fetch('purple/12/green/abc/blue/888');
is( $rsp['code'], Rframe::BAD_IDENT, 'fetch blue - bad id - code' );
is( $rsp['success'], false, 'fetch blue - bad id - success' );
like( $rsp['message'], '/blue 888 not found/i', 'fetch blue - bad id - message');

$rsp = $api->fetch('purple/12/green/def/blue/999');
is( $rsp['code'], Rframe::BAD_IDENT, 'fetch blue - wrong green - code' );
is( $rsp['success'], false, 'fetch blue - wrong green - success' );
like( $rsp['message'], '/blue 999 not found/i', 'fetch blue - wrong green - message');
