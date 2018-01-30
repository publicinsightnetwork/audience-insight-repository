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
require_once APPPATH.'../tests/Test.php';
require_once APPPATH.'../tests/AirHttpTest.php';
require_once APPPATH.'../tests/AirTestUtils.php';
require_once APPPATH.'../tests/models/TestUser.php';
require_once APPPATH.'../tests/models/TestOrganization.php';
require_once APPPATH.'../tests/models/TestProject.php';
require_once APPPATH.'../tests/models/TestInquiry.php';
require_once APPPATH.'../lib/querybuilder/AIR2_PublishedQuery.php';

define('MY_TEST_PASS', 'fooBar123.');

plan(7);

AIR2_DBManager::init();

// data prep
$user = new TestUser();
$user->user_encrypted_password = MY_TEST_PASS;
$user->save();
$org = new TestOrganization();
$org->save();
$org->add_users(array($user));
$org->save();
$project = new TestProject();
$project->add_orgs(array($org));
$project->save();
$inquiry = new TestInquiry();
$inquiry->add_projects(array($project));
$inquiry->Question[0]->ques_value = 'what is the air-speed velocity of a swallow?';
$inquiry->save();

// workflow tests

// write static files at publish time
ok( $inquiry->do_publish(), "do_publish" );

// verify all files exist
ok( $inquiry->has_published_files(), "has_published_files" );

// fetch published JSON
ok( $pub_query = new AIR2_PublishedQuery($inquiry->inq_uuid), "new PublishedQuery" );
ok( $query_json = $pub_query->get_json(), "published get_json" );

//diag_dump( $query_json );

// mock submission
$incoming_submission = array(
    $inquiry->Question[0]->ques_uuid => 'african or european swallow?'
);
$meta = array( 'referer' => null, 'mtime' => time() );
ok( $ok_submission = $pub_query->validate($incoming_submission, $meta),
    "validate incoming submission"
);

// nuke any previous file
$file = $ok_submission->get_file_path();
if (file_exists($file)) {
    diag("cleaning up stale test file");
    unlink($file);
}

ok( $ok_submission->write_file(), "write incoming submission" );
ok( file_exists( $file ), "submission written" );

// clean up
unlink($file);
