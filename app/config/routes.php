<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
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


/************************
 * Routes controlled by subclasses of AIR2_APIController
 */
$api_routes = array(
    'alert',
    'background',
    'bin',
    'csv',
    'import',
    'inquiry',
    'organization',
    'orgtree',
    'outcome',
    'outcomeexport',
    'preference',
    'project',
    'query',
    'savedsearch',
    'search',
    'source',
    'srcemail',
    'submission',
    'tag',
    'tank',
    'translation',
    'user',
);

$route['validator/([\w]+)'] = "validator/validate_record/$1";
$route['dashboard/([\w]+)'] = 'dashboard/get_org_stats/$1';
//$route['bin/([\w]+)'] = 'bin/index/bin/$1';
$route['password/([\w]+)'] = 'password/change_password_page/$1';

// alias search for "queries"
$route['search/queries'] = 'search/inquiries';

// querybuilder
$route['builder/([\w]+)'] = 'builder/index/$1';

// give the reader control of responses
$route['search/responses'] = 'reader';
$route['search/strict-responses'] = 'reader/strict';
$route['reader/strict-query/([\w]+)'] = 'reader/strict_query/$1';

// api namespace
$route['api/public/(:any)'] = 'public/$1';

// default
$route['default_controller'] = "home";
