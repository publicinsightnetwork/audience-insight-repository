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

ini_set('memory_limit', '512M');
require_once 'Test.php';
require_once 'app/init.php';

plan(3);

$uuids = array();

for ($i=0; $i<1000000; $i++) {
    $uuid = air2_generate_uuid();
    //diag($uuid);
    if (isset($uuids[$uuid])) {
        die("uuid $uuid already set at $i   ");
    }
    if (strlen($uuid) != 12) {
        die("strlen $uuid != 12");
    }
    $uuids[$uuid] = 1;
}

pass("all unique at 1m iterations");

is(strlen(air2_generate_uuid(64)), 64, "got 64 char uuid");
is(strlen(air2_generate_uuid(128)), 128, "got 128 char uuid");
//diag( air2_generate_uuid(128) );

