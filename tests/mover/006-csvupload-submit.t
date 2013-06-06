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
require_once APPPATH.'/../tests/models/TestProject.php';
require_once APPPATH.'/../tests/models/TestOrganization.php';
require_once APPPATH.'/../tests/models/TestTank.php';
require_once APPPATH.'/../tests/AirHttpTest.php';

// init
AIR2_DBManager::init();
$browser = new AirHttpTest();
$browser->set_content_type(AirHttpTest::$JSON);
$browser->set_test_user();
$csv_dir = dirname(__FILE__).'/csv';

// test data
$p = new TestProject();
$p->save();
$p2 = new TestProject();
$p2->save();
$o = new TestOrganization();
$o->save();
$o2 = new TestOrganization();
$o2->save();

// helper function for POSTing a file
function upload_file($url, $fld_name, $file, $put=false) {
    global $browser;

    $session = curl_init($browser->base_url.$url);
    curl_setopt($session, CURLOPT_HEADER, false);
    curl_setopt($session, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($session, CURLOPT_POST, true);

    // tunnel put method
    $params = array($fld_name => "@$file");
    if ($put) {
        $params['x-tunneled-method'] = 'PUT';
    }

    curl_setopt($session, CURLOPT_POSTFIELDS, $params);
    foreach ($browser->cookies as $nm => $ck) {
        curl_setopt($session, CURLOPT_COOKIE, "$nm=$ck");
    }
    curl_setopt($session, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($session, CURLOPT_SSL_VERIFYHOST, false);

    return curl_exec($session);
}


plan(87);

/**********************
 * Create
 */
$tank = new TestTank();
$tank->tank_user_id = 1;
$tank->tank_type = Tank::$TYPE_CSV;
$tank->tank_status = Tank::$STATUS_CSV_NEW;
$tank->tank_name = 'test_header.csv';
$tank->save();
$tank->copy_file("$csv_dir/test_header.csv");
$uuid1 = $tank->tank_uuid;

ok( $resp = $browser->http_get("csv/$uuid1"), 'GET csv' );
is( $browser->resp_code(), 200, 'GET csv - response code' );
ok( $json = json_decode($resp, true), 'GET csv - decode' );
is( $json['success'], true, 'GET csv - success' );


/**********************
 * Submit failure
 */
// DNE
ok( $resp = $browser->http_post("csv/DNE12345/submit"), 'non-existent' );
is( $browser->resp_code(), 404, 'non-existent - 404' );

// bad mapping (change delim)
$tank->set_meta_field('csv_delim', ';');
$tank->save();
$radix = json_encode(array('nojob' => 1));
ok( $resp = $browser->http_post("csv/$uuid1/submit", array('radix' => $radix)), 'bad mapping' );
is( $browser->resp_code(), 400, 'bad mapping - response code' );
ok( $json = json_decode($resp, true), 'bad mapping - decode' );
is( $json['success'], false, 'bad mapping - unsuccess' );
like( $json['message'], '/is required/i', 'bad mapping - message' );

// good mapping (no org)
$tank->set_meta_field('csv_delim', ',');
$tank->save();
$radix = json_encode(array('nojob' => 1));
ok( $resp = $browser->http_post("csv/$uuid1/submit", array('radix' => $radix)), 'no org' );
is( $browser->resp_code(), 400, 'no org - response code' );
ok( $json = json_decode($resp, true), 'no org - decode' );
is( $json['success'], false, 'no org - unsuccess' );
like( $json['message'], '/organization/i', 'no org - message' );


/**********************
 * Update org_uuid
 */
// bad org_uuid
$radix = json_encode(array('org_uuid' => 'FAKE'));
ok( $resp = $browser->http_put("csv/$uuid1", array('radix' => $radix)), 'bad org_uuid' );
is( $browser->resp_code(), 400, 'bad org_uuid - response code' );
ok( $json = json_decode($resp, true), 'bad org_uuid - decode' );
is( $json['success'], false, 'bad org_uuid - unsuccess' );
like( $json['message'], '/invalid org_uuid/i', 'bad org_uuid - message' );
$tank->refresh(true);
is( $tank->TankOrg->count(), 0, 'bad org_uuid - TankOrg count' );

// good org_uuid
$radix = json_encode(array('org_uuid' => $o->org_uuid));
ok( $resp = $browser->http_put("csv/$uuid1", array('radix' => $radix)), 'good org_uuid' );
is( $browser->resp_code(), 200, 'good org_uuid - response code' );
ok( $json = json_decode($resp, true), 'good org_uuid - decode' );
is( $json['success'], true, 'good org_uuid - success' );
$tank->clearRelated('TankOrg');
is( $tank->TankOrg->count(), 1, 'good org_uuid - TankOrg count' );
is( $tank->TankOrg[0]->to_org_id, $o->org_id, 'good org_uuid - org_id' );

// change org_uuid
$radix = json_encode(array('org_uuid' => $o2->org_uuid));
ok( $resp = $browser->http_put("csv/$uuid1", array('radix' => $radix)), 'change org_uuid' );
is( $browser->resp_code(), 200, 'change org_uuid - response code' );
ok( $json = json_decode($resp, true), 'change org_uuid - decode' );
is( $json['success'], true, 'change org_uuid - success' );
$tank->clearRelated('TankOrg');
is( $tank->TankOrg->count(), 1, 'change org_uuid - TankOrg count' );
is( $tank->TankOrg[0]->to_org_id, $o2->org_id, 'change org_uuid - org_id' );

// submit with org
$radix = json_encode(array('nojob' => 1));
ok( $resp = $browser->http_post("csv/$uuid1/submit", array('radix' => $radix)), 'with org' );
is( $browser->resp_code(), 400, 'with org - response code' );
ok( $json = json_decode($resp, true), 'with org - decode' );
is( $json['success'], false, 'with org - unsuccess' );
like( $json['message'], '/activity/i', 'with org - message' );


/**********************
 * Update activity/project
 */
// fail to set all meta
$data = array('prj_uuid' => $p->prj_uuid);
ok( $resp = $browser->http_put("csv/$uuid1", array('radix' => json_encode($data))), 'meta missing' );
is( $browser->resp_code(), 400, 'meta missing - response code' );
ok( $json = json_decode($resp, true), 'meta missing - decode' );
is( $json['success'], false, 'meta missing - unsuccess' );
like( $json['message'], '/missing required/i', 'meta missing - message' );
like( $json['message'], '/evdesc.+evdtim.+evtype.+evdir/i', 'meta missing - message2' );
$tank->refresh(true);
is( $tank->TankActivity->count(), 0, 'meta missing - TankActivity count' );

// invalid prj_uuid
$data = array(
    'prj_uuid' => 'FAKESTREET',
    'evdesc'   => '1234',
    'evdtim'   => air2_date(),
    'evtype'   => 'E',
    'evdir'    => 'I',
);
ok( $resp = $browser->http_put("csv/$uuid1", array('radix' => json_encode($data))), 'bad prj' );
is( $browser->resp_code(), 400, 'bad prj - response code' );
ok( $json = json_decode($resp, true), 'bad prj - decode' );
is( $json['success'], false, 'bad prj - unsuccess' );
like( $json['message'], '/invalid prj_uuid/i', 'bad prj - message' );
$tank->refresh(true);
is( $tank->TankActivity->count(), 0, 'bad prj - TankActivity count' );

// valid!
$data['prj_uuid'] = $p->prj_uuid;
ok( $resp = $browser->http_put("csv/$uuid1", array('radix' => json_encode($data))), 'valid prj' );
is( $browser->resp_code(), 200, 'valid prj - response code' );
ok( $json = json_decode($resp, true), 'valid prj - decode' );
is( $json['success'], true, 'valid prj - success' );
$tank->refresh(true);
is( $tank->TankActivity->count(), 1, 'valid prj - TankActivity count' );
is( $tank->TankActivity[0]->tact_prj_id, $p->prj_id, 'valid prj - prj_id' );

// change
$data['prj_uuid'] = $p2->prj_uuid;
ok( $resp = $browser->http_put("csv/$uuid1", array('radix' => json_encode($data))), 'change prj' );
is( $browser->resp_code(), 200, 'change prj - response code' );
ok( $json = json_decode($resp, true), 'change prj - decode' );
is( $json['success'], true, 'change prj - success' );
$tank->refresh(true);
is( $tank->TankActivity->count(), 1, 'change prj - TankActivity count' );
is( $tank->TankActivity[0]->tact_prj_id, $p2->prj_id, 'change prj - prj_id' );


/**********************
 * Submit
 */
// check for submit... should give a 404
ok( $resp = $browser->http_get("csv/$uuid1/submit"), 'check submit' );
is( $browser->resp_code(), 404, 'check submit - response code' );

// submit
$radix = json_encode(array('nojob' => 1));
ok( $resp = $browser->http_post("csv/$uuid1/submit", array('radix' => $radix)), 'submit' );
is( $browser->resp_code(), 200, 'submit - response code' );
ok( $json = json_decode($resp, true), 'submit - decode' );
is( $json['success'], true, 'submit - success' );

// no job!
$conn = AIR2_DBManager::get_master_connection();
$w = 'where jq_job like "%run-discriminator ?"';
$n = $conn->fetchOne("select count(*) from job_queue $w", array($tank->tank_id), 0);
is( $n, 0, 'submit - no job scheduled' );

// re-submit (fails)
ok( $resp = $browser->http_post("csv/$uuid1/submit", array('radix' => $radix)), 're-submit' );
is( $browser->resp_code(), 405, 're-submit - response code' );
ok( $json = json_decode($resp, true), 're-submit - decode' );
is( $json['success'], false, 're-submit - unsuccess' );
like( $json['message'], '/already exists/i', 're-submit - message' );


/**********************
 * Trigger a doctrine-validation error with the mapping
 */
$tank2 = new TestTank();
$tank2->tank_user_id = 1;
$tank2->tank_type = Tank::$TYPE_CSV;
$tank2->tank_status = Tank::$STATUS_CSV_NEW;
$tank2->tank_name = 'test_header.csv';
$tank2->save();
$tank2->copy_file("$csv_dir/test_header_error.csv");
$uuid2 = $tank2->tank_uuid;

// set meta
$data = array(
    'org_uuid' => $o->org_uuid,
    'prj_uuid' => $p->prj_uuid,
    'evdesc'   => '1234',
    'evdtim'   => air2_date(),
    'evtype'   => 'E',
    'evdir'    => 'I',
);
ok( $resp = $browser->http_put("csv/$uuid2", array('radix' => json_encode($data))), 'docvalid' );
is( $browser->resp_code(), 200, 'docvalid - response code' );
ok( $json = json_decode($resp, true), 'docvalid - decode' );
is( $json['success'], true, 'docvalid - success' );
$tank2->refresh(true);
is( $tank2->TankActivity->count(), 1, 'docvalid - TankActivity count' );
is( $tank2->TankOrg->count(), 1, 'docvalid - TankOrg count' );

// submit
$radix = json_encode(array('nojob' => 1));
ok( $resp = $browser->http_post("csv/$uuid2/submit", array('radix' => $radix)), 'docvalid submit' );
is( $browser->resp_code(), 400, 'docvalid submit - response code' );
ok( $json = json_decode($resp, true), 'docvalid submit - decode' );
is( $json['success'], false, 'docvalid submit - unsuccess' );
like( $json['message'], '/smadd_zip/i', 'docvalid submit - problem with smadd_zip' );
