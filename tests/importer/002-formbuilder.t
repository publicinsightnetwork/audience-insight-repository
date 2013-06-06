#!/usr/bin/env perl
use strict;
use warnings;

# force mysql connection
BEGIN { $ENV{FB_TYPE} = 'formbuilder'; }

use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use lib 'tests/search/models';
use AIR2::User;
use AIR2::Config;
use lib AIR2::Config::get_app_root() . '/lib/formbuilder';
use Formbuilder::Ask;
use Formbuilder::Project;
use AIR2Test::Source;
use AIR2Test::Project;
use AIR2Test::Inquiry;
use AIR2Test::Organization;
use AIR2::Importer::Formbuilder;
use AIR2::JobQueue;
use JSON;
use Data::Dump qw( dump );

use Test::More tests => 66;

my $EMAIL_NOTIFY = $ENV{FB_NOTIFY} || $ENV{USER} . '@mpr.org';
my $DEBUG        = $ENV{FB_DEBUG}  || 0;

$Rose::DB::Object::Manager::Debug = $DEBUG;
$Rose::DB::Object::Debug          = $DEBUG;

# clean up from any previous run
# must cascade manually since oracle has no CASCADE on delete defined.
my @fb_proj_uuids = (
    'air2-test-import', 'air2-test-import-reassignment',
    'air2-test-import1'
);

my $oldorg
    = AIR2::Organization->new( org_name => 'ima-org' )->load_speculative;
if ( $oldorg and $oldorg->org_id ) {
    $oldorg->delete( cascade => 1 );
}
for my $uuid (@fb_proj_uuids) {
    if ( my $oldproj
        = Formbuilder::Project->new( proj_code => $uuid, )->load_speculative )
    {
        for my $ask ( @{ $oldproj->asks } ) {
            for my $q ( @{ $ask->ask_questions } ) {
                $q->delete( cascade => 1 );
            }
            for my $car ( @{ $ask->ctb_ask_responses } ) {
                $car->delete( cascade => 1 );
            }
            $ask->delete( cascade => 1 );
        }
        $oldproj->delete( cascade => 1 );  # should clean up all children too.
    }

    # also look for AIR projects
    if ( my $oldprj
        = AIR2::Project->new( prj_name => $uuid, )->load_speculative )
    {
        $oldprj->delete( cascade => 1 );
    }
}

my %stale_tanks;
for my $uuid (
    qw( ima-fb-ask ima-fb-ask1 ima-fb-ask2 ima-fb-ask3 ima-fb-ask4 ))
{
    if ( my $oldair2inq
        = AIR2::Inquiry->new( inq_uuid => $uuid )->load_speculative() )
    {
        for my $trs ( @{ $oldair2inq->tank_response_sets } ) {
            my $tk = $trs->tanksource->tank;
            $stale_tanks{ $tk->tank_id } = $tk;
            $trs->delete( cascade => 1 );
        }
        $oldair2inq->delete( cascade => 1 );
    }
}

# cleanup stale tanks
for my $tankid ( keys %stale_tanks ) {
    $stale_tanks{$tankid}->delete( cascade => 1 );
}

# no way in normal (non-dbconv) usage to map a Formbuilder project to an AIR2 Org
# because proj_dgrp_id is meaningless to AIR2.
# instead we assume that all AIR2 projects are assigned to an Org by some
# manual intervention, which we mimic here.
my $air2_org = AIR2Test::Organization->new(
    org_name           => 'ima-org',
    org_display_name   => 'ima-displayed org',
    org_default_prj_id => 1,                     # avoid chicken-and-egg
)->load_or_save();

##############################################################
##                        project
##############################################################

# "touch" a Project so we can be sure to find it
my $fb_project = Formbuilder::Project->new(
    proj_name             => 'air2-test-import',
    proj_desc             => 'testing formbuilder import',
    proj_pij_enabled      => 1,
    proj_pij_dgrp_id      => 1,                               # APMG
    proj_last_modify_time => time(),
    proj_allow_rss        => 1,
    proj_code             => 'air2-test-import',
    proj_logo_url         => 'http://nosuchemail.org/logo',
    proj_url              => 'http://nosuchemail.org/',
    proj_status           => 'P',                             # published
);
$fb_project->save();

