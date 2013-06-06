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
plan(67);


/**********************
 * 0) Setup
 */
$rsp = $api->create('purple', array('val' => 'aaaaa'));
is( $rsp['code'], Rframe::OKAY, 'create1' );
$rsp = $api->create('purple', array('val' => 'ggggg'));
is( $rsp['code'], Rframe::OKAY, 'create2' );
$rsp = $api->create('purple', array('val' => 'ccccc'));
is( $rsp['code'], Rframe::OKAY, 'create3' );
$rsp = $api->create('purple', array('val' => 'zzzzz'));
is( $rsp['code'], Rframe::OKAY, 'create4' );
$rsp = $api->create('purple', array('val' => 'aaaaa'));
is( $rsp['code'], Rframe::OKAY, 'create5' );
$rsp = $api->create('purple', array('val' => 'aabaa'));
is( $rsp['code'], Rframe::OKAY, 'create6' );

/**********************
 * 1) Paging meta
 */
$allowed = $rsp['api']['methods']['query'];
$sorts = $rsp['api']['sorts'];
ok(in_array('lim', $allowed), 'meta - query limit');
ok(in_array('off', $allowed), 'meta - query offset');

/**********************
 * 2) Limit only
 */
$rsp = $api->query('purple');
is( $rsp['code'], Rframe::OKAY, 'default - code' );
is( count($rsp['radix']), 6, 'default - count' );
is( $rsp['meta']['total'], 6, 'default - total' );
is( $rsp['meta']['limit'], 0, 'default - meta limit' );
is( $rsp['meta']['offset'], 0, 'default - meta offset' );

$rsp = $api->query('purple', array('limit' => 5));
is( $rsp['code'], Rframe::BAD_DATA, 'limit - code' );
like( $rsp['message'], '/disallowed/i', 'limit - msg' );

$rsp = $api->query('purple', array('lim' => -1));
is( $rsp['code'], Rframe::BAD_DATA, 'lim bad - code' );
like( $rsp['message'], '/bad limit/i', 'lim bad - msg' );

$rsp = $api->query('purple', array('lim' => '5'));
is( $rsp['code'], Rframe::OKAY, 'limit 5 - code' );
is( count($rsp['radix']), 5, 'limit 5 - count' );
is( $rsp['meta']['total'], 6, 'limit 5 - total' );
is( $rsp['radix'][0]['val'], 'aaaaa', 'limit 5 - 1st' );
is( $rsp['meta']['limit'], 5, 'limit 5 - meta limit' );
is( $rsp['meta']['offset'], 0, 'limit 5 - meta offset' );

$rsp = $api->query('purple', array('lim' => 8));
is( $rsp['code'], Rframe::OKAY, 'limit 8 - code' );
is( count($rsp['radix']), 6, 'limit 8 - count' );
is( $rsp['meta']['total'], 6, 'limit 8 - total' );
is( $rsp['radix'][0]['val'], 'aaaaa', 'limit 8 - 1st' );

$rsp = $api->query('purple', array('lim' => 0));
is( $rsp['code'], Rframe::OKAY, 'limit 0 - code' );
is( count($rsp['radix']), 6, 'limit 0 - count' );
is( $rsp['meta']['total'], 6, 'limit 0 - total' );
is( $rsp['radix'][0]['val'], 'aaaaa', 'limit 0 - 1st' );
is( $rsp['meta']['limit'], 0, 'limit 0 - meta limit' );
is( $rsp['meta']['offset'], 0, 'limit 0 - meta offset' );

/**********************
 * 2) Offset only
 */
$rsp = $api->query('purple', array('offset' => 2));
is( $rsp['code'], Rframe::BAD_DATA, 'offset - code' );
like( $rsp['message'], '/disallowed/i', 'offset - msg' );

$rsp = $api->query('purple', array('off' => -1));
is( $rsp['code'], Rframe::BAD_DATA, 'off bad - code' );
like( $rsp['message'], '/bad offset/i', 'off bad - msg' );

$rsp = $api->query('purple', array('off' => '2'));
is( $rsp['code'], Rframe::OKAY, 'offset 2 - code' );
is( count($rsp['radix']), 4, 'offset 2 - count' );
is( $rsp['meta']['total'], 6, 'offset 2 - total' );
is( $rsp['radix'][0]['val'], 'ccccc', 'offset 2 - 1st' );
is( $rsp['meta']['limit'], 0, 'offset 2 - meta limit' );
is( $rsp['meta']['offset'], 2, 'offset 2 - meta offset' );

$rsp = $api->query('purple', array('off' => 8));
is( $rsp['code'], Rframe::OKAY, 'offset 8 - code' );
is( count($rsp['radix']), 0, 'offset 8 - count' );
is( $rsp['meta']['total'], 6, 'offset 8 - total' );

/**********************
 * 3) Limit + Offset
 */
$rsp = $api->query('purple', array('lim' => 2, 'off' => '3'));
is( $rsp['code'], Rframe::OKAY, 'lim2 off3 - code' );
is( count($rsp['radix']), 2, 'lim2 off3 - count' );
is( $rsp['meta']['total'], 6, 'lim2 off3 - total' );
is( $rsp['radix'][0]['val'], 'zzzzz', 'lim2 off3 - 1st' );
is( $rsp['radix'][1]['val'], 'aaaaa', 'lim2 off3 - 2nd' );
is( $rsp['meta']['limit'], 2, 'lim2 off3 - meta limit' );
is( $rsp['meta']['offset'], 3, 'lim2 off3 - meta offset' );

/**********************
 * 4) Limit + Offset + sort
 */
$rsp = $api->query('purple', array('lim' => 2, 'off' => '3', 'sortme' => 'val asc'));
is( $rsp['code'], Rframe::OKAY, 'lim-off-sort - code' );
is( count($rsp['radix']), 2, 'lim-off-sort - count' );
is( $rsp['meta']['total'], 6, 'lim-off-sort - total' );
is( $rsp['radix'][0]['val'], 'ccccc', 'lim-off-sort - 1st' );
is( $rsp['radix'][1]['val'], 'ggggg', 'lim-off-sort - 2nd' );
is( $rsp['meta']['limit'], 2, 'lim-off-sort - meta limit' );
is( $rsp['meta']['offset'], 3, 'lim-off-sort - meta offset' );

/**********************
 * 4) Limit + Offset + sort + filter
 */
$rsp = $api->query('purple', array(
    'lim' => 3,
    'off' => 1,
    'sortme' => 'val asc',
    'valstarts' => 'a',
));
is( $rsp['code'], Rframe::OKAY, 'lim-off-sort-filter - code' );
is( count($rsp['radix']), 2, 'lim-off-sort-filter - count' );
is( $rsp['meta']['total'], 3, 'lim-off-sort-filter - total' );
is( $rsp['radix'][0]['val'], 'aaaaa', 'lim-off-sort-filter - 1st' );
is( $rsp['radix'][1]['val'], 'aabaa', 'lim-off-sort-filter - 2nd' );
is( $rsp['meta']['limit'], 3, 'lim-off-sort-filter - meta limit' );
is( $rsp['meta']['offset'], 1, 'lim-off-sort-filter - meta offset' );
