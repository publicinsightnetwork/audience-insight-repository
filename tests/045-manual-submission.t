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
require_once 'AirHttpTest.php';
require_once 'models/TestProject.php';
require_once 'models/TestOrganization.php';
require_once 'models/TestUser.php';
require_once 'models/TestSource.php';

// init
AIR2_DBManager::init();
$conn = AIR2_DBManager::get_master_connection();

// test data
$usr = new TestUser();
$usr->save();
$usr2 = new TestUser();
$usr2->save();
$org = new TestOrganization();
$org->add_users(array($usr2), 2); //reader
$org->add_users(array($usr), 6); //reader-plus
$org->save();
$prj = new TestProject();
$prj->add_orgs(array($org));
$prj->save();
$prj2 = new TestProject();
$prj2->save();
$src = new TestSource();
$src->add_orgs(array($org));
$src->save();
$uuid = $src->src_uuid;

// http test
$browser = new AirHttpTest();
$browser->set_user($usr);
$browser->set_content_type(AirHttpTest::$JSON);
$data = array();


/**
 *
 *
 * @return unknown
 */
function radix() {
    global $data;
    return array('radix' => json_encode($data));
}


// cleanup for the just-in-time inquiry
class TestCleanup {
    public $test_user_id;


    /**
     *
     *
     * @param unknown $user_id
     */
    function __construct($user_id) {
        $this->test_user_id = $user_id;
    }


    /**
     *
     */
    function __destruct() {
        $conn = AIR2_DBManager::get_master_connection();
        $q = 'delete from inquiry where inq_cre_user = ?';
        $num = $conn->exec($q, array($this->test_user_id));
        //echo "\nDELETED $num stale inquiries\n";
    }


}


$cleanup = new TestCleanup($usr->user_id);


plan(83);

/**********************
 * Sanity check  TODO - this doesn't locate orphaned manual submission inquiry...
 */
ok( $resp = $browser->http_get("/source/$uuid"), 'source json' );
is( $browser->resp_code(), 200, 'source json resp code' );
is( count($src->SrcResponseSet), 0, 'source no submissions' );
is( count($prj->ProjectInquiry), 0, 'project no inquiries' );


/**********************
 * All the ways to fail
 */
$data['manual_entry_type'] = 'E';
$data['manual_entry_desc'] = 'desc';
$data['manual_entry_text'] = 'text';
$data['srs_date'] = '';
$url = "/source/$uuid/submission";

// no project
ok( $resp = $browser->http_post($url, radix()), 'POST no prj' );
is( $browser->resp_code(), 400, 'POST no prj - resp code' );
ok( $json = json_decode($resp, true), 'POST no prj - json' );
is( $json['success'], false, 'POST no prj - unsuccess' );
like( $json['message'], '/prj_uuid/i', 'POST no prj - message' );

// DNE project
$data['prj_uuid'] = 'DOESNOTEXIST';
ok( $resp = $browser->http_post($url, radix()), 'POST DNE prj' );
is( $browser->resp_code(), 400, 'POST DNE prj - resp code' );
ok( $json = json_decode($resp, true), 'POST DNE prj - json' );
is( $json['success'], false, 'POST DNE prj - unsuccess' );
like( $json['message'], '/project/i', 'POST DNE prj - message' );

// invalid (bad authz) project
$data['prj_uuid'] = $prj2->prj_uuid; //no access by $usr
ok( $resp = $browser->http_post($url, radix()), 'POST no-access prj' );
is( $browser->resp_code(), 403, 'POST no-access prj - resp code' );
ok( $json = json_decode($resp, true), 'POST no-access prj - json' );
is( $json['success'], false, 'POST no-access prj - unsuccess' );
like( $json['message'], '/project/i', 'POST no-access prj - message' );

// no entry desc
$data['prj_uuid'] = $prj->prj_uuid;
unset($data['manual_entry_desc']);
ok( $resp = $browser->http_post($url, radix()), 'POST no desc' );
is( $browser->resp_code(), 400, 'POST no desc - resp code' );
ok( $json = json_decode($resp, true), 'POST no desc - json' );
is( $json['success'], false, 'POST no desc - unsuccess' );
like( $json['message'], '/desc/i', 'POST no desc - message' );

// no entry text
$data['manual_entry_desc'] = 'desc';
unset($data['manual_entry_text']);
ok( $resp = $browser->http_post($url, radix()), 'POST no text' );
is( $browser->resp_code(), 400, 'POST no text - resp code' );
ok( $json = json_decode($resp, true), 'POST no text - json' );
is( $json['success'], false, 'POST no text - unsuccess' );
like( $json['message'], '/text/i', 'POST no text - message' );

// no entry type
$data['manual_entry_text'] = 'text';
unset($data['manual_entry_type']);
ok( $resp = $browser->http_post($url, radix()), 'POST no type' );
is( $browser->resp_code(), 400, 'POST no type - resp code' );
ok( $json = json_decode($resp, true), 'POST no type - json' );
is( $json['success'], false, 'POST no type - unsuccess' );
like( $json['message'], '/type/i', 'POST no type - message' );

// bad entry type
$data['manual_entry_type'] = '?';
ok( $resp = $browser->http_post($url, radix()), 'POST bad type' );
is( $browser->resp_code(), 400, 'POST bad type - resp code' );
ok( $json = json_decode($resp, true), 'POST bad type - json' );
is( $json['success'], false, 'POST bad type - unsuccess' );
like( $json['message'], '/type/i', 'POST bad type - message' );


