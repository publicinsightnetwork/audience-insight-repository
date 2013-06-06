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
 * Tests for sorting a query on API resources
 *
 * @version 0.1
 * @author ryancavis
 */
$api_path = dirname(__FILE__).'/testapi02';
$api = new Rframe($api_path, 'TestAPI02');
plan(43);


/**********************
 * 0) Setup
 */
$rsp = $api->create('purple', array('val' => 'aabaa'));
is( $rsp['code'], Rframe::OKAY, 'create1' );
$rsp = $api->create('purple', array('val' => 'aaaaa'));
is( $rsp['code'], Rframe::OKAY, 'create2' );
$rsp = $api->create('purple', array('val' => 'ccccc'));
is( $rsp['code'], Rframe::OKAY, 'create3' );
$rsp = $api->create('purple', array('val' => 'zzzzz'));
is( $rsp['code'], Rframe::OKAY, 'create4' );
$rsp = $api->create('purple', array('val' => 'aaaaa'));
is( $rsp['code'], Rframe::OKAY, 'create5' );
$rsp = $api->create('purple', array('val' => 'ggggg'));
is( $rsp['code'], Rframe::OKAY, 'create6' );

/**********************
 * 1) Sort meta
 */
$allowed = $rsp['api']['methods']['query'];
$sorts = $rsp['api']['sorts'];
ok(in_array('sortme', $allowed), 'meta - query sort');
ok(in_array('id', $sorts), 'meta - sorts id');
ok(in_array('val', $sorts), 'meta - sorts val');

/**********************
 * 2) Sort by ID
 */
$rsp = $api->query('purple');
is( $rsp['code'], Rframe::OKAY, 'default - code' );
is( count($rsp['radix']), 6, 'default - count' );
is( $rsp['meta']['total'], 6, 'default - total' );

$rsp = $api->query('purple', array('sort' => 'id'));
is( $rsp['code'], Rframe::BAD_DATA, 'sort - code' );
like( $rsp['message'], '/disallowed/i', 'sort - msg' );

$rsp = $api->query('purple', array('sortme' => 'aid'));
is( $rsp['code'], Rframe::BAD_DATA, 'sortme bad - code' );
like( $rsp['message'], '/bad sort field/i', 'sortme bad - msg' );

$rsp = $api->query('purple', array('sortme' => 'id'));
is( $rsp['code'], Rframe::OKAY, 'id-default - code' );
$sort_id_default = $rsp['radix'];

$rsp = $api->query('purple', array('sortme' => 'id asc'));
is( $rsp['code'], Rframe::OKAY, 'id-asc - code' );
$sort_id_asc = $rsp['radix'];

$rsp = $api->query('purple', array('sortme' => 'id desc'));
is( $rsp['code'], Rframe::OKAY, 'id-desc - code' );
$sort_id_desc = $rsp['radix'];

is_deeply( $sort_id_default, $sort_id_asc, 'asc is default' );
isnt( $sort_id_desc, $sort_id_asc, 'desc not asc' );
is( $sort_id_asc[0], $sort_id_desc[5], 'asc is reverse desc' );

/**********************
 * 2) Sort by VALUE
 */
$rsp = $api->query('purple', array('sortme' => 'val'));
is( $rsp['code'], Rframe::OKAY, 'val-default - code' );
$sort_val_default = $rsp['radix'];

$rsp = $api->query('purple', array('sortme' => 'val asc'));
is( $rsp['code'], Rframe::OKAY, 'val-asc - code' );
$sort_val_asc = $rsp['radix'];

$rsp = $api->query('purple', array('sortme' => 'val desc'));
is( $rsp['code'], Rframe::OKAY, 'val-desc - code' );
$sort_val_desc = $rsp['radix'];

is_deeply( $sort_val_default, $sort_val_asc, 'asc is default' );
isnt( $sort_val_desc, $sort_val_asc, 'desc not asc' );

is( $sort_val_desc[0]['val'], 'zzzzz', 'val-desc - 1' );
is( $sort_val_desc[1]['val'], 'ggggg', 'val-desc - 2' );
is( $sort_val_desc[2]['val'], 'ccccc', 'val-desc - 3' );
is( $sort_val_desc[3]['val'], 'aabaa', 'val-desc - 4' );
is( $sort_val_desc[4]['val'], 'aaaaa', 'val-desc - 5' );
is( $sort_val_desc[5]['val'], 'aaaaa', 'val-desc - 6' );

/**********************
 * 3) More meta
 */
$meta = $rsp['meta'];
is( $meta['sortstr'], 'val desc', 'meta sortstr' );
is( count($meta['sort']), 1, 'meta sort count' );
is( $meta['sort'][0][0], 'val', 'meta sort field' );
is( $meta['sort'][0][1], 'desc', 'meta sort direction' );

/**********************
 * 4) Defaults
 */
$rsp = $api->query('purple');
is( $rsp['code'], Rframe::OKAY, 'none-default - code' );
$sort_default = $rsp['radix'];
is( $sort_default[0]['val'], 'aabaa', 'val-default' );

TestAPI02_Purple::$DEFAULT_SORT = 'val asc';
$rsp = $api->query('purple');
is( $rsp['code'], Rframe::OKAY, 'none-default2 - code' );
$sort_default = $rsp['radix'];
is( $sort_default[0]['val'], 'aaaaa', 'val-default2' );

TestAPI02_Purple::$DEFAULT_SORT = 'val desc';
$rsp = $api->query('purple');
is( $rsp['code'], Rframe::OKAY, 'none-default3 - code' );
$sort_default = $rsp['radix'];
is( $sort_default[0]['val'], 'zzzzz', 'val-default3' );
