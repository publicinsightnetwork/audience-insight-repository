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
plan(33);

// setup the test objects
$__TEST_OBJECTS = array(
    new FooRecord(12, 'purple1'),
    new FooRecord(34, 'purple2'),
    new FooRecord(56, 'purple3'),
    new FooRecord(78, 'purple4'),
);
$bar1 = new BarRecord('abc', 'purplegreen1');
$bar1->add_foo(new FooRecord('999', 'purplegreenblue1'));
$__TEST_OBJECTS[0]->add_bar($bar1);


/**********************
 * 1) Basic tests
 */
$rsp = $api->update('purpl/12', array());
is( $rsp['code'], Rframe::BAD_PATH, 'bad path - code' );
is( $rsp['success'], false, 'bad path - success' );
like( $rsp['message'], '/invalid path/i', 'bad path - message');

// bad method
$rsp = $api->update('purple/', array('bird' => 'hello'));
is( $rsp['code'], Rframe::BAD_PATHMETHOD, 'bad path method - code' );
is( $rsp['success'], false, 'bad path method - success' );
like( $rsp['message'], '/invalid path for update/i', 'bad path method - message');

// bad data
$rsp = $api->update('purple/12', array('foo' => 'bar'));
is( $rsp['code'], Rframe::BAD_DATA, 'bad data - code' );
is( $rsp['success'], false, 'bad data - success' );
like( $rsp['message'], '/disallowed.+foo/i', 'bad data - message');

// no data
$rsp = $api->update('purple/12', array());
is( $rsp['code'], Rframe::OKAY, 'no data - code' );
is( $rsp['success'], true, 'no data - success' );
is( $rsp['radix']['my_val'], 'purple1', 'no data - radix unchanged' );

// too much data
$rsp = $api->update('purple/12', array('bird' => 'hello', 'foo' => 'bar'));
is( $rsp['code'], Rframe::BAD_DATA, 'too much data - code' );
is( $rsp['success'], false, 'too much data - success' );
like( $rsp['message'], '/disallowed.+foo/i', 'too much data - message');

// unset data
$rsp = $api->update('purple/12', array('bird' => null));
is( $rsp['code'], Rframe::OKAY, 'unset data 1 - code' );
is( $rsp['success'], true, 'unset data 1 - success' );
is( $rsp['radix']['my_val'], null, 'unset data 1 - null' );

// wrong data
$rsp = $api->update('purple/12', array('bird' => '8'));
is( $rsp['code'], Rframe::BAD_DATA, 'wrong data 2 - code' );
is( $rsp['success'], false, 'wrong data 2 - success' );
like( $rsp['message'], '/bird too small/i', 'wrong data 2 - message');

// good data
$rsp = $api->update('purple/12', array('bird' => 'blah'));
is( $rsp['code'], Rframe::OKAY, 'good - code' );
is( $rsp['success'], true, 'good - success' );
is( $rsp['radix']['my_val'], 'blah', 'good - my_val' );


/**********************
 * 2) Allowed methods
 */
// green update
$rsp = $api->update('purple/12/green/abc', array());
is( $rsp['code'], Rframe::BAD_METHOD, 'green update  - code' );
is( $rsp['success'], false, 'green update - success' );
like( $rsp['message'], '/update not allowed/i', 'green update - message');

// blue update
$rsp = $api->update('purple/12/green/abc/blue/999', array('tree' => 'garage'));
is( $rsp['code'], Rframe::OKAY, 'blue update  - code' );
is( $rsp['success'], true, 'blue update - success' );
is( $rsp['radix']['a_val'], 'garage', 'good - a_val' );

// dne update
$rsp = $api->update('purple/12/green/999/blue/999', array('tree' => 'garage'));
is( $rsp['code'], Rframe::BAD_IDENT, 'dne update  - code' );
is( $rsp['success'], false, 'dne update - success' );
like( $rsp['message'], '/green 999/i', 'dne update - message');