my $reader = Formbuilder::Project->fetch_all_iterator(

    # recently modified, not in Draft status

    query => [
        proj_last_modify_time => { ge => ( time() - 3 ) },
        proj_pij_enabled      => 1,
        '!proj_status'        => 'D'
    ]
);

my $user = AIR2::User->new( user_id => 1 )->load;

use_ok('AIR2::Importer::Formbuilder');
ok( my $importer = AIR2::Importer::Formbuilder->new(
        debug        => $DEBUG,
        atomic       => 1,
        max_errors   => 1,
        reader       => $reader,
        user         => $user,
        email_notify => $EMAIL_NOTIFY,
    ),
    "new Importer"
);
ok( $importer->run(), "run()" );
is( $importer->completed->{projects}, 1, "1 completely imported" );
ok( my $report = $importer->report, "get report" );
ok( !$importer->errored, "no errors" );

# we use AIR2Test to automatically delete from air2 db when object destroyed
ok( my $air2_proj
        = AIR2Test::Project->new( prj_name => $fb_project->proj_code )->load,
    "AIR2 project created"
);

# associate with org manually for later tests
$air2_org->org_default_prj_id( $air2_proj->prj_id );
$air2_org->save();
$air2_proj->project_orgs(
    {   porg_org_id          => $air2_org->org_id,
        porg_contact_user_id => $user->user_id
    }
);
$air2_proj->save();

##########################################################
##                        ask
##########################################################

my $fb_ask0 = Formbuilder::Ask->new(
    ask_code            => 'ima-fb-ask',
    ask_title           => 'ima-fb-ask-test-title',
    ask_external_title  => 'ima-fb-ask-test-ext-title',
    project             => $fb_project,
    ask_status          => 'P',
    ask_disp_ctb_fields => [
        {   adcf_shown    => 1,
            adcf_object   => { dcf_name => 'ctb_email', },
            adcf_disp_seq => 1,
        },
        {   adcf_shown    => 1,
            adcf_object   => { dcf_name => 'ctb_first_name', },
            adcf_disp_seq => 2,
        },
        {   adcf_shown    => 1,
            adcf_object   => { dcf_name => 'ctb_last_name', },
            adcf_disp_seq => 3,
        },
    ],

    # TODO mapping?
);
$fb_ask0->save;

my $ask_reader = Formbuilder::Ask->fetch_all_iterator(
    require_objects => ['project'],

    # recently modified not in Draft
    query => [
        ask_last_modify_time       => { ge => ( time() - 3 ) },
        'project.proj_pij_enabled' => 1,
        '!ask_status'              => 'D',
    ]
);

ok( $importer = AIR2::Importer::Formbuilder->new(
        debug        => $DEBUG,
        atomic       => 1,
        max_errors   => 1,
        reader       => $ask_reader,
        user         => $user,
        email_notify => $EMAIL_NOTIFY,
    ),
    "new ask importer"
);
ok( $importer->run(), "run ask importer" );
is( $importer->completed->{asks}, 1, "1 ask completed" );

#diag( $importer->report );
ok( !$importer->errored, "no errored" );

ok( my $air2_ask = AIR2Test::Inquiry->new( inq_uuid => 'ima-fb-ask' )->load,
    "AIR2 Inquiry created" );
is( $air2_ask->projects->[0]->prj_name,
    $air2_proj->prj_name, "project associated with Ask on import" );
is( $air2_ask->projects->[0]->prj_id,
    $air2_proj->prj_id, "prj_id values match" );

#################################################################
# reassign ask in FB and test whether AIR detects that (#2286)

my $fb_project_new = Formbuilder::Project->new(
    proj_name             => 'air2-test-import-reassignment',
    proj_desc             => 'testing formbuilder import reassignment',
    proj_pij_enabled      => 1,
    proj_pij_dgrp_id      => 1,                                         # APMG
    proj_last_modify_time => time(),
    proj_allow_rss        => 1,
    proj_code             => 'air2-test-import-reassignment',
    proj_logo_url         => 'http://nosuchemail.org/logo-new',
    proj_url              => 'http://nosuchemail.org/new',
    proj_status => 'P',    # published
);
$fb_project_new->save();
$fb_ask0->project($fb_project_new);
$fb_ask0->save();

