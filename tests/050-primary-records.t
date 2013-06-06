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
require_once 'AirTestUtils.php';
require_once 'models/TestOrganization.php';
require_once 'models/TestSource.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// helper function to update upd_dtim
function change_upd_dtim($rec, $timestr) {
    global $conn;
    $dtim = air2_date(strtotime($timestr));
    $tbl = $rec->getTable()->getTableName();

    // find columns
    $idcol = false;
    $dtimcol = false;
    $data = $rec->toArray();
    foreach ($data as $key => $val) {
        if (preg_match('/^[a-z]+_id$/', $key)) $idcol = $key;
        if (preg_match('/_upd_dtim$/', $key)) $dtimcol = $key;
    }
    $id = $rec[$idcol];
    $conn->exec("update $tbl set $dtimcol = '$dtim' where $idcol = $id");
}

// test data
$src = new TestSource();
$src->save();
$uuid = $src->src_uuid;

plan(33);

/**********************
 * create unprimary
 */
$src->SrcEmail[0]->sem_primary_flag = false;
$src->SrcEmail[0]->sem_email = "test$uuid@test.com";
$src->SrcPhoneNumber[0]->sph_primary_flag = false;
$src->SrcPhoneNumber[0]->sph_number = '5555555555';
$src->SrcMailAddress[0]->smadd_primary_flag = false;
$src->SrcMailAddress[0]->smadd_city = 'Denver';
$src->save();

$src->refresh(true);
is( $src->SrcEmail[0]->sem_primary_flag, true, 'unprimary - email' );
is( $src->SrcPhoneNumber[0]->sph_primary_flag, true, 'unprimary - phone' );
is( $src->SrcMailAddress[0]->smadd_primary_flag, true, 'unprimary - mail' );

/**********************
 * create 2nd unprimary
 */
$src->SrcEmail[1]->sem_primary_flag = false;
$src->SrcEmail[1]->sem_email = "2test$uuid@test.com";
$src->SrcPhoneNumber[1]->sph_primary_flag = false;
$src->SrcPhoneNumber[1]->sph_number = '5555555555';
$src->SrcMailAddress[1]->smadd_primary_flag = false;
$src->SrcMailAddress[1]->smadd_city = 'Denver';
$src->save();

$src->refresh(true);
is( $src->SrcEmail[0]->sem_primary_flag, true, 'unprimary 2 - email 1' );
is( $src->SrcEmail[1]->sem_primary_flag, false, 'unprimary 2 - email 2' );
is( $src->SrcPhoneNumber[0]->sph_primary_flag, true, 'unprimary 2 - phone 1' );
is( $src->SrcPhoneNumber[1]->sph_primary_flag, false, 'unprimary 2 - phone 2' );
is( $src->SrcMailAddress[0]->smadd_primary_flag, true, 'unprimary 2 - mail 1' );
is( $src->SrcMailAddress[1]->smadd_primary_flag, false, 'unprimary 2 - mail 2' );

/**********************
 * new primary
 */
$src->SrcEmail[2]->sem_primary_flag = true;
$src->SrcEmail[2]->sem_email = "3test$uuid@test.com";
$src->SrcPhoneNumber[2]->sph_primary_flag = true;
$src->SrcPhoneNumber[2]->sph_number = '5555555555';
$src->SrcMailAddress[2]->smadd_primary_flag = true;
$src->SrcMailAddress[2]->smadd_city = 'Denver';
$src->save();

$src->refresh(true);
is( $src->SrcEmail[0]->sem_primary_flag, false, 'new primary - email 1' );
is( $src->SrcEmail[1]->sem_primary_flag, false, 'new primary - email 2' );
is( $src->SrcEmail[2]->sem_primary_flag, true, 'new primary - email 3' );
is( $src->SrcPhoneNumber[0]->sph_primary_flag, false, 'new primary - phone 1' );
is( $src->SrcPhoneNumber[1]->sph_primary_flag, false, 'new primary - phone 2' );
is( $src->SrcPhoneNumber[2]->sph_primary_flag, true, 'new primary - phone 3' );
is( $src->SrcMailAddress[0]->smadd_primary_flag, false, 'new primary - mail 1' );
is( $src->SrcMailAddress[1]->smadd_primary_flag, false, 'new primary - mail 2' );
is( $src->SrcMailAddress[2]->smadd_primary_flag, true, 'new primary - mail 3' );

/**********************
 * manually change upd dtim to make one non-primary the "newest"
 */
change_upd_dtim($src->SrcEmail[1], '+1 minute');
change_upd_dtim($src->SrcPhoneNumber[0], '-2 minute');
change_upd_dtim($src->SrcPhoneNumber[1], '-1 minute');
change_upd_dtim($src->SrcMailAddress[1], '+1 minute');
change_upd_dtim($src->SrcMailAddress[0], '+2 minute');
$src->refresh(true);

/**********************
 * unset primary
 */
$src->SrcEmail[2]->sem_primary_flag = false;
$src->SrcPhoneNumber[2]->sph_primary_flag = false;
$src->SrcMailAddress[2]->smadd_primary_flag = false;
$src->save();

$src->refresh(true);
is( $src->SrcEmail[0]->sem_primary_flag, false, 'unset - email 1' );
is( $src->SrcEmail[1]->sem_primary_flag, true, 'unset - email 2' );
is( $src->SrcEmail[2]->sem_primary_flag, false, 'unset - email 3' );
is( $src->SrcPhoneNumber[0]->sph_primary_flag, false, 'unset - phone 1' );
is( $src->SrcPhoneNumber[1]->sph_primary_flag, true, 'unset - phone 2' );
is( $src->SrcPhoneNumber[2]->sph_primary_flag, false, 'unset - phone 3' );
is( $src->SrcMailAddress[0]->smadd_primary_flag, true, 'unset - mail 1' );
is( $src->SrcMailAddress[1]->smadd_primary_flag, false, 'unset - mail 2' );
is( $src->SrcMailAddress[2]->smadd_primary_flag, false, 'unset - mail 3' );

/**********************
 * manually change upd dtim to make one non-primary the "newest"
 */
change_upd_dtim($src->SrcEmail[2], '+10 minute');
change_upd_dtim($src->SrcPhoneNumber[2], '+10 minute');
change_upd_dtim($src->SrcMailAddress[2], '+10 minute');
$src->refresh(true);

/**********************
 * delete primary
 */
$src->SrcEmail[1]->delete();
$src->SrcPhoneNumber[1]->delete();
$src->SrcMailAddress[0]->delete();

$src->refresh(true);
is( $src->SrcEmail[0]->sem_primary_flag, false, 'delete - email 1' );
is( $src->SrcEmail[1]->sem_primary_flag, true, 'delete - email 2' );
is( $src->SrcPhoneNumber[0]->sph_primary_flag, false, 'delete - phone 1' );
is( $src->SrcPhoneNumber[1]->sph_primary_flag, true, 'delete - phone 2' );
is( $src->SrcMailAddress[0]->smadd_primary_flag, false, 'delete - mail 1' );
is( $src->SrcMailAddress[1]->smadd_primary_flag, true, 'delete - mail 2' );
