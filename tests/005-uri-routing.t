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

$uris = array(
    '/',
    '/test',
    '/home',
    '/test/html_render',
);

// Note that PROD environments will return 404's for any test URL
if (AIR2_ENVIRONMENT == 'prod') $uris = array('/', '/home');

plan((count($uris)*2) + 10);

/***********************************
 * test URI routing
 */

$browser = new AirHttpTest();
$browser->set_user('testuser', array());
$browser->set_content_type(AirHttpTest::$HTML);
$browser->browser->setMaximumRedirects(0);

foreach ($uris as $uri) {
    $page = $browser->http_head($uri);
    is($browser->resp_code(), 405, "HEAD $uri");
    if ($browser->resp_code() != 405) {
        diag( $page );
        diag_dump( $browser->browser->getHeaders() );
    }
    $page = $browser->http_get($uri);
    is($browser->resp_code(), 200, "GET $uri");
    if ($browser->resp_code() != 200) {
        diag( $page );
    }
}

// static files
ok( $css = $browser->http_get('/css/air2.css'),
    "GET /css/air2.css");
is( $browser->resp_code(), 200, "GET css ok");

// test content
ok( $html = $browser->http_get('/test/html_render'),
    "get html_render");

if (AIR2_ENVIRONMENT == 'prod') {
    pass( 'prod get html_render' );
    pass( 'prod get html_render' );
    pass( 'prod get html_render' );
    pass( 'prod get html_render' );
}
else {
    like( $html, '/this is the body/', "html body");
    like( $html, '/\/js\/test.js/', "js file");
    like( $html, '/\/css\/test.css/', "css file");
    like( $html, '/alert\("test ok"\)/', "misc javascript");
}

// login test
if (AIR2_PIN_SSO_TRUST) {
    $browser->http_get('/login');   // should redirect
    is( $browser->resp_code(), 302, "SSO /login redirects");
}
else {
    $browser->http_get('/login');   // should redirect
    is( $browser->resp_code(), 200, "local /login presents HTML");
}

// logout test
$browser->http_get('/logout'); // should redirect
is( $browser->resp_code(), 302, "/logout redirects");
is( $browser->browser->getCurrentCookieValue(AIR2_AUTH_TKT_NAME), 'deleted',
    "auth cookie deleted");
