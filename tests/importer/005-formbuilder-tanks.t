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

use Test::More tests => 19;

my $EMAIL_NOTIFY = $ENV{FB_NOTIFY} || $ENV{USER} . '@mpr.org';
my $DEBUG        = $ENV{FB_DEBUG}  || 0;

$Rose::DB::Object::Manager::Debug = $DEBUG;
$Rose::DB::Object::Debug          = $DEBUG;

# clean up from any previous run
# must cascade manually since oracle has no CASCADE on delete defined.
my @fb_proj_uuids = qw(air2-test-import);
for my $uuid (@fb_proj_uuids) {
    my $old = Formbuilder::Project->new( proj_code => $uuid )->load_speculative;
    if ($old && $old->proj_id) {
        for my $ask ( @{ $old->asks } ) {
            for my $q ( @{ $ask->ask_questions } ) {
                $q->delete( cascade => 1 );
            }
            for my $car ( @{ $ask->ctb_ask_responses } ) {
                $car->delete( cascade => 1 );
            }
            $ask->delete( cascade => 1 );
        }
        $old->delete( cascade => 1 );
    }

    # also look for AIR projects
    my $oldair = AIR2::Project->new( prj_name => $uuid )->load_speculative;
    if ($oldair && $oldair->prj_id) {
        $oldair->delete( cascade => 1 );
    }
}

# cleanup inquiries and tanks
my %stale_tanks;
for my $uuid (qw(ima-fb-ask1 ima-fb-ask2)) {
    my $tanks = AIR2::Tank->fetch_all(
        query => [ tank_type => 'F', tank_xuuid => $uuid ]
    );
    for my $t ( @{$tanks} ) {
        $t->delete( cascade => 1 );
    }

    my $old = AIR2::Inquiry->new( inq_uuid => $uuid )->load_speculative;
    if ($old && $old->inq_id) {
        $old->delete( cascade => 1 );
    }
}


##############################################################
##                        SETUP
##############################################################

# load/save an organization
my $air_org = AIR2Test::Organization->new(
    org_name           => 'ima-org',
    org_display_name   => 'ima-displayed org',
    org_default_prj_id => 1,
)->load_or_save();

# create formbuilder project
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

# create air project
my $air_project = AIR2Test::Project->new(
    prj_name         => 'air2-test-import',
    prj_display_name => 'testing formbuilder import',
);
$air_project->save();

# associate with org
my $user = AIR2::User->new( user_id => 1 )->load;
$air_org->org_default_prj_id( $air_project->prj_id );
$air_org->save();
$air_project->project_orgs(
    {   porg_org_id          => $air_org->org_id,
        porg_contact_user_id => 1,
    }
);
$air_project->save();

# asks and questions
my $fb_ask1 = Formbuilder::Ask->new(
    ask_code           => 'ima-fb-ask1',
    ask_title          => 'ima-fb-ask-test-title1',
    ask_external_title => 'ima-fb-ask-test-ext-title1',
    project            => $fb_project,
    ask_status         => 'P',
);
$fb_ask1->save;
my $ask1_question1 = Formbuilder::AskQuestion->new(
    askq_qtyp_id => 1,
    askq_ask_id  => $fb_ask1->ask_id,
    askq_qt_id   => 1,
    askq_text    => 'what is your gender?',
)->save();
my $ask1_question2 = Formbuilder::AskQuestion->new(
    askq_qtyp_id => 2,
    askq_ask_id  => $fb_ask1->ask_id,
    askq_qt_id   => 2,
    askq_text    => 'what is your income?',
)->save();

# sources
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
my $air_source2 = AIR2Test::Source->new(
    src_username   => 'FB_TEST_USER2',
    src_first_name => 'TEST',
    src_last_name  => 'SOURCE',
    src_status     => 'A',
    emails         => [
        {   sem_primary_flag => 1,
            sem_email        => 'FB_TEST_USER2@nosuchemail.org',
        }
    ],
)->load_or_save();

# contributors
my $ctb1 = Formbuilder::Contributor->new(
    ctb_email      => $air_source1->get_primary_email()->sem_email,
    ctb_first_name => $air_source1->src_first_name,
    ctb_last_name  => $air_source1->src_last_name,
)->load_or_save();
my $ctb2 = Formbuilder::Contributor->new(
    ctb_email      => $air_source2->get_primary_email()->sem_email,
    ctb_first_name => $air_source2->src_first_name,
    ctb_last_name  => $air_source2->src_last_name,
)->load_or_save();

