#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use lib 'tests/search/models';
use AIR2::User;
use AIR2::Config;
use AIR2::CSVReader;
use AIR2::Importer::FS;
use AIR2::SrsConfirmation;
use AIR2Test::Source;
use AIR2Test::Project;
use AIR2Test::Inquiry;
use AIR2Test::Organization;
use AIR2Test::User;
use AIR2::JobQueue;
use Data::Dump qw( dump );
use Test::More tests => 59;
use Path::Class;
use JSON;
use File::Slurp;

#############################################################
## mock up inquiries and submissions

my $TEST_ORG_NAME1 = 'testorg1';
my $TEST_ORG_NAME2 = 'testorg2';
my $TEST_PROJECT   = 'ima-test-project';
my $TEST_USERNAME  = 'ima-test-user';
my $TEST_INQUIRY   = 'abcdef123456';
my $TEMP_SUBMISSION_PEN
    = dir( $ENV{TEMP_SUBMISSION_PEN}
        || '/tmp/submission-pen-' . getpwuid($<) );
my $TEST_FILE_UPLOAD
    = AIR2::Config::get_app_root->file('tests/querymaker/test-upload.jpg');

# start clean
{
    my $i = AIR2::Inquiry->new( inq_uuid => $TEST_INQUIRY )->load_speculative;
    $i->delete if $i;

    $TEMP_SUBMISSION_PEN->rmtree();
}

$TEMP_SUBMISSION_PEN->mkpath(1);

use_ok('AIR2::InquiryPublisher');
use_ok('AIR2::Reader::FS');
use_ok('AIR2::Importer::FS');

ok( my $project = AIR2Test::Project->new(
        prj_name         => $TEST_PROJECT,
        prj_display_name => $TEST_PROJECT,
    ),
    "new project"
);
ok( $project->load_or_save, "save project" );

if ( !$project->prj_uuid ) {
    die "Failed to load_or_save $TEST_PROJECT";
}

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
ok( $user->set_primary_email('i-am-user@nosuchemail.org'),
    "set user->primary_email" );
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

ok( my $inquiry1 = AIR2Test::Inquiry->new(
        inq_uuid  => 'i am a uuid',
        inq_title => 'the color QUERY  ',
    ),
    "new Inquiry"
);
ok( my $question1 = AIR2::Question->new(
        ques_value     => 'what is your email address',
        ques_type      => 'Z',
        ques_resp_type => 'E',
        ques_resp_opts =>
            encode_json( { "require" => JSON::true, "maxlen" => 128 } )
    ),
    "new Question"
);
ok( $inquiry1->add_questions($question1), "add question to Inquiry" );
ok( $inquiry1->add_projects( [$project] ), "add projects to Inquiry" );
ok( $inquiry1->add_organizations($org1), "org1 is an Owner" );
ok( $inquiry1->add_users_as_authors( [$user] ), "add author to Inquiry" );

ok( $inquiry1->load_or_save(), 'save inquiry1' );

# publish
my $inq_uuid1      = $inquiry1->inq_uuid;
my $inq_uuid1_safe = AIR2::InquiryPublisher->safe_uuid($inq_uuid1);

ok( AIR2::InquiryPublisher->publish($inq_uuid1), 'published' );

ok( my $inquiry2 = AIR2Test::Inquiry->new(
        inq_uuid  => $TEST_INQUIRY,
        inq_title => 'what color is your parachute?',
    ),
    "new Inquiry"
);

ok( my $email_question = AIR2::Question->new_from_template('email'),
    "create email question" );

ok( my $first_name_question = AIR2::Question->new_from_template('firstname'),
    "create first name question"
);

ok( my $last_name_question = AIR2::Question->new_from_template('lastname'),
    "create last name question" );

ok( my $postal_code_question = AIR2::Question->new_from_template('zip'),
    "create zip question" );

ok( my $religion_question = AIR2::Question->new_from_template('religion'),
    "create religion question" );

ok( my $income_question = AIR2::Question->new_from_template('income'),
    "create income question" );

ok( my $lang_question = AIR2::Question->new_from_template('preflang'),
    "create preflang question" );

