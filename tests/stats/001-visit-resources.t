#!/usr/bin/env php
<?php

require_once 'app/init.php';
require_once APPPATH . '/../tests/Test.php';
require_once 'AIR2_DBManager.php';
require_once 'rframe/AIRAPI.php';
require_once APPPATH . '/../tests/AirHttpTest.php';
require_once APPPATH . '/../tests/models/TestOrganization.php';
require_once APPPATH . '/../tests/models/TestProject.php';
require_once APPPATH . '/../tests/models/TestSource.php';
require_once APPPATH . '/../tests/models/TestUser.php';
require_once APPPATH . '/../tests/models/TestInquiry.php';
require_once APPPATH . '/../tests/models/TestSrcResponseSet.php';

plan(6);

// Initialize DB connection.
ok(AIR2_DBManager::init());

/**
 * Initialize data.
 */
$user = new TestUser();
$user->save();

$org = new TestOrganization();
$org->add_users(array($user), AdminRole::WRITER);
$org->save();

$project = new TestProject();
$project->add_orgs(array($org));
$project->save();
$org->org_default_prj_id = $project->prj_id;
$org->save();

// Create test source.
$src = new TestSource();
$src->add_orgs(array($org));
$src->save();
is(strlen($src->src_uuid) > 1, true);

$inq = new TestInquiry();
$inq->save();

$src = new TestSource();
$src->add_orgs(array($org));
$src->save();

$srs = new TestSrcResponseSet();
$srs->Source = $src;
$srs->Inquiry = $inq;
$srs->srs_date = date('Y-m-d');
$srs->save();

// clean slate
$conn = AIR2_DBManager::get_master_connection();
$conn->exec("delete from user_visit");

// Initialize browser.
$browser = new AirHttpTest();
$browser->set_content_type(AirHttpTest::$HTML);
$browser->set_user('testuser', array());

/**
 * Test visiting a source (/source/abc123.html).
 */
// Make sure there aren't any existing visits for this source.
$recs = UserVisit::find(array(
	'type' => UserVisit::$VISITABLE['Source'],
	'xid' => $src->src_id)
);
is(count($recs), 0, "visits start at zero");

// Test retrieving the source.
$result = $browser->http_get('/source/' . $src->src_uuid);

// Make sure a visit was recorded.
$recs = UserVisit::find(array(
	'type' => UserVisit::$VISITABLE['Source'],
	'xid' => $src->src_id)
);
is(count($recs), 1, 'one visit recorded');

/**
 * Test visiting a SrcResponseSet (/submission/abc123.html).
 */
// Make sure visits == 0 at start.
$recs = UserVisit::find(array(
	'type' => UserVisit::$VISITABLE['SrcResponseSet'],
	'xid' => $srs->srs_id)
);
is(count($recs), 0, "visits start at zero");

// Visit.
$result = $browser->http_get('/submission/' . $srs->srs_uuid);

// Make sure visits == 1 after visiting.
$recs = UserVisit::find(array(
	'type' => UserVisit::$VISITABLE['SrcResponseSet'],
	'xid' => $srs->srs_id)
);
is(count($recs), 1, "visits increment by one");