$ask_reader = Formbuilder::Ask->fetch_all_iterator(
    require_objects => ['project'],

    # recently modified not in Draft
    query => [
        ask_last_modify_time       => { ge => ( time() - 3 ) },
        'project.proj_pij_enabled' => 1,
        '!ask_status'              => 'D',
    ]
);

ok( $importer = AIR2::Importer::Formbuilder->new(
        debug        => $DEBUG,
        atomic       => 1,
        max_errors   => 1,
        reader       => $ask_reader,
        user         => $user,
        email_notify => $EMAIL_NOTIFY,
    ),
    "new ask importer"
);
ok( $importer->run(), "run ask importer" );
is( $importer->completed->{asks}, 1, "1 ask completed" );

#diag( $importer->report );
ok( !$importer->errored, "no errored" );
$air2_ask->forget_related('projects');
$air2_ask->load();
is( $air2_ask->projects->[0]->prj_name,
    $fb_project_new->proj_name, "air2 inquiry project reassignment" );

# now set it back for the rest of the tests
$fb_ask0->project($fb_project);
$fb_ask0->save();
$ask_reader = Formbuilder::Ask->fetch_all_iterator(
    require_objects => ['project'],

    # recently modified not in Draft
    query => [
        ask_last_modify_time       => { ge => ( time() - 3 ) },
        'project.proj_pij_enabled' => 1,
        '!ask_status'              => 'D',
    ]
);

ok( $importer = AIR2::Importer::Formbuilder->new(
        debug        => $DEBUG,
        atomic       => 1,
        max_errors   => 1,
        reader       => $ask_reader,
        user         => $user,
        email_notify => $EMAIL_NOTIFY,
    ),
    "new ask importer"
);
ok( $importer->run(), "run ask importer" );
is( $importer->completed->{asks}, 1, "1 ask completed" );

##########################################################
##             car (response_sets)
##########################################################

# create multiple responses, in different asks to exercise org/tank record placement,
# and in different projects to test mapping logic

########################
## asks and projects
my $fb_project1 = Formbuilder::Project->new(
    proj_name        => 'air2-test-import1',
    proj_desc        => 'testing formbuilder import1',
    proj_pij_enabled => 1,
    proj_pij_dgrp_id      => 4,        # NHPR, but useless for AIR2 import
    proj_last_modify_time => time(),
    proj_allow_rss        => 1,
    proj_code     => 'air2-test-import1',
    proj_logo_url => 'http://nosuchemail.org/logo1',
    proj_url      => 'http://nosuchemail.org/1',
    proj_status   => 'P',                              # published
);
$fb_project1->save();
my $fb_ask1 = Formbuilder::Ask->new(
    ask_code            => 'ima-fb-ask1',
    ask_title           => 'ima-fb-ask-test-title1',
    ask_external_title  => 'ima-fb-ask-test-ext-title1',
    project             => $fb_project,
    ask_status          => 'P',
    ask_disp_ctb_fields => [
        {   adcf_shown    => 1,
            adcf_object   => { dcf_name => 'ctb_email', },
            adcf_disp_seq => 1,
        },
        {   adcf_shown    => 1,
            adcf_object   => { dcf_name => 'ctb_first_name', },
            adcf_disp_seq => 2,
        },
        {   adcf_shown    => 1,
            adcf_object   => { dcf_name => 'ctb_last_name', },
            adcf_disp_seq => 3,
        },
    ],

);
$fb_ask1->save;
my $fb_ask2 = Formbuilder::Ask->new(
    ask_code            => 'ima-fb-ask2',
    ask_title           => 'ima-fb-ask-test-title2',
    ask_external_title  => 'ima-fb-ask-test-ext-title2',
    project             => $fb_project1,
    ask_status          => 'P',
    ask_disp_ctb_fields => [
        {   adcf_shown    => 1,
            adcf_object   => { dcf_name => 'ctb_email', },
            adcf_disp_seq => 1,
        },
        {   adcf_shown    => 1,
            adcf_object   => { dcf_name => 'ctb_first_name', },
            adcf_disp_seq => 2,
        },
        {   adcf_shown    => 1,
            adcf_object   => { dcf_name => 'ctb_last_name', },
            adcf_disp_seq => 3,
        },
    ],

);
$fb_ask2->save;
my $fb_ask3 = Formbuilder::Ask->new(
    ask_code            => 'ima-fb-ask3',
    ask_title           => 'ima-fb-ask-test-title3',
    ask_external_title  => 'ima-fb-ask-test-ext-title3',
    project             => $fb_project1,
    ask_status          => 'P',
    ask_disp_ctb_fields => [
        {   adcf_shown    => 1,
            adcf_object   => { dcf_name => 'ctb_email', },
            adcf_disp_seq => 1,
        },
        {   adcf_shown    => 1,
            adcf_object   => { dcf_name => 'ctb_first_name', },
            adcf_disp_seq => 2,
        },
        {   adcf_shown    => 1,
            adcf_object   => { dcf_name => 'ctb_last_name', },
            adcf_disp_seq => 3,
        },
    ],

);
$fb_ask3->save;
my $fb_ask4 = Formbuilder::Ask->new(
    ask_code            => 'ima-fb-ask4',
    ask_title           => 'ima-fb-ask-test-title4',
    ask_external_title  => 'ima-fb-ask-test-ext-title4',
    project             => $fb_project1,
    ask_status          => 'P',
    ask_disp_ctb_fields => [
        {   adcf_shown    => 1,
            adcf_object   => { dcf_name => 'ctb_email', },
            adcf_disp_seq => 1,
        },
        {   adcf_shown    => 1,
            adcf_object   => { dcf_name => 'ctb_first_name', },
            adcf_disp_seq => 2,
        },
        {   adcf_shown    => 1,
            adcf_object   => { dcf_name => 'ctb_last_name', },
            adcf_disp_seq => 3,
        },
    ],

);
$fb_ask4->save;