ok( my $file_upload_question
        = AIR2::Question->new_from_template('fileupload'),
    "create fileupload question"
);

ok( my $unanswered_question = AIR2::Question->new_from_template('twitter'),
    "new unanswered question" );

ok( $inquiry2->add_questions(
        [   $email_question,
            $first_name_question,
            $last_name_question,
            $postal_code_question,
            $religion_question,
            $income_question,
            $lang_question,
            $file_upload_question,
            $unanswered_question,

            # TODO more
        ]
    ),
    "add questions to Inquiry2"
);
ok( $inquiry2->add_projects( [$project] ), "add projects to Inquiry" );
ok( $inquiry2->add_organizations($org2), "org2 is an Owner" );
ok( $inquiry2->add_users_as_authors( [$user] ), "add author to Inquiry" );
ok( $inquiry2->load_or_save(), 'save inquiry2' );

# publish
my $inq_uuid2      = $inquiry2->inq_uuid;
my $inq_uuid2_safe = AIR2::InquiryPublisher->safe_uuid($inq_uuid2);

ok( AIR2::InquiryPublisher->publish($inq_uuid2), 'published' );

# create submissions
my $srs_uuid      = '1234567890ab';
my $inquiry2_path = $TEMP_SUBMISSION_PEN->subdir($inq_uuid2_safe);
$inquiry2_path->mkpath(1);
$inquiry2_path->subdir( $srs_uuid . '.uploads' )->mkpath(1);
my $tmpfile = $inquiry2_path->subdir( $srs_uuid . '.uploads' )
    ->file( $file_upload_question->ques_uuid() . '.jpg' );
system("cp $TEST_FILE_UPLOAD $tmpfile");

my $submission1 = {
    $email_question->ques_uuid()       => 'me@pinsight.org',
    $first_name_question->ques_uuid()  => 'me',
    $last_name_question->ques_uuid() =>
        "myself \x{1F609} \x{1F338}\x{1F41D}\x{1F41E}",
    $postal_code_question->ques_uuid() => '12345',
    $religion_question->ques_uuid() =>
        'Christian Mysticism',    # should get translated
    $income_question->ques_uuid() =>
        '$100,001-$200,000',      # commas should get stripped
    $lang_question->ques_uuid()        => 'es',    # spanish
    $file_upload_question->ques_uuid() => {
        tmp_name  => "$tmpfile",
        file_ext  => 'jpg',
        orig_name => $TEST_FILE_UPLOAD->basename,
    },
    meta => {
        mtime   => 1234567890,
        referer => 'placeicamefrom.org',
        query   => $inq_uuid2_safe,
    },

    # NOTE unanswered question is missing on purpose

};

like(
    Search::Tools::UTF8::to_utf8(
        $submission1->{ $last_name_question->ques_uuid() }
    ),
    qr/[\x{10000}-\x{10ffff}]/,
    "response matches 4-byte utf8 character"
);

ok( write_file( "$inquiry2_path/$srs_uuid.json", encode_json($submission1) ),
    "write submission1 json"
);

##########################################################
##             import to tank
##########################################################

ok( my $reader = AIR2::Reader::FS->new( root => $TEMP_SUBMISSION_PEN ),
    "new FS reader" );

ok( my $importer = AIR2::Importer::FS->new(
        reader       => $reader,
        user         => $user,
        debug        => $ENV{AIR2_DEBUG},    #1,
        email_notify => 'pijdev@mpr.org',
    ),
    "new importer"
);

ok( $importer->run(), "run importer" );
ok( my $report = $importer->report, "get report" );
diag( dump $report );

is( $importer->errored, 0, "no errors" );
ok( my $tanks = $importer->get_tanks(), "get_tanks" );
is( scalar(@$tanks), 1, "got 1 tanks for 1 submission to 1 query" );

my %query_uuids;
for my $t (@$tanks) {

    #diag( $t->tank_name );
    $query_uuids{ $t->tank_xuuid } = 1;
}

##########################################################
##             discriminator
##########################################################

