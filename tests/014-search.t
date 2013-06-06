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

plan(13);

// init browser
$browser = new AirHttpTest();
$browser->set_test_user();
$browser->set_content_type(AirHttpTest::$JSON); // set to json

ok( $resp = $browser->http_get('/search?q=test'),
    "GET basic search");

//diag_dump( $resp );

ok( $json = json_decode($resp), "response is valid JSON");
cmp_ok( $json->total, '>', 10, "more then ten results");

// html responses
$browser = new AirHttpTest();
$browser->set_user('testuser', array(''=>false));
$browser->set_content_type(AirHttpTest::$HTML); // set to json
$idx_types = array('sources', 'responses', 'inquiries', 'activities', 'projects');

foreach ($idx_types as $idx) {
    $uri = '/search/'.$idx.'?q=test';
    ok( $resp = $browser->http_get($uri), "GET $uri");
    //diag_dump( $resp );
    like( $resp, '/<html/', "$idx is html");
}
