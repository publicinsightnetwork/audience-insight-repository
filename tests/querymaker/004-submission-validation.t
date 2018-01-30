#!/usr/bin/env php
<?php
/**************************************************************************
 *
 *   Copyright 2013 American Public Media Group
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
require_once APPPATH.'../tests/AirTestUtils.php';
require_once APPPATH.'../tests/models/TestUser.php';
require_once APPPATH.'../tests/models/TestOrganization.php';
require_once APPPATH.'../tests/models/TestProject.php';
require_once APPPATH.'../tests/models/TestInquiry.php';
require_once APPPATH.'../lib/querybuilder/AIR2_PublishedQuery.php';

define('MY_TEST_PASS', 'fooBar123.');

plan(8);

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

// questions
$inquiry->save(); // will create contributor questions

$question = new Question;
$question->ques_value = 'what is the air-speed velocity of a swallow?';
$question->ques_resp_type = 'S';
$inquiry->Question[] = $question;
$inquiry->save(); // add our custom question

$url_question = new Question;
$url_question->ques_value = 'where is your web home?';
$url_question->ques_resp_type = Question::$DTYPE_URL;
$inquiry->Question[] = $url_question;
$inquiry->save();

ok( $inquiry->do_publish(), "do_publish" );
ok( $pub_query = new AIR2_PublishedQuery($inquiry->inq_uuid), "new PublishedQuery" );
ok( $query_json = $pub_query->get_json(), "published get_json" );

//diag_dump( $query_json );

// find our contributor questions so we can submit against them
$contrib_question = array();
foreach ($query_json->questions as $q) {
    $contrib_question[$q->ques_template] = $q;
}

// mock submission
$incoming_submission = array(
    $question->ques_uuid => 'african or european swallow?',
    $url_question->ques_uuid => 'http://example.com/foo?bar=quack',
    $contrib_question['email']->ques_uuid => 'hahainvalidemail',
    $contrib_question['firstname']->ques_uuid => 'some',
    $contrib_question['lastname']->ques_uuid  => 'body',
    $contrib_question['zip']->ques_uuid       => '55555',
);
$meta = array( 'referer' => null, 'mtime' => time() );
ok( $fail_submission = $pub_query->validate($incoming_submission, $meta),
    "validate incoming submission"
);
ok( !$fail_submission->ok(), "submission is not ok" );
ok( $errors = $fail_submission->get_errors(), "get errors" );
//diag_dump( $errors );
is( count($errors), 1, "got expected error number" );
is_deeply( $errors, array(
        array(
            'msg' => 'Not an email',
            'question' => $contrib_question['email']->ques_uuid
        )
    ),
    "got expected error messages"
);