#####################
## questions

# 8 types, so one of each, for each ask and each template
my @questions = ();
for my $i ( 1 .. 8 ) {
    my $ask_question1 = Formbuilder::AskQuestion->new(
        askq_qtyp_id => $i,
        askq_ask_id  => $fb_ask0->ask_id,
        askq_qt_id   => 1,
        askq_text    => 'what is your gender?',
    )->save();
    my $ask_question2 = Formbuilder::AskQuestion->new(
        askq_qtyp_id => $i,
        askq_ask_id  => $fb_ask1->ask_id,
        askq_qt_id   => 2,
        askq_text    => 'what is your income?',
    )->save();
    my $ask_question3 = Formbuilder::AskQuestion->new(
        askq_qtyp_id => $i,
        askq_ask_id  => $fb_ask2->ask_id,
        askq_qt_id   => 3,
        askq_text    => 'what is your political affiliation?',
    )->save();
    my $ask_question4 = Formbuilder::AskQuestion->new(
        askq_qtyp_id => $i,
        askq_ask_id  => $fb_ask3->ask_id,
        askq_qt_id   => 7,
        askq_text    => 'what is your ethnicity?',
    )->save();
    push @questions, $ask_question1, $ask_question2, $ask_question3,
        $ask_question4;
}

# rest of templated AIR-specific questions go on one ask
my @air_questions;
my %air_values;
my $photo_loc_askq = Formbuilder::AskQuestion->new(
    askq_qtyp_id => 1,
    askq_ask_id  => $fb_ask0->ask_id,
    askq_qt_id   => 8,
    askq_text    => 'upload your photo',
)->save();
push @air_questions, $photo_loc_askq;
$air_values{8} = 'path/to/my/photo';

my $occupation_askq = Formbuilder::AskQuestion->new(
    askq_qtyp_id => 1,
    askq_ask_id  => $fb_ask0->ask_id,
    askq_qt_id   => 14,
    askq_text    => 'what is your occupation?',
)->save();
push @air_questions, $occupation_askq;
$air_values{14} = 'wrestler';

my $edu_level_askq = Formbuilder::AskQuestion->new(
    askq_qtyp_id => 1,
    askq_ask_id  => $fb_ask0->ask_id,
    askq_qt_id   => 21,
    askq_text    => 'what is your education level?',
)->save();
push @air_questions, $edu_level_askq;
$air_values{21} = 'i got my education!';

