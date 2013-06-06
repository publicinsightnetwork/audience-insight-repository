#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 42;
use LWP::UserAgent;
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use lib "$FindBin::Bin/../../tests/search/models";
use AIR2::Config;
use AIR2::Question;
use AIR2Test::Inquiry;
use AIR2Test::User;
use AIR2Test::Project;
use AIR2Test::Organization;
use JSON;
use Search::Tools::UTF8;
use Data::Dump qw( dump );

my $path_to_file
    = AIR2::Config::get_app_root->file('tests/querymaker/test-upload.jpg');
my $url     = AIR2::Config::get_constant('AIR2_BASE_URL') . 'submit.php';
my $browser = LWP::UserAgent->new();

# debugging
#$browser->add_handler( "request_send",  sub { shift->dump; return } );
#$browser->add_handler( "response_done", sub { shift->dump; return } );

# POST only allowed
ok( my $resp = $browser->get( $url . '?query=ignored' ), "GET $url" );

#diag( dump($resp) );
is( $resp->code, 405, "GET not allowed" );

# missing query uuid
ok( $resp = $browser->post( $url, [ foo => 'bar' ] ),
    "POST with missing query param" );
is( $resp->code, 400, "missing query uuid gives 400 response" );

# params with multiple values respected
ok( $resp = $browser->post(
        $url . '?query=ignored',
        [   'DEBUG_MODE' => 'params',
            'foo[]'      => 'bar',
            'foo[]'      => 'baz'
        ]
    ),
    "POST multiple param values"
);
ok( my $json = decode_json( $resp->content ), "decode JSON response" );
is_deeply(
    $json,
    { DEBUG_MODE => 'params', foo => [ 'bar', 'baz' ] },
    "params with multiple values preserved"
);

#diag( dump($resp) );

###################################################
# test full cycle with mock query
###################################################
# set up test data
my $TEST_ORG_NAME1 = 'testorg1';
my $TEST_ORG_NAME2 = 'testorg2';
my $TEST_PROJECT   = 'ima-test-project';
my $TEST_USERNAME  = 'ima-test-user';

use_ok('AIR2::InquiryPublisher');

ok( my $project = AIR2Test::Project->new(
        prj_name         => $TEST_PROJECT,
        prj_display_name => $TEST_PROJECT,
    ),
    "new project"
);
ok( $project->load_or_save, "save project" );
ok( my $org1 = AIR2Test::Organization->new(
        org_default_prj_id => $project->prj_id,
        org_name           => $TEST_ORG_NAME1,
        org_display_name   => uc($TEST_ORG_NAME1),
        )->load_or_save(),
    "create test org1"
);
ok( my $org2 = AIR2Test::Organization->new(
        org_default_prj_id => $project->prj_id,
        org_name           => $TEST_ORG_NAME2,
        org_display_name   => uc($TEST_ORG_NAME2),
        )->load_or_save(),
    "create test org2"
);
ok( my $user = AIR2Test::User->new(
        user_username   => $TEST_USERNAME,
        user_first_name => 'First',
        user_last_name  => 'Last',
    ),
    "create test user"
);
ok( $user->load_or_save(), "save test user" );

# must do this AFTER we set default_prj_id above
ok( $project->add_project_orgs(
        [   {   porg_org_id          => $org1->org_id,
                porg_contact_user_id => $user->user_id,
            },
            {   porg_org_id          => $org2->org_id,
                porg_contact_user_id => $user->user_id,
            }
        ]
    ),
    "add orgs to project"
);
ok( $project->save(), "write ProjectOrgs" );

ok( my $inquiry = AIR2Test::Inquiry->new(
        inq_uuid  => 'i am a uuid',
        inq_title => 'the color QUERY  ',
    ),
    "new Inquiry"
);
ok( my $question = AIR2::Question->new(
        ques_value     => 'what is your email address',
        ques_type      => 'Z',
        ques_resp_type => 'E',
        ques_resp_opts =>
            encode_json( { "require" => JSON::true, "maxlen" => 128 } )
    ),
    "new Question"
);
ok( my $file_question = AIR2::Question->new(
        ques_value     => 'let us see your smiling face! upload a photo',
        ques_type      => 'F',
        ques_resp_type => 'S',
    ),
    "new File Upload Question"
);
ok( my $text_question = AIR2::Question->new(
        ques_value     => 'what is your favorite color?',
        ques_type      => 'T',
        ques_resp_type => 'S',
    ),
    "new Text question"
);
ok( my $utf8_question
        = AIR2::Question->new_from_template( 'gender', 'es_US' ),
    "utf8 question"
);
ok( $inquiry->add_questions($question),      "add question to Inquiry" );
ok( $inquiry->add_questions($file_question), "add file_question to Inquiry" );
ok( $inquiry->add_questions($text_question), "add text_question to Inquiry" );
ok( $inquiry->add_questions($utf8_question), "add utf8_question to Inquiry" );
ok( $inquiry->add_projects( [$project] ), "add projects to Inquiry" );
ok( $inquiry->add_organizations($org1), "org1 is an Owner" );

