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


/*
|---------------------------------------------------------------
| DEFINE APPLICATION CONSTANTS
|---------------------------------------------------------------
|
| EXT		   - The file extension.  Typically ".php"
| SELF		   - The name of THIS file (typically "index.php")
| FCPATH	   - The full server path to THIS file
| BASEPATH	   - The full server path to the "system" folder
| DOCPATH      - The full doctrine "lib" folder path
| APPPATH	   - The full server path to the "application" folder
| AIR2_DOCROOT - The full server path to the "public_html" folder
|
*/
define('EXT', '.php');
define('SELF', 'init.php');
define('FCPATH', str_replace(SELF, '', __FILE__));
define('BASEPATH', realpath(FCPATH.'../lib/codeigniter/system').'/');
define('DOCPATH', realpath(FCPATH.'../lib/doctrine/lib').'/');
define('APPPATH', realpath(FCPATH).'/');
define('AIR2_DOCROOT', realpath(FCPATH.'/../public_html/'));
define('AIR2_CODEROOT', realpath(FCPATH.'/../'));

// determine which profile to read
$my_profile = APPPATH.'../etc/my_profile';
if (file_exists($my_profile)) {
    define('AIR2_PROFILE', trim(file_get_contents($my_profile)));
}
else {
    define('AIR2_PROFILE', php_uname("n"));
}

// determine the version number
$my_version = APPPATH.'../etc/my_version';
if (file_exists($my_version)) {
    define('AIR2_VERSION', trim(file_get_contents($my_version)));
}
else {
    define('AIR2_VERSION', '2.x.y');
}

// parse profiles ini file
$profiles = parse_ini_file(realpath(APPPATH.'../etc/profiles.ini'), true);
if (!count($profiles)) {
    die("etc/profiles.ini failed to load");
}
if (!isset($profiles[AIR2_PROFILE])) {
    die("no profile defined in etc/profiles.ini for " . AIR2_PROFILE);
}
require_once APPPATH.'config/air2_constants.php';

// load authorization ini files
$actions = parse_ini_file(realpath(APPPATH.'config/actions.ini'));
$roles = parse_ini_file(realpath(APPPATH.'config/roles.ini'), true);
foreach ($actions as $name => $bitmask) {
    define($name, intval($bitmask));
}
foreach ($roles as $name => $def) {
    $code = $def['ar_code'];
    $authzs = array();
    $lines = preg_split('/\s+/', $def['authz']);
    foreach ($lines as $line) {
        $line = trim($line, ' \\');
        if ($line) $authzs[] = $line;
    }

    // calculate the role-bitmask
    $bitmask = 0;
    foreach ($authzs as $act) {
        if (!defined($act)) {
            throw new Exception("Unknown action '$act' in roles.ini!");
        }
        $bitmask = $bitmask | constant($act);
    }
    define("AIR2_AUTHZ_ROLE_$code", $bitmask);
}

// set up include path
$air2_include_paths = array(
    APPPATH.'libraries',
    APPPATH.'models',
    APPPATH.'../lib',
    APPPATH.'../lib/shared',
    APPPATH.'../lib/shared/passwordreset',
    APPPATH.'../lib/mover',
);
set_include_path(implode(':', $air2_include_paths));
require_once 'Carper.php';
require_once 'AIR2_Exception.php';
require_once 'AIR2_Utils.php';
