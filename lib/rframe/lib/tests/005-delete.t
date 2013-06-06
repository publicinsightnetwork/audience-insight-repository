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
 * Tests for querying API resources.
 *
 * @version 0.1
 * @author ryancavis
 */
$api_path = dirname(__FILE__).'/testapi01';
$api = new Rframe($api_path, 'TestAPI01');
plan(26);

// setup the test objects
$__TEST_OBJECTS = array(
    new FooRecord(12, 'purple1'),
    new FooRecord(34, 'purple2'),
    new FooRecord(56, 'purple3'),
    new FooRecord(78, 'purple4'),
);
$bar1 = new BarRecord('abc', 'purplegreen1');
$bar1->add_foo(new FooRecord('999', 'purplegreenblue1'));
$__TEST_OBJECTS[1]->add_bar($bar1);


/**********************
 * 1) Basic tests
 */
$rsp = $api->delete('purpl/12');
is( $rsp['code'], Rframe::BAD_PATH, 'bad path - code' );
is( $rsp['success'], false, 'bad path - success' );
like( $rsp['message'], '/invalid path/i', 'bad path - message');

// bad method
$rsp = $api->delete('purple/');
is( $rsp['code'], Rframe::BAD_PATHMETHOD, 'bad path method - code' );
is( $rsp['success'], false, 'bad path method - success' );
like( $rsp['message'], '/invalid path for delete/i', 'bad path method - message');

// dne
$rsp = $api->delete('purple/777');
is( $rsp['code'], Rframe::BAD_IDENT, 'dne - code' );
is( $rsp['success'], false, 'dne - success' );
like( $rsp['message'], '/purple 777 not found/i', 'dne - message');

// delete
is( count($__TEST_OBJECTS), 4, '4 test objects' );
$rsp = $api->delete('purple/12');
is( $rsp['code'], Rframe::OKAY, 'delete 12 - code' );
is( $rsp['success'], true, 'delete 12 - success' );
is( count($__TEST_OBJECTS), 3, '3 test objects' );

// re-delete
$rsp = $api->delete('purple/12');
is( $rsp['code'], Rframe::BAD_IDENT, 're-delete - code' );
is( $rsp['success'], false, 're-delete - success' );
like( $rsp['message'], '/purple 12 not found/i', 're-delete - message');


/**********************
 * 2) Allowed methods
 */
$bars = $__TEST_OBJECTS[0]->get_bars();
is( count($bars), 1, '1 bar objects' );
$foos = $bars[0]->get_foos();
is( count($foos), 1, '1 foo objects' );

// delete blue
$rsp = $api->delete('purple/34/green/abc/blue/999');
is( $rsp['code'], Rframe::BAD_METHOD, 'delete blue - code' );
is( $rsp['success'], false, 'delete blue - success' );

// delete green
$rsp = $api->delete('purple/34/green/abc/');
is( $rsp['code'], Rframe::OKAY, 'delete green - code' );
is( $rsp['success'], true, 'delete green - success' );
$bars = $__TEST_OBJECTS[0]->get_bars();
is( count($bars), 0, '0 bar objects' );

// re-delete green
$rsp = $api->delete('purple/34/green/abc/');
is( $rsp['code'], Rframe::BAD_IDENT, 'redelete green - code' );
is( $rsp['success'], false, 'redelete green - success' );
like( $rsp['message'], '/green abc not found/i', 're-delete green - message');
