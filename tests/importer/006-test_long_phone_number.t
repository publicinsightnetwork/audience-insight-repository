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
require_once APPPATH.'/../tests/models/TestSrcPhoneNumber.php';
require_once 'phperl/callperl.php';

AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// setup
$s = new TestSrcPhoneNumber();
$s->save();

plan(2);

/**********************
 * 1) Long Phone Number
 */

$s->sph_primary_flag = false; //will be ignored
$s->sph_context = SrcPhoneNumber::$CONTEXT_HOME;
$s->sph_country = 'AAA';
$s->sph_number = '00 44 (0) 7796 292525';
$s->sph_ext = 'x123';

is('00 44 (0) 7796 292525', $s->sph_number, 'Test that extra characters exist before save.');

$s->save();

is('004407796292525', $s->sph_number, 'Test that extra characters are stripped out.');