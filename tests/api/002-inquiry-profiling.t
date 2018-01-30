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
require_once 'rframe/AIRAPI.php';
$tdir = APPPATH.'../tests';
require_once "$tdir/Test.php";
require_once "$tdir/models/TestCleanup.php";
require_once "$tdir/models/TestUser.php";
require_once 'Stopwatch.php';

/**********************
 * Init
 */
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();
$u = new TestUser();
$u->save();
$api = new AIRAPI($u);

//plan(2);

// profile inquiry query, as per home page controller
$args = array('limit' => 6, 'sort' => 'inq_cre_dtim desc');
$watch = new Stopwatch();
diag( $watch->click("start inqs query") );
$inqs = $api->query('inquiry', $args);
diag( $watch->click("finish inqs query") );

// now again, using a user in the global org
$global_org = Doctrine::getTable('Organization')->findOneBy('org_id', Organization::$GLOBALPIN_ORG_ID);
$global_org_user = $global_org->UserOrg[0]->User;
diag( "global org user==" . $global_org_user->user_username );
diag( $watch->click("start inqs query") );
$api = new AIRAPI($global_org_user);
$inqs = $api->query('inquiry', $args);
diag( $watch->click("finish inqs query") );
