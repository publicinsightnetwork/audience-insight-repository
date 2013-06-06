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
require_once APPPATH.'/../tests/Test.php';
require_once APPPATH.'/../tests/AirHttpTest.php';
require_once APPPATH.'/../tests/models/TestBin.php';
require_once APPPATH.'/../tests/models/TestSource.php';
require_once APPPATH.'/../tests/models/TestUser.php';
require_once APPPATH.'/../tests/models/TestOrganization.php';
require_once 'air2reader/CSVReader.php';

// init
AIR2_DBManager::init();

// test user
$u = new TestUser();
$u->save();
$o = new TestOrganization();
$o->add_users(array($u));
$o->save();

// browser
$browser = new AirHttpTest();
$browser->set_content_type(AirHttpTest::$JSON);
$browser->set_user($u);

/**********************
 * Setup test sources
 */
$s1 = new TestSource();
$s1->add_orgs(array($o));
$s1->save();
$s1->SrcEmail[0]->sem_email = $s1->src_username;
$s1->save();
$s2 = new TestSource();
$s2->add_orgs(array($o));
$s2->save();
$s2->SrcEmail[0]->sem_email = $s2->src_username;
$s2->save();
$s3 = new TestSource();
$s3->add_orgs(array($o));
$s3->save();
$s3->SrcEmail[0]->sem_email = $s3->src_username;
$s3->save();
$s4 = new TestSource();
$s4->save();
$s4->SrcEmail[0]->sem_email = $s4->src_username;
$s4->save();
$s5 = new TestSource();
$s5->save();
$s5->SrcEmail[0]->sem_email = $s5->src_username;
$s5->save();


/**********************
 * Add sources to bin
 */
$b = new TestBin();
$b->bin_user_id = $u->user_id;
$b->BinSource[0]->bsrc_src_id = $s1->src_id;
$b->BinSource[1]->bsrc_src_id = $s2->src_id;
$b->BinSource[2]->bsrc_src_id = $s3->src_id;
$b->BinSource[3]->bsrc_src_id = $s4->src_id;
$b->BinSource[4]->bsrc_src_id = $s5->src_id;
$b->save();
$uuid = $b->bin_uuid;


plan(41);
/**********************
 * Check bin counts
 */
ok( $resp = $browser->http_get("/bin/$uuid"), 'GET bin' );
is( $browser->resp_code(), 200, "GET bin response code" );
ok( $json = json_decode($resp,true), "JSON decode GET bin" );
is( $json['radix']['src_count'], 5, 'bin count 5' );
ok( $resp = $browser->http_get("/bin/$uuid/source"), 'GET bin contents' );
is( $browser->resp_code(), 200, "GET bin contents response code" );
ok( $json = json_decode($resp,true), "JSON decode GET bin contents" );
is( count($json['radix']), 3, 'bin contents count 3' );
is( $json['meta']['total'], 3, 'bin contents total 3' );
is( $json['meta']['unauthz_total'], 5, 'bin contents unauthz_total 5' );


/**********************
 * Test the exporter
 */
ok( $resp = $browser->http_get("/bin/$uuid/exportsource.csv"), 'GET bin csv' );
is( $browser->resp_code(), 200, "GET bin csv response code" );

// write to file so we can read it back in
$fp = fopen("php://memory", "rw");
fwrite($fp, $resp);
fseek($fp, 0);

// read headers
$headers = fgetcsv($fp);
ok( $headers, "read csv headers" );
ok( $width = count($headers), "read csv header count" );

// find username header
$uname_idx = 0;
foreach ($headers as $idx => $hdr) {
    if (strtolower($hdr) == 'username' || strtolower($hdr) == 'email address') {
        $uname_idx = $idx;
        break;
    }
}

// read lines
$line = fgetcsv($fp);
is( count($line), $width, "read csv line 1 - width" );
is( $line[$uname_idx], strtolower($s1->src_username), "read csv line 1 - username" );
$line = fgetcsv($fp);
is( count($line), $width, "read csv line 2 - width" );
is( $line[$uname_idx], strtolower($s2->src_username), "read csv line 2 - username" );
$line = fgetcsv($fp);
is( count($line), $width, "read csv line 3 - width" );
is( $line[$uname_idx], strtolower($s3->src_username), "read csv line 3 - username" );

$line = fgetcsv($fp);
is( $line, null, "csv had 3 lines" );

// check src_activity logging
is( count($s1->SrcActivity), 1, 'src1 activity' );
is( $s1->SrcActivity[0]->sact_cre_user, $u->user_id, 'src1 activity - user_id' );
is( count($s2->SrcActivity), 1, 'src2 activity' );
is( $s2->SrcActivity[0]->sact_cre_user, $u->user_id, 'src2 activity - user_id' );
is( count($s3->SrcActivity), 1, 'src3 activity' );
is( $s3->SrcActivity[0]->sact_cre_user, $u->user_id, 'src3 activity - user_id' );
is( count($s4->SrcActivity), 0, 'src4 no activity' );
is( count($s5->SrcActivity), 0, 'src5 no activity' );

/**********************
 * Export again with User able to read all
 */
$s4->add_orgs(array($o));
$s4->save();
$s5->add_orgs(array($o));
$s5->save();
ok( $resp = $browser->http_get("/bin/$uuid/source"), 'GET bin contents' );
is( $browser->resp_code(), 200, "GET bin contents response code" );
ok( $json = json_decode($resp,true), "JSON decode GET bin contents" );
is( $json['meta']['total'], 5, 'bin contents total 5' );
is( $json['meta']['unauthz_total'], 5, 'bin contents unauthz_total 5' );

ok( $resp = $browser->http_get("/bin/$uuid/exportsource.csv"), 'GET bin csv' );
diag_dump($resp);
is( $browser->resp_code(), 200, "GET bin csv response code" );

// check src_activity logging
$s1->refresh(true);
is( count($s1->SrcActivity), 2, 'src1 2 activity' );
$s2->refresh(true);
is( count($s2->SrcActivity), 2, 'src2 2 activity' );
$s3->refresh(true);
is( count($s3->SrcActivity), 2, 'src3 2 activity' );
$s4->refresh(true);
is( count($s4->SrcActivity), 1, 'src4 1 activity' );
$s5->refresh(true);
is( count($s5->SrcActivity), 1, 'src5 1 activity' );

// delete first to get src_exports cleaned up
$b->__destruct();
