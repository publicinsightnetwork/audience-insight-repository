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
plan(45);

// setup the test objects
$__TEST_OBJECTS = array(
    new FooRecord(12, 'purple1'),
);
$bar1 = new BarRecord('abc', 'purplegreen1');
$bar1->add_foo(new FooRecord('999', 'purplegreenblue1'));
$__TEST_OBJECTS[0]->add_bar($bar1);


/**********************
 * 1) Basic tests
 */
$rsp = $api->query('purple');
is( $rsp['code'], Rframe::OKAY, 'init count - code' );
is( count($rsp['radix']), 1, 'init count - 1' );

// bad path
$rsp = $api->create('purpl/12', array());
is( $rsp['code'], Rframe::BAD_PATH, 'bad path - code' );
is( $rsp['success'], false, 'bad path - success' );
like( $rsp['message'], '/invalid path/i', 'bad path - message');

// bad method
$rsp = $api->create('purple/12', array('foo' => 'bar'));
is( $rsp['code'], Rframe::BAD_PATHMETHOD, 'bad path method - code' );
is( $rsp['success'], false, 'bad path method - success' );
like( $rsp['message'], '/invalid path/i', 'bad path method - message');

// bad data
$rsp = $api->create('purple', array('foo' => 'bar'));
is( $rsp['code'], Rframe::BAD_DATA, 'bad data - code' );
is( $rsp['success'], false, 'bad data - success' );
like( $rsp['message'], '/disallowed.+foo/i', 'bad data - message');

// no data
$rsp = $api->create('purple', array());
is( $rsp['code'], Rframe::BAD_DATA, 'no data - code' );
is( $rsp['success'], false, 'no data - success' );
like( $rsp['message'], '/hat required/i', 'no data - message');

// too much data
$rsp = $api->create('purple', array('hat' => 'myhat', 'foo' => 'bar'));
is( $rsp['code'], Rframe::BAD_DATA, 'too much data - code' );
is( $rsp['success'], false, 'too much data - success' );
like( $rsp['message'], '/disallowed.+foo/i', 'too much data - message');

// wrong data
$rsp = $api->create('purple', array('hat' => null));
is( $rsp['code'], Rframe::BAD_DATA, 'wrong data 1 - code' );
is( $rsp['success'], false, 'wrong data 1 - success' );
like( $rsp['message'], '/hat required/i', 'wrong data 1 - message');

$rsp = $api->create('purple', array('hat' => '8'));
is( $rsp['code'], Rframe::BAD_DATA, 'wrong data 2 - code' );
is( $rsp['success'], false, 'wrong data 2 - success' );
like( $rsp['message'], '/hat too small/i', 'wrong data 2 - message');

/**********************
 * 2) Succeed in creating
 */
$rsp = $api->create('purple', array('hat' => 'myhat'));
is( $rsp['code'], Rframe::OKAY, 'good - code' );
is( $rsp['success'], true, 'good - success' );
ok( isset($rsp['radix']), 'good - radix' );
is( $rsp['radix']['my_val'], 'myhat', 'good - value' );
$id = $rsp['radix']['my_id'];
is( $rsp['path'], "purple/$id", 'good - path' );

$rsp2 = $api->query('purple');
is( $rsp2['code'], Rframe::OKAY, 'new count - code' );
is( count($rsp2['radix']), 2, 'new count - 2' );

$rsp3 = $api->fetch("purple/$id");
is( $rsp3['code'], Rframe::OKAY, 'refetch - code' );
is( $rsp3['path'], $rsp['path'], 'refresh - same path' );

/**********************
 * 3) Allowed methods
 */
$rsp = $api->create("purple/$id/green", array('apple' => '1234'));
is( $rsp['code'], Rframe::OKAY, 'green allowed - code' );
is( $rsp['success'], true, 'green allowed - success' );
ok( isset($rsp['radix']), 'green allowed - radix' );
is( $rsp['radix']['blah_val'], '1234', 'green allowed - value' );
$gid = $rsp['radix']['blah_id'];
is( $rsp['path'], "purple/$id/green/$gid", 'green allowed - path' );

$rsp2 = $api->fetch("purple/$id/green/$gid");
is( $rsp2['code'], Rframe::OKAY, 'refetch - code' );
is( $rsp2['path'], $rsp['path'], 'refresh - same path' );

// create blue
$rsp = $api->create("purple/$id/green/$gid/blue", array());
is( $rsp['code'], Rframe::BAD_METHOD, 'bad method - code' );
is( $rsp['success'], false, 'bad method - success' );
like( $rsp['message'], '/create not allowed/i', 'bad method - message');

// DNE
$rsp = $api->create("purple/$id/green/999/blue", array());
is( $rsp['code'], Rframe::BAD_IDENT, 'dne - code' );
is( $rsp['success'], false, 'dne - success' );
like( $rsp['message'], '/green 999 not found/i', 'dne - message');
