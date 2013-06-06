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
plan(32);

// setup the test objects
$__TEST_OBJECTS = array(
    new FooRecord(12, 'purple1'),
);
$bar1 = new BarRecord('abc', 'purplered1');
$bar2 = new BarRecord('def', 'purplered2');
$__TEST_OBJECTS[0]->add_bar($bar1);
$__TEST_OBJECTS[0]->add_bar($bar2);


/**********************
 * 1) Basic tests
 */
// normal fetch
$rsp = $api->fetch('purple/12');
is( $rsp['code'], Rframe::OKAY, 'normal - code' );
is( $rsp['success'], true, 'normal - success' );
$radix = $rsp['radix'];
ok( isset($radix['my_id']), 'normal - my_id' );
ok( isset($radix['my_val']), 'normal - my_val' );
ok( !isset($radix['red']), 'normal - no red' );

// include red
$rsp = $api->fetch('purple/12', array('with' => 'red'));
is( $rsp['code'], Rframe::OKAY, 'fetchwith - code' );
is( $rsp['success'], true, 'fetchwith - success' );
$radix = $rsp['radix'];
ok( isset($radix['my_id']), 'fetchwith - my_id' );
ok( isset($radix['my_val']), 'fetchwith - my_val' );
ok( isset($radix['red']), 'fetchwith - isset red' );

// validate reds
ok( is_array($radix['red']), 'fetchwith - red is array' );
is( count($radix['red']), 2, 'fetchwith - 2 reds' );
is( $radix['red'][0]['blah_val'], 'purplered1', 'fetchwith - val 1' );
is( $radix['red'][1]['blah_val'], 'purplered2', 'fetchwith - val 2' );
ok( isset($rsp['meta']['with']['red']), 'fetchwith - meta with' );


/**********************
 * 2) With filter
 */
// include red filter
$rsp = $api->fetch('purple/12', array('with' => array('red' => array('filter' => 'red1'))));
is( $rsp['code'], Rframe::OKAY, 'filter - code' );
is( $rsp['success'], true, 'filter - success' );
$radix = $rsp['radix'];
ok( isset($radix['my_id']), 'filter - my_id' );
ok( isset($radix['my_val']), 'filter - my_val' );
ok( isset($radix['red']), 'filter - isset red' );

// validate data
ok( is_array($radix['red']), 'filter - red is array' );
is( count($radix['red']), 1, 'filter - 1 red' );
is( $radix['red'][0]['blah_val'], 'purplered1', 'fetchwith - val 1' );
ok( isset($rsp['meta']['with']['red']), 'fetchwith - meta with' );


/**********************
 * 3) Bad 'with' (ignored for now... TODO: better idea?)
 */
$rsp = $api->fetch('purple/12', array('with' => 'nothing'));
is( $rsp['code'], Rframe::OKAY, 'bad - code' );
is( $rsp['success'], true, 'bad - success' );
$radix = $rsp['radix'];
ok( isset($radix['my_id']), 'bad - my_id' );
ok( isset($radix['my_val']), 'bad - my_val' );
ok( !isset($radix['red']), 'bad - no red' );
ok( !isset($radix['red']), 'bad - no nothing' );
ok( isset($rsp['meta']['with']), 'bad - has with' );
is( count($rsp['meta']['with']), 0, 'bad - empty with' );
