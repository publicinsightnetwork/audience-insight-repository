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
$browser = new AirHttpTest();
$browser->set_test_user();

plan(6);

/***********************************
 * test IE7's wacky content types
 */

// IE7 will give a long type string of junk content types, followed by the
// ambiguous */* --- we should return html here
$junk = 'image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/msword, '
    . 'application/vnd.ms-powerpoint, application/vnd.ms-excel, application/xaml+xml, '
    . 'application/vnd.ms-xpsdocument, application/x-ms-xbap, application/x-ms-application, '
    . 'application/x-shockwave-flash, application/x-silverlight';
$browser->set_content_type("$junk, */*");
$page = $browser->http_get('');
is($browser->resp_code(), 200, "ie7 nonsense is supported");
is($browser->resp_content_type(), 'text/html', 'ie7 nonsense returns html');

// if we request the same nonsense without the */*, we should get a 415
$browser->set_content_type($junk);
$page = $browser->http_get('');
is($browser->resp_code(), 415, "ie7 junk request not tolerated");
is($browser->resp_content_type(), 'text/plain', 'ie7 junk request returns text');

// on a refresh, IE7 will request */* instead of the what it requested before,
// because it can't even be consistently insane.
$browser->set_content_type('*/*');
$page = $browser->http_get('');
is($browser->resp_code(), 200, "ie7 refresh is supported");
is($browser->resp_content_type(), 'text/html', 'ie7 refresh returns html');


?>
