<?php  if ( !defined('BASEPATH')) exit('No direct script access allowed');
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

// default format for requests
$default_format = 'text/html';

// Map valid URL-appended formats to HTTP_ACCEPT mime types
$url_formats = array(
    'json' => 'application/json',
    'xml'  => 'application/xml',
    'html' => 'text/html',
    'htm'  => 'text/html',
    'text' => 'text/plain',
    'txt'  => 'text/plain',
    'csv'  => 'application/csv',
    'img'  => 'image/*',
    'phtml' => 'print/html',
    'rss'  => 'application/rss+xml',
);

// Map valid HTTP_ACCEPT mime types to output views
$format_views = array(
    'application/json' => 'json',
    'text/html'        => 'html',
    'text/plain'       => 'text',
    'application/xml'  => 'xml',
    'application/csv'  => 'csv',
    'print/html'       => 'phtml',
    'application/rss+xml' => 'rss',
    'image/*'          => null, //no output view
);

// just in case you want to output a different 'Content-type' header
// for a matched format
$alt_headers = array(
    'print/html' => 'text/html', //print should display normal html headers
);