my $employer_askq = Formbuilder::AskQuestion->new(
    askq_qtyp_id => 1,
    askq_ask_id  => $fb_ask0->ask_id,
    askq_qt_id   => 42,
    askq_text    => 'who is your employer?',
)->save();
push @air_questions, $employer_askq;
$air_values{42} = '3 ring circus';

my $job_title_askq = Formbuilder::AskQuestion->new(
    askq_qtyp_id => 1,
    askq_ask_id  => $fb_ask0->ask_id,
    askq_qt_id   => 43,
    askq_text    => 'what is your job title?',
)->save();
push @air_questions, $job_title_askq;
$air_values{43} = 'wrangler';

my $pol_office_askq = Formbuilder::AskQuestion->new(
    askq_qtyp_id => 1,
    askq_ask_id  => $fb_ask0->ask_id,
    askq_qt_id   => 44,
    askq_text    => 'political offices?',
)->save();
push @air_questions, $pol_office_askq;
$air_values{44} = 'president';

my $orgs_askq = Formbuilder::AskQuestion->new(
    askq_qtyp_id => 1,
    askq_ask_id  => $fb_ask0->ask_id,
    askq_qt_id   => 45,
    askq_text    => 'organizations?',
)->save();
push @air_questions, $orgs_askq;
$air_values{45} = 'NRA';

my $religion_askq = Formbuilder::AskQuestion->new(
    askq_qtyp_id => 1,
    askq_ask_id  => $fb_ask0->ask_id,
    askq_qt_id   => 62,
    askq_text    => 'religion?',
)->save();
push @air_questions, $religion_askq;
$air_values{62} = 'Christian Mysticism';    # should get translated

my $birth_year_askq = Formbuilder::AskQuestion->new(
    askq_qtyp_id => 1,
    askq_ask_id  => $fb_ask0->ask_id,
    askq_qt_id   => 81,
    askq_text    => 'what year were you born?',
)->save();
push @air_questions, $birth_year_askq;
$air_values{81} = '1955';

my $pref_lang_askq = Formbuilder::AskQuestion->new(
    askq_qtyp_id => 1,
    askq_ask_id  => $fb_ask0->ask_id,
    askq_qt_id   => 101,
    askq_text    => 'what is your preferred language?',
)->save();
push @air_questions, $pref_lang_askq;
$air_values{101} = 'es';

my $permission_to_publish_askq = Formbuilder::AskQuestion->new(
    askq_qtyp_id => 4,
    askq_ask_id  => $fb_ask0->ask_id,
    askq_qt_id   => 12,
    askq_text    => 'may we share your insights?',
)->save();
push @air_questions, $permission_to_publish_askq;
$air_values{12} = 'yes';

push @questions, @air_questions;

#########################################
## contributors and responses

my $air_source0 = AIR2Test::Source->new(
    src_username   => 'FB_TEST_USER0',
    src_first_name => 'TEST',
    src_last_name  => 'SOURCE',
    src_status     => 'A',
    emails         => [
        {   sem_primary_flag => 1,
            sem_email        => 'FB_TEST_USER0@nosuchemail.org',
        }
    ],
)->load_or_save();

my $air_source1 = AIR2Test::Source->new(
    src_username   => 'FB_TEST_USER1',
    src_first_name => 'TEST',
    src_last_name  => 'SOURCE',
    src_status     => 'A',
    emails         => [
        {   sem_primary_flag => 1,
            sem_email        => 'FB_TEST_USER1@nosuchemail.org',
        }
    ],
)->load_or_save();

my $ctb_in_air_conflict = Formbuilder::Contributor->new(
    ctb_email      => $air_source0->get_primary_email()->sem_email,
    ctb_first_name => 'NOT_TEST',
    ctb_last_name  => 'NOT_SOURCE',
)->load_or_save();

my $ctb_in_air_ok = Formbuilder::Contributor->new(
    ctb_email      => $air_source1->get_primary_email()->sem_email,
    ctb_first_name => $air_source1->src_first_name,
    ctb_last_name  => $air_source1->src_last_name,
)->load_or_save();

