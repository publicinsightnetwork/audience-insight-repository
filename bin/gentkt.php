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

require_once realpath(dirname(__FILE__).'/../app/init.php');
require_once 'AirUser.php';
require_once 'User.php';
require_once 'AIR2_DBManager.php';

AIR2_DBManager::init();

array_shift($argv);

$length = count($argv);
for ($i = 0; $i < $length; $i++) {
    $airUser = new AirUser(); // user_username => $username )->load;
    $username = $argv[$i];
    $user = Doctrine::getTable('User')->findOneBy('user_username', $username);
    $tkt = $airUser->get_tkt($user->user_username, $user->user_id);
    var_dump($tkt);
}
