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
require_once 'models/TestSource.php';

// init
AIR2_DBManager::init();
plan(29);

// create a test organization to look at
$s = new TestSource();
$s->SrcPhoneNumber[0]->sph_context = SrcPhoneNumber::$CONTEXT_CELL;
$s->SrcPhoneNumber[0]->sph_number = '6515555555';
$s->SrcMailAddress[0]->smadd_context = SrcMailAddress::$CONTEXT_WORK;
$s->SrcMailAddress[0]->smadd_line_1 = '1234 Fake Street';
$s->SrcMailAddress[0]->smadd_line_2 = 'Apt 12';
$s->SrcMailAddress[0]->smadd_city = 'St. Paul';
$s->SrcMailAddress[0]->smadd_state = 'MN';
$s->SrcMailAddress[0]->smadd_zip = '55101';
$s->SrcMailAddress[0]->smadd_context = SrcMailAddress::$CONTEXT_HOME;
$s->SrcMailAddress[0]->smadd_line_1 = '12 Country Road';
$s->SrcMailAddress[0]->smadd_line_2 = 'Rural route 12';
$s->SrcMailAddress[0]->smadd_city = 'Nowhere';
$s->SrcMailAddress[0]->smadd_state = 'MN';
$s->SrcMailAddress[0]->smadd_zip = '55555';
$s->SrcEmail[0]->sem_context = SrcEmail::$CONTEXT_PERSONAL;
$s->SrcEmail[0]->sem_email = 'blah@fake.com';
AIR2_DBManager::$FORCE_MASTER_ONLY = true;
$s->save();
AIR2_DBManager::$FORCE_MASTER_ONLY = false;

function get_query() {
    global $s;
    $q = Doctrine_Query::create();
    $q->from('Source a');
    $q->leftJoin('a.SrcPhoneNumber p');
    $q->leftJoin('a.SrcMailAddress m');
    $q->addWhere('a.src_uuid = ?', $s->src_uuid);
    return $q;
}

/**********************
 * Test normal fetch
 */
$q = get_query();
$rs = $q->fetchArray();
$data = isset($rs[0]) ? $rs[0] : array();
is( count($rs), 1, 'normal - count' );
ok( isset($data['src_username']), 'normal - source set' );
ok( isset($data['SrcPhoneNumber']), 'normal - phone set' );
ok( isset($data['SrcMailAddress']), 'normal - mail set' );


/**********************
 * Test explicit select
 */
$q = get_query();
$q->select('a.*');
$rs = $q->fetchArray();
$data = isset($rs[0]) ? $rs[0] : array();
is( count($rs), 1, 'select() - count' );
ok( isset($data['src_username']), 'select() - source set' );
ok( !isset($data['SrcPhoneNumber']), 'select() - phone unset' );
ok( !isset($data['SrcMailAddress']), 'select() - mail unset' );


/**********************
 * Test subquery
 */
$q = get_query();
$q->select('a.*, (select count(*) from source) as total_count');
$rs = $q->fetchArray();
$data = isset($rs[0]) ? $rs[0] : array();
is( count($rs), 1, 'select() - count' );
ok( isset($data['src_username']), 'select() extra - source set' );
ok( isset($data['total_count']), 'select() extra - total_count set' );
ok( !isset($data['SrcPhoneNumber']), 'select() extra - phone unset' );
ok( !isset($data['SrcMailAddress']), 'select() extra - mail unset' );


/**********************
 * Test subquery as addSelect
 */
$q = get_query();
$q->addSelect('(select count(*) from source) as total_count');
$rs = $q->fetchArray();
$data = isset($rs[0]) ? $rs[0] : array();
is( count($rs), 1, 'addSelect() implicit - count' );
ok( isset($data['src_username']), 'addSelect() implicit - source set' );
ok( isset($data['total_count']), 'addSelect() implicit - total_count set' );
ok( isset($data['SrcPhoneNumber']), 'addSelect() implicit - phone set' );
ok( isset($data['SrcMailAddress']), 'addSelect() implicit - mail set' );


/**********************
 * Test explicit with addselect
 */
$q = get_query();
$q->select('a.*');
$q->addSelect('(select count(*) from source) as total_count');
$rs = $q->fetchArray();
$data = isset($rs[0]) ? $rs[0] : array();
is( count($rs), 1, 'addSelect() explicit - count' );
ok( isset($data['src_username']), 'addSelect() explicit - source set' );
ok( isset($data['total_count']), 'addSelect() explicit - total_count set' );
ok( !isset($data['SrcPhoneNumber']), 'addSelect() explicit - phone not set' );
ok( !isset($data['SrcMailAddress']), 'addSelect() explicit - mail not set' );


/**********************
 * Test join after addSelect
 */
$q = get_query();
$q->addSelect('(select count(*) from source) as total_count');
$q->leftJoin('a.SrcEmail e');
$rs = $q->fetchArray();
$data = isset($rs[0]) ? $rs[0] : array();
is( count($rs), 1, 'addSelect() join - count' );
ok( isset($data['src_username']), 'addSelect() join - source set' );
ok( isset($data['total_count']), 'addSelect() join - total_count set' );
ok( isset($data['SrcPhoneNumber']), 'addSelect() join - phone set' );
ok( isset($data['SrcMailAddress']), 'addSelect() join - mail set' );

// since we called leftJoin before joining this, email won't be included
// in the select statement.  See AIR2_Query::addSelect().
ok( !isset($data['SrcEmail']), 'addSelect() join - email NOT set' );