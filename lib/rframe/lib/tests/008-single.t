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
 * Tests for one-to-one relationships in the framework
 *
 * @version 0.1
 * @author ryancavis
 */
$api_path = dirname(__FILE__).'/testapi03';
$api = new Rframe($api_path, 'TestAPI03');
plan(38);


// setup the test objects
$foo1 = new FooRecord(12, 'purple1');
$ham1 = new HamRecord('abc', 'purplered1');
$bar1 = new BarRecord('z', 'purpleredgreen1');
$foo1->set_ham($ham1);
$ham1->add_bar($bar1);

$foo2 = new FooRecord(34, 'purple2');
$__TEST_OBJECTS = array($foo1, $foo2);


/**********************
 * 1) Test fetch/query on routes
 */
$rsp = $api->query('purple');
is( $rsp['code'], Rframe::OKAY, 'query purple - code' );
$rsp = $api->fetch('purple');
is( $rsp['code'], Rframe::BAD_PATHMETHOD, 'fetch purple - code' );

$rsp = $api->query('purple/12');
is( $rsp['code'], Rframe::BAD_PATHMETHOD, 'query purple/12 - code' );
$rsp = $api->fetch('purple/12');
is( $rsp['code'], Rframe::OKAY, 'fetch purple/12 - code' );

$rsp = $api->query('purple/12/red');
is( $rsp['code'], Rframe::BAD_METHOD, 'query purple/12/red - code' );
$rsp = $api->fetch('purple/12/red');
is( $rsp['code'], Rframe::OKAY, 'fetch purple/12/red - code' );

$rsp = $api->query('purple/12/red/green');
is( $rsp['code'], Rframe::OKAY, 'query purple/12/red/green - code' );
$rsp = $api->fetch('purple/12/red/green');
is( $rsp['code'], Rframe::BAD_PATHMETHOD, 'fetch purple/12/red/green - code' );

$rsp = $api->query('purple/12/red/green/z');
is( $rsp['code'], Rframe::BAD_PATHMETHOD, 'query purple/12/red/green/z - code' );
$rsp = $api->fetch('purple/12/red/green/z');
is( $rsp['code'], Rframe::OKAY, 'fetch purple/12/red/green/z - code' );


/**********************
 * 2) Verify data and metadata
 */
$purple = $api->fetch('purple/12');
$red    = $api->fetch('purple/12/red');
$green  = $api->fetch('purple/12/red/green/z');

is( $purple['radix']['my_val'], $foo1->get_value(), 'purple value' );
is( $red['radix']['my_val'], $ham1->get_value(), 'red value' );
is( $green['radix']['my_val'], $bar1->get_value(), 'green value' );

is( $purple['api']['route'], 'purple', 'purple route' );
is( $red['api']['route'], 'purple/red', 'red route' );
is( $green['api']['route'], 'purple/red/green', 'green route' );

is( $purple['api']['children'], array('red'), 'purple children' );
is( $red['api']['children'], array('green'), 'red children' );
is( $green['api']['children'], array(), 'green children' );


/**********************
 * 3) Update
 */
$rsp = $api->update('purple/12/red', array('val' => 'blahblah'));
is( $rsp['code'], RFrame::OKAY, 'update OK' );
is( $rsp['radix']['my_val'], 'blahblah', 'update value' );
is( $ham1->get_value(), 'blahblah', 'update check record' );


/**********************
 * 4) Create/Delete
 */
// should fail, since already exists
$rsp = $api->create('purple/12/red', array('val' => 'testtest'));
is( $rsp['code'], RFrame::ONE_EXISTS, 'create - already exists' );
is( $foo1->get_ham()->get_value(), 'blahblah', 'create - value unchanged' );

// delete should work just fine
$rsp = $api->delete('purple/12/red');
is( $rsp['code'], Rframe::OKAY, 'delete - exists' );
is( $foo1->get_ham(), false, 'delete - no ham' );

// fetch fails when DNE
$rsp = $api->fetch('purple/12/red');
is( $rsp['code'], Rframe::ONE_DNE, 'fetch - DNE' );

// update fails when DNE
$rsp = $api->update('purple/12/red', array('val' => 'nothing'));
is( $rsp['code'], Rframe::ONE_DNE, 'update - DNE' );

// delete fails when DNE
$rsp = $api->delete('purple/12/red');
is( $rsp['code'], Rframe::ONE_DNE, 'delete - DNE' );

// now create works
$rsp = $api->create('purple/12/red', array('val' => 'testtest'));
is( $rsp['code'], RFrame::OKAY, 'create - DNE' );
is( $rsp['radix']['my_val'], 'testtest', 'create - response val' );
is( $foo1->get_ham()->get_value(), 'testtest', 'create - value changed' );


/**********************
 * 5) A bit of CRUD on the resource in back of the one-to-one
 */
$bars = $foo1->get_ham()->get_bars();
is( count($bars), 0, 'no bars' );

$rsp = $api->create('purple/12/red/green', array('val' => 'bananastand'));
is( $rsp['code'], Rframe::OKAY, 'create green - okay' );
$bars = $foo1->get_ham()->get_bars();
is( count($bars), 1, '1 bars' );
is( $bars[0]->get_value(), 'bananastand', 'create green - value' );
$id = $bars[0]->get_id();

$rsp = $api->update("purple/12/red/green/$id", array('val' => 'hamburger'));
is( $rsp['code'], Rframe::OKAY, 'update green - okay' );
is( $rsp['radix']['my_val'], 'hamburger', 'update green - value' );