my $ctb_new = Formbuilder::Contributor->new(
    ctb_email      => 'i-do-not-yet-exist@nosuchemail-addr.foo',
    ctb_first_name => 'IMA',
    ctb_last_name  => 'SOURCE',
)->load_or_save();

my $ctb_min_fields = Formbuilder::Contributor->new(
    ctb_email      => 'i-do-not-yet-exist2@nosuchemail-addr.foo',
    ctb_first_name => 'IMA',
    ctb_last_name  => 'SOURCE',
    ctb_zipcode    => '55101',
)->load_or_save();

my $car0 = Formbuilder::CtbAskResponse->new(
    car_ctb_id => $ctb_in_air_ok->ctb_id,
    car_ask_id => $fb_ask0->ask_id,
)->load_or_save();
my $car1 = Formbuilder::CtbAskResponse->new(
    car_ctb_id => $ctb_in_air_conflict->ctb_id,
    car_ask_id => $fb_ask1->ask_id,
)->load_or_save();
my $car2 = Formbuilder::CtbAskResponse->new(
    car_ctb_id => $ctb_in_air_ok->ctb_id,
    car_ask_id => $fb_ask2->ask_id,
)->load_or_save();
my $car3 = Formbuilder::CtbAskResponse->new(
    car_ctb_id => $ctb_new->ctb_id,
    car_ask_id => $fb_ask3->ask_id,
)->load_or_save();
my $car4 = Formbuilder::CtbAskResponse->new(
    car_ctb_id => $ctb_min_fields->ctb_id,
    car_ask_id => $fb_ask0->ask_id,
)->load_or_save();

for my $airq (@air_questions) {
    $car0->add_ctb_ask_response_dtls(
        [   {   card_askq_id => $airq->askq_id,
                card_value   => $air_values{ $airq->askq_qt_id },
            }
        ]
    );
}
$car0->add_ctb_ask_response_dtls(
    [   {   card_askq_id => $questions[0]->askq_id,
            card_value   => 'hear me roar',
        },
        {   card_askq_id => $questions[1]->askq_id,
            card_value   => '$100,001-$200,000',      # see #1638 re commas
        },
    ]
);
$car0->save();

$car1->add_ctb_ask_response_dtls(
    [   {   card_askq_id => $questions[1]->askq_id,
            card_value   => '$100,001-$200,000',      # see #1638 re commas
        },
        {   card_askq_id => $questions[10]->askq_id,    # 1+9
            card_value   => 'i am the walrus',
        }
    ]
);
$car1->save();
$car2->add_ctb_ask_response_dtls(
    [   {   card_askq_id => $questions[1]->askq_id,     # with commas
            card_value   => '$100,001-$200,000',
        },
        {   card_askq_id => $questions[11]->askq_id,    # 2+9
            card_value   => 'you are the eggman',
        }
    ]
);
$car2->save();
$car3->add_ctb_ask_response_dtls(
    [   {   card_askq_id => $questions[1]->askq_id,
            card_value   => '$100,001-$200,000',      # with commas, old style
        },
        {   card_askq_id => $questions[12]->askq_id,    # 3+9
            card_value   => 'out of my mind',
        }
    ]
);
$car3->save();

my $empty_car = Formbuilder::CtbAskResponse->new(
    car_ctb_id => $ctb_in_air_ok->ctb_id,
    car_ask_id => $fb_ask0->ask_id,
)->save();
$empty_car->add_ctb_ask_response_dtls(
    [   {   card_askq_id => $questions[12]->askq_id,
            card_value   => undef,
        },
        {   card_askq_id => $questions[1]->askq_id,
            card_value   => '',
        }
    ]
);
$empty_car->save;

##########################################################
##        run import with failed transaction
##########################################################

my $car_reader_will_fail = Formbuilder::CtbAskResponse->fetch_all_iterator(
    require_objects => ['ask.project'],
    query           => [
        car_last_modify_time           => { ge => ( time() - 10 ) },
        'ask.project.proj_pij_enabled' => 1,
        car_air_export_status =>
            $Formbuilder::CtbAskResponse::CAR_AIR_EXPORT_NO,
    ]
);