ok( $inquiry->load_or_save(), 'get test data' );

# publish, check artifacts
my $inq_uuid      = $inquiry->inq_uuid;
my $inq_uuid_safe = AIR2::InquiryPublisher->safe_uuid($inq_uuid);

ok( AIR2::InquiryPublisher->publish($inq_uuid), 'published' );

my $output_dir  = AIR2::Config::get_app_root()->subdir('public_html/querys');
my $output_json = $output_dir->file( $inq_uuid_safe . '.json' );
my $submission_pen
    = AIR2::Config::get_submission_pen()->subdir($inq_uuid_safe);

#diag( dump decode_json( $output_json->slurp ) );

# send bad submission: non-existent question
ok( $resp = $browser->post(
        $url . '?query=' . $inq_uuid_safe,
        { 'nosuchquestion' => 'i am the walrus' },
        'X-Requested-With' => 'xmlhttprequest',      # mimic ajax
        'Accept'           => 'application/json',    # demand response format
    ),
    "POST with non-existent question"
);

#diag( dump $resp );
my $resp_decoded = decode_json( $resp->content );

#diag( dump $resp_decoded );

is( $resp->code, 400, "bad question gets 400 Bad Request response" );
is_deeply(
    {   errors =>
            [ { msg => 'Invalid question', question => 'nosuchquestion' }, ],
        success => JSON::false
    },
    $resp_decoded,
    "got json error response"
);

# send bad submission: validation fail
ok( $resp = $browser->post(
        $url . '?query=' . $inq_uuid_safe,
        { $question->ques_uuid => 'i am invalid content',
        },
        'X-Requested-With' => 'xmlhttprequest',      # mimic ajax
        'Accept'           => 'application/json',    # demand response format
    ),
    "response invalid"
);
is( $resp->code, 400, "invalid content gets 400 Bad Request response" );

########################################################################
#    we expect success
########################################################################

# send ok submission
my $ok_submission = [
    $question->ques_uuid()             => 'foo@nosuchemail.org',
    $text_question->ques_uuid() . '[]' => 'blue',
    $text_question->ques_uuid() . '[]' => 'no wait! red!',
    $utf8_question->ques_uuid()        => 'mamá',
    $file_question->ques_uuid()        => ["$path_to_file"],
];
ok( $resp = $browser->post(
        $url . '?query=' . $inq_uuid_safe,
        [ @$ok_submission, 'X-PIN-referer' => 'placeicamefrom.org', ],
        'X-Requested-With' => 'xmlhttprequest',      # mimic ajax
        'Content_Type'     => 'form-data',
        'Accept'           => 'application/json',    # demand response format
    ),
    "POST valid submission"
);
is( $resp->code, 202, "valid submission gets 202 Accepted response" );
ok( $json = decode_json( $resp->content ), "202 response is json" );

#diag( dump $json );

# find the temp submission.json file
my $submission_file = $submission_pen->file( $json->{uuid} . '.json' );
ok( -s $submission_file, "submission temp file created" );

#diag( $submission_file->slurp );
$json = decode_json( $submission_file->slurp );

#diag( dump $json );
my $meta = delete $json->{meta};

is_deeply(
    $json,
    {   $text_question->ques_uuid() => [ 'blue', 'no wait! red!' ],
        $question->ques_uuid()      => 'foo@nosuchemail.org',
        $utf8_question->ques_uuid() => to_utf8('mamá'),
        $file_question->ques_uuid() => {
            orig_name => 'test-upload.jpg',

            # cheat
            tmp_name => $json->{ $file_question->ques_uuid() }->{tmp_name},

            file_ext => 'jpg',
        },
    },
    "submission round-trip"
);
is( $meta->{referer}, 'placeicamefrom.org', "got referer" );
ok( $meta->{mtime}, "got mtime" );

# clean up
ok( $submission_file->remove(), "remove temp submission file" );