for my $t (@$tanks) {

    #    diag(
    #        sprintf(
    #            "before job run, tank id %d has status %s errors '%s'",
    #            $t->tank_id, $t->tank_status, $t->tank_errors
    #        )
    #    );
    my $job
        = AIR2::JobQueue->new(
        jq_job => 'PERL AIR2_ROOT/bin/run-discriminator ' . $t->tank_id, );
    ok( $job->run(), "run discriminator for tank " . $t->tank_id );
    if ( $job->jq_error_msg() ) {
        diag(
            sprintf(
                "FAIL: job id %s with error msg: %s\n",
                $job->jq_id, $job->jq_error_msg
            )
        );
    }
    $t->load();

    my $tank_meta = decode_json( $t->tank_meta );

    #diag( dump $tank_meta );
    #diag( "tank_errors: " . $t->tank_errors );
    #diag( dump( $t->flatten( max_depth => 0 ) ) );

    for my $ts ( @{ $t->sources } ) {

        #diag( dump( $ts->flatten( max_depth => 0 ) ) );
    }
}

##########################################################
##             post-discriminator
##########################################################

# check response_sets
ok( my $new_source
        = AIR2Test::Source->new( src_username => 'me@pinsight.org' )->load(),
    "get new source"
);
is( $new_source->has_related('response_sets'),
    1, "1 new response imported for new source" );

my $has_media = 0;
my $has_null_unanswered_question;
for my $srs ( @{ $new_source->response_sets } ) {
    for my $sr ( @{ $srs->responses } ) {
        diag(
            sprintf( "%s => %s",
                $sr->question->ques_uuid,
                ( $sr->sr_orig_value || '(NULL)' ) )
        );
        if ( $sr->sr_media_asset_flag ) {
            $has_media = $sr->sr_orig_value;
        }
        if ( $sr->sr_ques_id == $unanswered_question->ques_id
            and !defined $sr->sr_orig_value )
        {
            $has_null_unanswered_question = 1;
        }
    }
}
ok( $has_media, "response set has media flag set" );
is( $has_media,
    sprintf(
        '%s/%s/%s.jpg', $org2->org_name, $inquiry2->inq_uuid, $srs_uuid
    ),
    "media response has correct path name"
);
ok( $has_null_unanswered_question,
    "unanswered question generates NULL sr_response" );

#diag( dump( $air_source1->flatten( force_load => 1, max_depth => 2 ) ) );

# check facts
is( $new_source->get_religion(),
    "Christian (non-specified)",
    "fact translation happened"
);
is( $new_source->get_income(),
    '$100001-$200000', "trac 1638 no commas in income" );

# check actvitiies
for my $sact ( @{ $new_source->activities } ) {

    #diag( $sact->sact_desc );
    if ( $sact->sact_actm_id == $AIR2::ActivityMaster::QUERY_RESPONSE ) {
        is( $sact->sact_desc, "{SRC} responded to {XID}", "got sact" );
    }
}

is( $new_source->get_pref_lang,
    'es_US', "preferred language mapped to preferences" );

##########################################################
##             confirmation message
##########################################################

# confirmation message
ok( my $confirmation = AIR2::SrsConfirmation->new( dry_run => 1 ),
    "new AIR2::SrsConfirmation" );
ok( my $confirmed = $confirmation->send($srs_uuid), "confirmation->send" );
is_deeply(
    $confirmed->{template_vars}->{source},
    {   email  => $new_source->get_primary_email->sem_email,
        name   => $new_source->get_first_last_name,
        src_id => $new_source->src_id,
    },
    "confirmation template_vars source"
);
is( $confirmed->{template_vars}->{locale},
    $new_source->get_pref_lang,
    "pref_lang used in confirmation email"
);

##########################################################
##             clean up
##########################################################
diag("cleaning up");

for my $t (@$tanks) {
    for my $ts ( @{ $t->sources } ) {
        $ts->delete( cascade => 1 );
    }
    $t->delete( cascade => 1 );
}

# normal DESTROY would catch this, but we want to nuke it before its related Project(s)
$org1->delete();
$org2->delete();

$tmpfile->remove();