ok( my $car_importer_will_fail = AIR2::Importer::Formbuilder->new(
        debug            => $DEBUG,
        atomic           => 1,
        max_errors       => 1,
        reader           => $car_reader_will_fail,
        user             => $user,
        default_org      => $air2_org,
        email_notify     => $EMAIL_NOTIFY,
        test_transaction => 1,
    ),
    "new CAR Importer"
);
eval { $car_importer_will_fail->run(); };

#diag($@);
like( "$@", qr/test rollback/, "car_importer_will_fail throw exception" );
is( $car_importer_will_fail->completed->{cars},
    undef, "car_importer_will_fail shows 0 imported" );
$car2->db->rollback;    # must do this manually since we croaked internally.
$car2->load();          # reload
is( $car2->car_air_export_status,
    $Formbuilder::CtbAskResponse::CAR_AIR_EXPORT_NO,
    "car air_export_status still==new"
);

##########################################################
##             run import
##########################################################

my $car_reader = Formbuilder::CtbAskResponse->fetch_all_iterator(
    query => [
        car_last_modify_time => { ge => ( time() - 10 ) },
        car_air_export_status =>
            $Formbuilder::CtbAskResponse::CAR_AIR_EXPORT_NO,
    ]
);

ok( my $car_importer = AIR2::Importer::Formbuilder->new(
        debug        => $DEBUG,
        atomic       => 1,
        max_errors   => 1,
        reader       => $car_reader,
        user         => $user,
        default_org  => $air2_org,
        email_notify => $EMAIL_NOTIFY,
    ),
    "new CAR Importer"
);
ok( $car_importer->run(), "car_importer->run()" );
is( $car_importer->completed->{cars}, 5, "car_importer 5 imported" );
ok( my $car_report = $car_importer->report, "get car_report" );

#diag($car_report);
#diag( dump $car_importer->errors );
is( $car_importer->errored, 0, "no errors" );
ok( my $tanks = $car_importer->get_tanks(), "get_tanks" );
is( scalar(@$tanks), 4, "got 4 tanks for 5 cars representing 4 queries" );

my %query_uuids;
for my $t (@$tanks) {

    #diag( $t->tank_name );
    $query_uuids{ $t->tank_xuuid } = 1;
}

for my $c ( $car0, $car1, $car2, $car3, $car4 ) {
    $c->load();
    is( $c->car_air_export_status,
        $Formbuilder::CtbAskResponse::CAR_AIR_EXPORT_YES,
        "CAR flagged as exported"
    );

    # check for uuid
    my $uuid = $c->ask->ask_code;
    ok( $query_uuids{$uuid}, "ASK set in tank_xuuid" );
}

# empty car skipped
$empty_car->load;
is( $empty_car->car_air_export_status,
    $Formbuilder::CtbAskResponse::CAR_AIR_EXPORT_SKIPPED,
    "empty car skipped"
);

# public flags set
my $public_inq = AIR2::Inquiry->new( inq_uuid => $fb_ask0->ask_code );
ok( $public_inq->load(), "load fb_ask0 inquiry from AIR" );
for my $q ( @{ $public_inq->questions } ) {
    if ( $q->ques_type eq 'P' ) {
        is( $q->ques_value,
            'may we share your insights?',
            "permission question flagged as public"
        );
    }
}

# NOTE that inq_public_flag does not get re-set on fb_ask0
# because it was saved before the public questions associated
# with it were saved. Would need to re-import in order
# to get automatic flag saved, which we probably do not want
# to do anyway since it could overwrite manually set flag in AIR.

# because of this, we cannot adequately test the sr_public_flag
# importer logic because we cannot set ques_public_flag=1 outside
# the Importer class.

# before discriminator, get number of responses for known source
my $responses_before_import_0 = $air_source0->has_related('response_sets');
my $responses_before_import_1 = $air_source1->has_related('response_sets');

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
    my $job = AIR2::JobQueue->new(
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

    # only ask1 should conflict
    if ( $tank_meta->{inquiry} =~ m/^ima-fb-ask1/ ) {
        is( $t->tank_status, "C", "discriminator done, tank == C" );
    }
    else {
        is( $t->tank_status, "R", "discriminator done, tank == R" );
    }

    #diag( dump( $t->flatten( max_depth => 1 ) ) );
}

