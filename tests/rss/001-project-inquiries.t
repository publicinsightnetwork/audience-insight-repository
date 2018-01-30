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
require_once APPPATH . '../tests/Test.php';
require_once APPPATH . '../tests/AirHttpTest.php';
require_once APPPATH . '/../tests/models/TestProject.php';
require_once APPPATH . '/../tests/models/TestInquiry.php';
require_once 'Cache.php';

plan(12);

// We have to do this, or we'll run out of memory when reading the all-project RSS feed.
ini_set('memory_limit', '512M');

// Initialize browser.
$browser = new AirHttpTest();
$browser->set_content_type(AirHttpTest::$RSS);

// Initialize DB connection.
ok(AIR2_DBManager::init());

/*
 * Test data.
 */
$prj = new TestProject();
$prj->save();

$inq = new TestInquiry();
$inq->inq_ext_title = 'Test Inquiry Title';
$inq->inq_rss_intro = 'Test Inquiry RSS Intro.';
is($inq->inq_status, Inquiry::$STATUS_ACTIVE, 'inquiry status');
$inq->inq_rss_status = 'Y';
$inq->inq_publish_dtim = air2_date();
$inq->add_projects(array($prj));
$inq->save();
diag("saved " . $inq->inq_ext_title);

$inq2 = new TestInquiry();
$inq2->inq_ext_title = 'Test Inquiry Title 2';
$inq2->inq_rss_intro = 'Test Inquiry RSS Intro.';
is($inq2->inq_status, Inquiry::$STATUS_ACTIVE, 'inquiry status');
$inq2->inq_rss_status = 'N';
$inq2->inq_publish_dtim = air2_date();
$inq2->add_projects(array($prj));
$inq2->save();
diag("saved " . $inq2->inq_ext_title);

$inq3 = new TestInquiry();
$inq3->inq_ext_title = 'Test Inquiry Title 3';
$inq3->inq_rss_intro = 'Test Inquiry RSS Intro.';
$inq3->inq_status = Inquiry::$STATUS_INACTIVE;
$inq3->inq_rss_status = 'Y';
$inq3->inq_publish_dtim = air2_date();
$inq3->add_projects(array($prj));
$inq3->save();
diag("saved " . $inq3->inq_ext_title);

$inq4 = new TestInquiry();
$inq4->inq_ext_title = 'Test Inquiry Title 4';
$inq4->inq_rss_intro = 'Test Inquiry RSS Intro.';
$inq4->inq_status = 'F';
$inq4->inq_rss_status = 'Y';
$inq4->inq_publish_dtim = air2_date(time() + 1000); // future
$inq4->add_projects(array($prj));
$inq4->save();
diag("saved " . $inq4->inq_ext_title);

$inq5 = new TestInquiry();
$inq5->inq_ext_title = 'Test Inquiry Title 5';
$inq5->inq_rss_intro = 'Test Inquiry RSS Intro.';
$inq5->inq_status = 'F';
$inq5->inq_rss_status = 'Y';
$inq5->inq_publish_dtim = air2_date();
$inq5->inq_expire_dtim = air2_date(time() - 1000); // past
$inq5->add_projects(array($prj));
$inq5->save();
diag("saved " . $inq5->inq_ext_title);

$inq6 = new TestInquiry();
$inq6->inq_ext_title = 'Test Inquiry Title 6';
$inq6->inq_rss_intro = 'Test Inquiry <b>RSS Intro</b>';
$inq6->inq_status = 'F';
$inq6->inq_rss_status = 'Y';
$inq6->inq_publish_dtim = air2_date();
$inq6->inq_expire_dtim = air2_date(time() - 1000); // past 
$inq6->add_projects(array($prj));
try {
    $inq6->save(); // should blow up
    fail("Inquiry->inq_rss_intro invalidates HTML for " . $inq6->inq_rss_intro);
}
catch(Exception $e) {
    //diag( $e );
    pass("Inquiry->inq_rss_intro invalidates HTML for " . $inq6->inq_rss_intro);
}

// Make sure $prj's RSS feed cache doesn't exist, to begin with.
is(
    file_exists( $prj->get_rss_cache_path() ),
    false,
    'cache does not exist'
);

// Make sure the all-project RSS feed cache doesn't exist, to begin with.
is(
    file_exists( Project::get_combined_rss_cache_path() ),
    false,
    'all-project cache does not exist'
);

// Get the RSS feed for the project.
$response = $browser->http_get('/rss/project/' . $prj->prj_name . '.rss');
//diag( $response );

// Make sure the feed response is a valid XML, and has the elements
$sum_before = md5($response);  // Note: This is only the body; not including headers.
$rss = new SimpleXMLElement($response);
$items = $rss->xpath('/rss/channel/item');
foreach ($items as $item) {
    //diag( $item->title );
}
is(count($items), 1, 'count of items in rss feed'); // only one of 5 in the feed

// Check the all-project RSS feed now.
$response = $browser->http_get('/rss/project.rss');
//diag( $response );

$sum_all_before = md5($response);
$rss = new SimpleXMLElement($response);
$items = $rss->xpath('/rss/channel/item');
foreach ($items as $item) {
    //diag( 'all projects: ' . $item->title );
}
isnt(count($items), 1, 'count of items in rss feed');

// Check cache file existence for our test project, and all projects.
is(
    file_exists( $prj->get_rss_cache_path() ),
    true,
    'cache existence after first load'
);
is(
    file_exists( Project::get_combined_rss_cache_path() ),
    true,
    'all-project cache after first load'
);

// Make sure feeds change after saving the inquiry.
$inq->inq_ext_title = 'CHANGE Test Inquiry Title';
$inq->save();
$sum_after     = md5($browser->http_get('/rss/project/' . $prj->prj_name . '.rss'));
$sum_all_after = md5($browser->http_get('/rss/project.rss'));

isnt($sum_after, $sum_before, 'checksums of project feed before and after');
isnt($sum_all_after, $sum_all_before, 'checksums of all-projects feed before and after');