/**********************
 * Verify that authz is being applied
 */
is( $src->user_may_read($usr), AIR2_AUTHZ_IS_ORG, 'usr read authz' );
is( $src->user_may_write($usr), AIR2_AUTHZ_IS_ORG, 'usr write authz' );
is( $src->user_may_manage($usr), AIR2_AUTHZ_IS_DENIED, 'usr manage authz' );


/**********************
 * Submit without srs_data
 */
unset($data['srs_date']);
$data['manual_entry_type'] = 'E'; //email
ok( $resp = $browser->http_post($url, radix()), 'POST no-date' );
is( $browser->resp_code(), 400, 'POST no-date - resp code' );
ok( $json = json_decode($resp, true), 'POST no-date - json' );
is( $json['success'], false, 'POST no-date - unsuccess' );
ok( preg_match('/srs_date/i', $json['message']), 'POST no-date - message' );
is( count($src->SrcActivity), 0, 'POST no-date - no activity');


/**********************
 * Make sure "Reader" user fails
 */
$browser->set_user($usr2);
$data['srs_date'] = air2_date(strtotime("-1 day"));
ok( $resp = $browser->http_post($url, radix()), 'reader POST email' );
is( $browser->resp_code(), 403, 'reader POST email - 403' );


/**********************
 * Succeed! (type email)
 */
$browser->set_user($usr);
$data['srs_date'] = air2_date(strtotime("-1 day"));
ok( $resp = $browser->http_post($url, radix()), 'POST email' );
is( $browser->resp_code(), 200, 'POST email - resp code' );
ok( $json = json_decode($resp, true), 'POST email - json' );
//diag_dump( $json );
is( $json['success'], true, 'POST email - success' );


/**********************
 * Verify state
 */
$src->refresh(true);
$prj->refresh(true);
is( count($src->SrcResponseSet), 1, 'source 1 submissions' );
is( count($src->SrcResponse), 3, 'source 3 responses' );
is( count($src->SrcActivity), 1, 'source 1 activity');
is( $src->SrcActivity[0]->sact_xid, $src->SrcResponseSet[0]->srs_id, 'activity sact_xid set' );
is( count($prj->ProjectInquiry), 1, 'project 1 inquiry' );
$inq_uuid = $prj->ProjectInquiry[0]->Inquiry->inq_uuid;

$radix = $json['radix'];
is( $radix['srs_type'], SrcResponseSet::$TYPE_MANUAL_ENTRY, 'POST email - srs_type' );
is( $radix['Inquiry']['inq_uuid'], $inq_uuid, 'POST email - inq_uuid' );
is( $radix['Inquiry']['inq_type'], Inquiry::$TYPE_MANUAL_ENTRY, 'POST email - inq_type' );
ok( array_key_exists('manual_entry_text', $radix), 'POST email - has key' );
ok( preg_match('/email/i', $radix['manual_entry_type']), 'POST email - type response' );
is( $radix['manual_entry_desc'], 'desc', 'POST email - desc response' );
is( $radix['manual_entry_text'], 'text', 'POST email - text response' );


/**********************
 * Create another (type phone)
 */
$data['manual_entry_type'] = 'P'; //phone
$data['manual_entry_desc'] = 'desc2';
$data['manual_entry_text'] = 'text2';
$data['srs_date'] = air2_date(strtotime("-10 day"));
ok( $resp = $browser->http_post($url, radix()), 'POST phone' );
is( $browser->resp_code(), 200, 'POST phone - resp code' );
ok( $json = json_decode($resp, true), 'POST phone - json' );
//diag_dump($json);
is( $json['success'], true, 'POST phone - success' );


/**********************
 * Verify state
 */
$src->refresh(true);
$prj->refresh(true);
is( count($src->SrcResponseSet), 2, 'source 2 submissions' );
is( count($src->SrcResponse), 6, 'source 6 responses' );
is( count($src->SrcActivity), 2, 'source 2 activity');
is( count($prj->ProjectInquiry), 1, 'project 1 inquiry' );
is( count($prj->ProjectInquiry[0]->Inquiry->InqOrg), 1, "inquiry has 1 inq_org");
is( $prj->ProjectOrg[0]->porg_org_id,
    $prj->ProjectInquiry[0]->Inquiry->InqOrg[0]->iorg_org_id,
    "inquiry has 1 inq_org"
);

$radix = $json['radix'];
is( $radix['srs_type'], SrcResponseSet::$TYPE_MANUAL_ENTRY, 'POST phone - srs_type' );
is( $radix['Inquiry']['inq_uuid'], $inq_uuid, 'POST phone - inq_uuid' );
is( $radix['Inquiry']['inq_type'], Inquiry::$TYPE_MANUAL_ENTRY, 'POST phone - inq_type' );
ok( array_key_exists('manual_entry_text', $radix), 'POST phone - has key' );
ok( preg_match('/phone/i', $radix['manual_entry_type']), 'POST phone - type response' );
is( $radix['manual_entry_desc'], 'desc2', 'POST phone - desc response' );
is( $radix['manual_entry_text'], 'text2', 'POST phone - text response' );