##########################################################
##             post-discriminator
##########################################################

# check response_sets
$air_source0->forget_related('response_sets');
$air_source1->forget_related('response_sets');
$air_source0->load();
$air_source1->load();
is( $air_source0->has_related('response_sets'),
    $responses_before_import_0,
    "no new response imported for existing user 0" );
is( $air_source1->has_related('response_sets'),
    $responses_before_import_1 + 2,
    "2 new response imported for existing user 1"
);

#diag( dump( $air_source1->flatten( force_load => 1, max_depth => 2 ) ) );

# check facts
is( $air_source1->get_religion(),
    "Christian (non-specified)",
    "fact translation happened"
);
is( $air_source1->get_income(),
    '$100001-$200000', "trac 1638 no commas in income" );

# check actvitiies
for my $sact ( @{ $air_source1->activities } ) {

    #diag( $sact->sact_desc );
    if ( $sact->sact_actm_id == $AIR2::ActivityMaster::QUERY_RESPONSE ) {
        is( $sact->sact_desc, "{SRC} responded to {XID}", "got sact" );
    }
}

is( $air_source1->get_pref_lang, 'es_US',
    "preferred language mapped to preferences" );

# new source added
my $new_air_source
    = AIR2Test::Source->new( src_username => $ctb_new->ctb_email )
    ->load_speculative();
if ($new_air_source) {
    is( $new_air_source->has_related('response_sets'),
        1, "1 new response_set for new source" );

    for my $sr ( @{ $new_air_source->response_sets->[0]->responses } ) {
        diag(
            sprintf( '%s : %s\n',
                $sr->question->ques_value,
                ( $sr->sr_orig_value || '(NULL)' ) )
        );
        if (    $sr->question->ques_template
            and $sr->question->ques_template eq 'email'
            and defined $sr->sr_orig_value )
        {
            is( $sr->sr_orig_value, $ctb_new->ctb_email,
                "contributor question autovivified, email imported" );
        }
    }

    is( $new_air_source->get_income(),
        '$100001-$200000',
        "trac 1638 no commas in income, even though raw input had them" );

   #diag(
   #    dump( $new_air_source->flatten( force_load => 1, max_depth => 2 ) ) );
}
else {
    fail( sprintf( "new source imported '%s'", $ctb_new->ctb_email ) );
    fail( sprintf( "new source imported '%s'", $ctb_new->ctb_email ) );
    fail( sprintf( "new source imported '%s'", $ctb_new->ctb_email ) );
}

# min-fields source created
my $min_air_source
    = AIR2Test::Source->new( src_username => $ctb_min_fields->ctb_email )
    ->load_speculative();
if ($min_air_source) {
    is( $min_air_source->has_related('response_sets'),
        1, "1 new response_set for new source" );

    my $num_resps = 0;
    for my $srs ( @{ $min_air_source->response_sets } ) {
        $num_resps += scalar @{ $srs->responses };
    }
    is( $num_resps, 3, "min-fields source contributor-only responses" );
}
else {
    fail("min-fields source not imported");
    fail("min-fields source no response sets");
}

##########################################################
##             clean up
##########################################################
for my $t (@$tanks) {
    for my $ts ( @{ $t->sources } ) {
        $ts->delete( cascade => 1 );
    }
    $t->delete( cascade => 1 );
}
for my $q (@questions) {
    $q->delete( cascade => 1 );
}
for my $ask ( @{ $fb_project->asks } ) {
    $ask->delete( cascade => 1 );
}
for my $ask ( @{ $fb_project1->asks } ) {
    $ask->delete( cascade => 1 );
}
$fb_project->delete( cascade => 1 );
$fb_project1->delete( cascade => 1 );
$ctb_in_air_conflict->delete( cascade => 1 );
$ctb_in_air_ok->delete( cascade => 1 );
$ctb_new->delete( cascade => 1 );
$ctb_min_fields->delete( cascade => 1 );

# normal DESTROY would catch this, but we want to nuke it before its related Project(s)
$air2_org->delete();