# responses
my $car1 = Formbuilder::CtbAskResponse->new(
    car_ctb_id => $ctb1->ctb_id,
    car_ask_id => $fb_ask1->ask_id,
)->load_or_save();
$car1->add_ctb_ask_response_dtls([
    {
        card_askq_id => $ask1_question1->askq_id,
        card_value   => 'my gender',
    },
    {
        card_askq_id => $ask1_question2->askq_id,
        card_value   => 'my income',
    }
]);
$car1->save();


my $car2 = Formbuilder::CtbAskResponse->new(
    car_ctb_id => $ctb2->ctb_id,
    car_ask_id => $fb_ask1->ask_id,
)->load_or_save();
$car2->add_ctb_ask_response_dtls([
    {
        card_askq_id => $ask1_question1->askq_id,
        card_value   => 'my gender',
    },
    {
        card_askq_id => $ask1_question2->askq_id,
        card_value   => 'my income',
    }
]);
$car2->save();


##########################################################
##        run import on first response
##########################################################
my $car_reader = Formbuilder::CtbAskResponse->fetch_all_iterator(
    query => [ car_id => $car1->car_id ]
);

ok( my $car_importer = AIR2::Importer::Formbuilder->new(
        debug        => $DEBUG,
        atomic       => 1,
        max_errors   => 1,
        reader       => $car_reader,
        user         => $user,
        default_org  => $air_org,
        email_notify => $EMAIL_NOTIFY,
    ),
    "new CAR Importer"
);
ok( $car_importer->run(), "car_importer->run()" );
is( $car_importer->completed->{cars}, 1, "car_importer 1 imported" );
ok( my $car_report = $car_importer->report, "get car_report" );
is( $car_importer->errored, 0, "no errors" );
ok( my $tanks = $car_importer->get_tanks(), "get_tanks" );
is( scalar(@$tanks), 1, "got 1 tank" );

my $t1 = $tanks->[0];
is( $t1->tank_name, 'ima-fb-ask-test-ext-title1', 'tank 1 name' );
is( $t1->tank_xuuid, 'ima-fb-ask1', 'tank 1 xuuid' );


##########################################################
##        run import on second response
##########################################################
my $car_reader2 = Formbuilder::CtbAskResponse->fetch_all_iterator(
    query => [ car_id => $car2->car_id ]
);

ok( my $car_importer2 = AIR2::Importer::Formbuilder->new(
        debug        => $DEBUG,
        atomic       => 1,
        max_errors   => 1,
        reader       => $car_reader2,
        user         => $user,
        default_org  => $air_org,
        email_notify => $EMAIL_NOTIFY,
    ),
    "new CAR Importer2"
);
ok( $car_importer2->run(), "car_importer2->run()" );
is( $car_importer2->completed->{cars}, 1, "car_importer2 1 imported" );
ok( my $car_report2 = $car_importer2->report, "get car_report2" );
is( $car_importer2->errored, 0, "no errors" );
ok( my $tanks2 = $car_importer2->get_tanks(), "get_tanks" );
is( scalar(@$tanks2), 1, "got 1 tank" );

my $t2 = $tanks2->[0];
is( $t2->tank_name, 'ima-fb-ask-test-ext-title1', 'tank 1 name' );
is( $t2->tank_xuuid, 'ima-fb-ask1', 'tank 1 xuuid' );
is( $t2->tank_id, $t1->tank_id, 'got same tank' );


##########################################################
##             clean up
##########################################################
for my $t (@$tanks) {
    for my $ts ( @{ $t->sources } ) {
        $ts->delete( cascade => 1 );
    }
    $t->delete( cascade => 1 );
}

$air_org->delete( cascade => 1 );
$air_project->delete( cascade => 1 );
$ask1_question1->delete( cascade => 1 );
$ask1_question2->delete( cascade => 1 );
$fb_ask1->delete( cascade => 1 );
$fb_project->delete( cascade => 1 );
$air_source1->delete( cascade => 1);
$air_source2->delete( cascade => 1);
$car1->delete( cascade => 1 );
$car2->delete( cascade => 1 );
$ctb1->delete( cascade => 1 );
$ctb2->delete( cascade => 1 );
