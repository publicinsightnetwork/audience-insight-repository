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

// display legal notice for locale and specific query (copyright holder(s))
require_once '../app/init.php';
require_once 'Encoding.php';

$valid_methods = array('GET','OPTIONS');
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

if (!isset($_GET['query'])) {
    header('X-PIN: missing query param', false, 400);
    print "Missing query param\n";
    exit(0);
}
if (!isset($_GET['locale'])) {
    header('X-PIN: missing locale param', false, 400);
    print "Missing locale param\n";
    exit(0);
}

$query_uuid = $_GET['query'];
$locale     = $_GET['locale'];
$callback   = $_GET['callback'];

//echo "uuid=$query_uuid locale=$locale";

$query_file_path = realpath(AIR2_DOCROOT . "/querys/$query_uuid.json");
if (!file_exists($query_file_path)) {
    header('X-PIN: invalid query uuid: ' . $query_uuid, false, 404);
    print "No such query: $query_uuid";
    exit(0);
}
$legal_file_path = realpath(AIR2_DOCROOT . "/legal-${locale}.html");
if (!file_exists($legal_file_path)) {
    header('X-PIN: invalid locale: ' . $locale, false, 404);
    print "No such locale: $locale";
    exit(0);
}

$query = json_decode(file_get_contents($query_file_path));
$legal_buf = file_get_contents($legal_file_path);

$copyright_holders = array();
$num_orgs = count($query->orgs);
foreach ($query->orgs as $org) {
    $org_name = $org->display_name;
    if ($org_name == 'Global PIN Access') {
        if ($num_orgs > 1) {
            continue; // skip global completely if it is one of multiple orgs
        }
        $org_name = 'American Public Media';
    }
    $org_url = $org->site;
    if (!$org_url) {
        $org_url = 'http://www.publicinsightnetwork.org/source/en/newsroom/'.$org->name;
    }
    $copyright_holders[] = sprintf("<a href='%s'>%s</a>", $org_url, $org_name);
}

$year = date('Y');
$legal_buf = preg_replace('/<!-- YEAR -->/', $year, $legal_buf);
$legal_buf = preg_replace(
    '/<!-- COPYRIGHT_HOLDER -->/',
    implode(', ', $copyright_holders),
    $legal_buf
);

if (!$callback) { ?>
<html>
 <head>
  <link rel="stylesheet" href="css/pinform.css"/>
  <style>
    body {
        font: 15px Helvetica, Helvetica Neue, Arial, 'sans serif';
    }
  </style>
 </head>
 <body>
 <?php echo $legal_buf ?>
 </body>
</html>
<?php
}
else {
    $legal_json = Encoding::json_encode_utf8(array('legal'=>$legal_buf));
    header("Content-Type: application/json");
    echo "${callback}(";
    echo $legal_json;
    echo ")";
}
