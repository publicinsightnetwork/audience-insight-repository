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
require_once 'AirHttpTest.php';
require_once 'AirTestUtils.php';
require_once 'models/TestProject.php';
require_once 'models/TestOrganization.php';
require_once 'models/TestUser.php';
require_once 'models/TestSource.php';
require_once 'AIR2Merge.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// test user
$u = new TestUser();
$u->save();
$o = new TestOrganization();
$o->add_users(array($u), 4); //MANAGER
$o->save();

// browser
$browser = new AirHttpTest();
$browser->set_user($u);
$browser->set_content_type(AirHttpTest::$JSON);

// test data
$prime = new TestSource();
$prime->src_username = 'PRIMEUSER1234';
$prime->src_first_name = 'Harold';
$prime->src_last_name = 'Blah';
$prime->src_middle_initial = 'T';
$prime->src_pre_name = null;
$prime->src_post_name = 'Senior';
$prime->src_status = Source::$STATUS_ENROLLED;
$prime->src_has_acct = Source::$ACCT_YES;
$prime->src_channel = Source::$CHANNEL_EVENT;
$prime->save();
$prime_uuid = $prime->src_uuid;

$merge = new TestSource();
$merge->src_username = 'MERGEUSER1234';
$merge->src_first_name = 'Steven';
$merge->src_last_name = 'Blah';
$merge->src_middle_initial = 'L';
$merge->src_pre_name = 'Duke';
$merge->src_post_name = 'Junior';
$merge->src_status = Source::$STATUS_ENGAGED;
$merge->src_has_acct = Source::$ACCT_NO;
$merge->src_channel = Source::$CHANNEL_QUERY;
$merge->save();
$merge_uuid = $merge->src_uuid;


plan(48);

/**********************
 * sanity check html
 */
$page = $browser->http_get("/merge");
is( $browser->resp_code(), 404, "GET merge list" );
$page = $browser->http_get("/merge/BADTYPE");
is( $browser->resp_code(), 404, "GET bad type" );
$page = $browser->http_get("/merge/source");
is( $browser->resp_code(), 404, "GET source no-uuid" );
$page = $browser->http_get("/merge/source/$prime_uuid");
is( $browser->resp_code(), 404, "GET source 1-uuid" );
$page = $browser->http_get("/merge/source/$prime_uuid/baduuid");
is( $browser->resp_code(), 404, "GET source bad 2nd uuid" );
$page = $browser->http_get("/merge/source/baduuid/$merge_uuid");
is( $browser->resp_code(), 404, "GET source bad 1st uuid" );


/**********************
 * authz on sources
 */
$page = $browser->http_get("/merge/source/$prime_uuid/$merge_uuid");
is( $browser->resp_code(), 403, "GET prime authz" );
ok( $json=json_decode($page,true), 'GET prime authz json' );
like( $json['message'], '/prime source/i', 'GET prime authz message' );
$prime->add_orgs(array($o));
$prime->save();

$page = $browser->http_get("/merge/source/$prime_uuid/$merge_uuid");
is( $browser->resp_code(), 403, "GET merge authz" );
ok( $json=json_decode($page,true), 'GET merge authz json' );
like( $json['message'], '/merge source/i', 'GET merge authz message' );
$merge->add_orgs(array($o));
$merge->save();


/**********************
 * merge with SOURCE acct
 */
$page = $browser->http_get("/merge/source/$merge_uuid/$prime_uuid");
is( $browser->resp_code(), 500, 'GET backwards - status' );
ok( $json=json_decode($page,true), 'GET backwards - json' );
is( $json['success'], false, 'GET backwards - unsuccess' );
ok( isset($json['message']), 'GET backwards - has message' );
ok( preg_match('/source account/i', $json['message']), 'GET backwards - message' );


/**********************
 * GET/preview merge
 */
$page = $browser->http_get("/merge/source/$prime_uuid/$merge_uuid");
is( $browser->resp_code(), 400, 'GET preview - status' );
ok( $json=json_decode($page,true), 'GET preview - json' );
is( $json['success'], false, 'GET preview - unsuccess' );
is( count($json['errors']), 3, 'GET preview - 3 errors' );

// go with the merge source on all conflicts
$ops = json_encode(array('Source' => AIR2Merge::OPTMERGE));
$page = $browser->http_get("/merge/source/$prime_uuid/$merge_uuid", array('ops' => $ops));
is( $browser->resp_code(), 200, 'GET preview2 - status' );
ok( $json=json_decode($page,true), 'GET preview2 - json' );
is( $json['success'], true, 'GET preview2 - success' );
ok( !isset($json['errors']) || count($json['errors']) == 0, 'GET preview2 - no errors' );
ok( isset($json['PrimeSource']), 'GET preview2 - PrimeSource' );
ok( isset($json['MergeSource']), 'GET preview2 - MergeSource' );
ok( isset($json['ResultSource']), 'GET preview2 - ResultSource' );

// check data state
$mi = 'src_middle_initial';
$prime->refresh(true);
$merge->refresh(true);
$psrc = $json['PrimeSource'];
$msrc = $json['MergeSource'];
$rsrc = $json['ResultSource'];
ok( $merge && $merge->exists(), 'GET preview2 - merge exists' );
is( $prime[$mi], 'T', 'GET preview2 - prime preserved' );
is( $merge[$mi], 'L', 'GET preview2 - merge preserved' );
is( $psrc[$mi], $prime[$mi], 'GET preview2 - prime MI' );
is( $msrc[$mi], $merge[$mi], 'GET preview2 - merge MI' );
is( $rsrc[$mi], $merge[$mi], 'GET preview2 - result MI' );


/**********************
 * POST/commit merge
 */
// go with the merge source on all conflicts
$ops = array('Source' => array(
    'src_middle_initial' => AIR2Merge::OPTPRIME,
    'src_first_name' => AIR2Merge::OPTMERGE,
    'src_post_name' => AIR2Merge::OPTMERGE,
));
$page = $browser->http_post("/merge/source/$prime_uuid/$merge_uuid", array('ops' => json_encode($ops)));
is( $browser->resp_code(), 200, 'POST commit - status' );
ok( $json=json_decode($page,true), 'POST commit - json' );
is( $json['success'], true, 'POST commit - success' );
ok( !isset($json['errors']) || count($json['errors']) == 0, 'POST commit - no errors' );
ok( isset($json['PrimeSource']), 'POST commit - PrimeSource' );
ok( isset($json['MergeSource']), 'POST commit - MergeSource' );
ok( isset($json['ResultSource']), 'POST commit - ResultSource' );

// refresh in try/catch
try {
    $merge->refresh(true);
    fail( 'GET preview2 - merge deleted' );
}
catch (Exception $e) {
    pass( 'GET preview2 - merge deleted' );
}

// check data state
$fn = 'src_first_name';
$pn = 'src_post_name';
$prime->refresh(true);
$rsrc = $json['ResultSource'];
is( $prime[$mi], 'T', 'GET preview2 - prime MI' );
is( $rsrc[$mi], 'T', 'GET preview2 - result MI' );
is( $prime[$fn], 'Steven', 'GET preview2 - prime first' );
is( $rsrc[$fn], 'Steven', 'GET preview2 - result first' );
is( $prime[$pn], 'Junior', 'GET preview2 - prime post' );
is( $rsrc[$pn], 'Junior', 'GET preview2 - result post' );
