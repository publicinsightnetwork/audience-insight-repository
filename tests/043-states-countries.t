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

plan(16);

// init
AIR2_DBManager::init();

ok( $states = State::get_all_codes(), "State::get_all_codes");
ok( is_array($states), "states is_array");
cmp_ok( count($states), '>=', 50, "fifty nifty states, at least" );
ok( in_array('CA', $states), "CA is a state");

ok( $state_hash = State::get_all(), "State::get_all");
ok( is_array($state_hash), "state_hash is_array");
is( count($states), count($state_hash), "just as many codes as states" );
is( $state_hash['CA'], 'California', "CA => California");

ok( $countries = Country::get_all_codes(), "Country::get_all_codes");
ok( is_array($countries), "countries is_array");
cmp_ok( count($countries), '>=', 100, "at least 100 countries" );
ok( in_array('CA', $countries), "CA is a country too");

ok( $countries_hash = Country::get_all(), "Country::get_all");
ok( is_array($countries_hash), "countries_hash is_array");
is( count($countries), count($countries_hash), "just as many codes as countries" );
is( $countries_hash['CA'], 'Canada', "CA => Canada");

