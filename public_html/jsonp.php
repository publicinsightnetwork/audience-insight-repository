<?php
/**************************************************************************
 *
 *   Copyright 2013 American Public Media Group
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

// jsonp wrapper for .json files
// note this is slower than letting apache serve the .json directly
// but allows for cross domain requests

$valid_methods = array('GET');
$request_method = $_SERVER['REQUEST_METHOD'];
if (!in_array($request_method, $valid_methods)) {
    header('X-PIN: invalid request: ' . $request_method, false, 405);
    header('Allow: ' . implode(' ', $valid_methods));
    exit(0);
}
if ($request_method == 'OPTIONS') {
    // cross-domain requirement for embedded queries
    if (isset($_SERVER['HTTP_ORIGIN'])) {
        header('Access-Control-Allow-Origin: ' . $_SERVER['HTTP_ORIGIN']);
    }
    header('Access-Control-Allow-Headers: Content-Type, Content-Range, Content-Disposition, Content-Description, X-Requested-With');
    exit(0);
}

if (!isset($_GET['f'])) {
    header('X-PIN: missing f param', false, 400);
    print "Missing f param\n";
    exit(0);
}
if (!isset($_GET['callback'])) {
    header('X-PIN: missing callback param', false, 400);
    print "Missing callback param\n";
    exit(0);
}

$file       = $_GET['f'];
$callback   = $_GET['callback'];

if (preg_match('/\.\./', $file) || !preg_match('/\.json$/', $file)) {
    header('X-PIN: illegal f param', false, 400);
    print "illegal f param\n";
    exit(0);
}

// slurp in $file relative to this script
// and echo it with jsonp wrapper
$this_dir = dirname(__FILE__);
//echo "file=$file dir=$this_dir";
$file_path = realpath("$this_dir/$file");
//echo "file_path=$file_path  callback=$callback";
if (file_exists($file_path)) {
    $buf = file_get_contents($file_path);
    header('Content-Type: application/javascript');
    printf("%s(%s)", $callback, $buf);
}
else {
    header("X-PIN: No such resource: $file", false, 404);
    echo "No such resource: $file";
}
