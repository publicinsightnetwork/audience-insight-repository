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

require_once 'app/init.php';
require_once APPPATH.'/../tests/Test.php';
require_once APPPATH.'/../tests/models/TestSrcMailAddress.php';
require_once 'phperl/callperl.php';

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// setup
$s = new TestSrcMailAddress();
$s->save();

plan(5);

/**********************
 * 1) Short zip code
 */

$s->smadd_primary_flag = false; //will be ignored
$s->smadd_context = SrcMailAddress::$CONTEXT_HOME;
$s->smadd_zip = '1234';

is('1234', $s->smadd_zip, "Test that there is no leading zero before we save");

$s->save();

is('01234', $s->smadd_zip, "Test that the leading zero got added in.");

/**********************
 * 2) No zip code
 */

$s->smadd_primary_flag = false; //will be ignored
$s->smadd_context = SrcMailAddress::$CONTEXT_HOME;
$s->smadd_zip = '';

is($s->smadd_zip, '', "Test blank zip code before we save");

$s->save();

is($s->smadd_zip, '', "Test that the zip code is left alone");

// alpha
$s->smadd_zip = 'abc';
$s->save();
is($s->smadd_zip, 'abc', "alpha values are ignored");
