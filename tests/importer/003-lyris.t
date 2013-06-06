#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use lib 'tests/search/models';
use AIR2::User;
use AIR2::Config;
use AIR2Test::Source;
use AIR2Test::Project;
use AIR2Test::Inquiry;
use AIR2Test::Organization;
use AIR2::Bin;
use AIR2::Exporter::Lyris;
use AIR2::Importer::Lyris;
use lib AIR2::Config::get_app_root() . '/lib/lyris';
use Lyris::DB::MailingList;
use Lyris::DB::Message;
use Lyris::DB::Email;

use Data::Dump qw( dump );

use Test::More tests => 34;

my $EMAIL_NOTIFY = $ENV{LYRIS_NOTIFY} || $ENV{USER} . '@mpr.org';
my $DEBUG        = $ENV{LYRIS_DEBUG}  || 0;
my $DUMMY_MAILING_LIST_ID = 100;

$Rose::DB::Object::Manager::Debug = $DEBUG;
$Rose::DB::Object::Debug          = $DEBUG;

# temp packages to clean up when we end the script
{

    package MyBin;
    @MyBin::ISA = ('AIR2::Bin');

    sub DESTROY {
        my $self = shift;

        #warn "cleaning up $self id==" . $self->bin_id;
        $self->delete();
    }

}
{

    package MyMailingList;
    @MyMailingList::ISA = ('Lyris::DB::MailingList');
    sub DESTROY { shift->delete() }
}

{

    package MyEmail;
    @MyEmail::ISA = ('Lyris::DB::Email');
    sub DESTROY { shift->delete() }
}

{

    package MyMessage;
    @MyMessage::ISA = ('Lyris::DB::Message');
    sub DESTROY { shift->delete() }
}

{

    package MyEmailMessage;
    @MyEmailMessage::ISA = ('Lyris::DB::EmailMessage');
    sub DESTROY { shift->delete() }
}

# the Plan:
# create a dummy Source with dummy Export
# create a dummy Message, then import it, testing the Export reconciliation
# create some extra email_messages, to make sure they AREN'T imported

my $project = AIR2Test::Project->new(
    prj_name         => 'ima-project',
    prj_display_name => 'ima-project',
)->load_or_save();
my $org = AIR2Test::Organization->new(
    org_name           => 'ima-org',
    org_display_name   => 'ima-displayed org',
    org_default_prj_id => 1,
    org_sys_id =>
        [ { osid_type => 'E', osid_xuuid => $DUMMY_MAILING_LIST_ID, } ],
)->load_or_save();
my $inquiry
    = AIR2Test::Inquiry->new( inq_title => 'ima-inquiry', )->load_or_save();
my $user = AIR2::User->new( user_id => 1 )->load;

# create a source with email
sub mk_source {
    my $uname = shift;
    my $src = AIR2Test::Source->new( src_username => $uname )->load_or_save();
    $src->add_emails( [ { sem_email => $src->src_username } ] );
    $src->add_organizations($org);
    $src->save();
    for my $sem ( @{ $src->emails } ) {
        $sem->add_src_org_emails(
            [   {   soe_org_id      => $org->org_id,
                    soe_status      => 'A',
                    soe_status_dtim => time(),
                    soe_type        => 'L',
                }
            ]
        );
        $sem->save();
    }
    return $src;
}

my $source1 = mk_source('tempuser_1@ima-email-domain.org');
my $source2 = mk_source('tempuser_2@ima-email-domain.org');
my $source3 = mk_source('tempuser_3@ima-email-domain.org');
my $source4 = mk_source('tempuser_4@ima-email-domain.org');
my $source5 = mk_source('tempuser_5@ima-email-domain.org');

my $bin = MyBin->new(
    bin_name    => 'air2-test-lyris-bucket',
    bin_user_id => $user->user_id,
    sources     => [
        { bsrc_src_id => $source1->src_id },
        { bsrc_src_id => $source2->src_id },
        { bsrc_src_id => $source3->src_id },
        { bsrc_src_id => $source4->src_id },
        { bsrc_src_id => $source5->src_id },
    ],
);
$bin->load_or_save();
#diag("AIR2 data set up complete");

# export the bin (not really because of no_export)
ok( my $exporter = AIR2::Exporter::Lyris->new(
        reader       => $bin->get_exportable_emails($org),
        reuse_demographic => 1,    # keep noise down while testing
        name         => $bin->bin_name,
        strict       => 1,                    # enforce the 24-hour rule
        org          => $org,
        user         => $user,
        project      => $project,
        inquiry      => $inquiry,
        email_notify => $EMAIL_NOTIFY,
        debug        => $DEBUG,
        no_export    => 1,
    ),
    "new Lyris Exporter"
);

#Temporarily suppress warnings (this will show an "unauthorized")
{
    local $SIG{__WARN__}=sub{};
    ok( $exporter->run(), "exporter->run()" );
}

# create dummy records in Lyris db
my $message_date = time();
my $mlist        = MyMailingList->new(
    ml_id   => $DUMMY_MAILING_LIST_ID,
    ml_name => 'ima-mailing-list',
)->load_or_save();
my $message = MyMessage->new(
    msg_id        => 1,                    # TODO conflict?
    msg_subject   => 'ima-message',
    msg_name      => 'ima-message-name',
    msg_category  => 'Query',
    msg_date      => $message_date,
    msg_rule_name => $bin->bin_name,
    msg_ml_id     => $mlist->ml_id,
)->load_or_save();

# create lyris emails
sub mk_lyris_email {
    my $addr = shift;
    my $stat = shift || $Lyris::DB::EmailMessage::STATUS_SENT;
    my $email = MyEmail->new(
        email_address => $addr,
        email_ml_id   => $mlist->ml_id,
        email_uid     => 'imatester0',
    )->load_or_save();
    my $em = MyEmailMessage->new(
        em_msg_id   => $message->msg_id,
        em_email_id => $email->email_id,
        em_status   => $stat,
    )->load_or_save();
    return [$em, $email]; #keep in-scope
}

my $lyris1 = mk_lyris_email( $source1->src_username, 'S' );
my $lyris2 = mk_lyris_email( $source2->src_username, 'N' );
my $lyris3 = mk_lyris_email( $source3->src_username, 'N' );
my $lyris4 = mk_lyris_email( $source4->src_username, 'I' );
my $lyris5 = mk_lyris_email( $source5->src_username, 'K' );
my $lyris6 = mk_lyris_email( '12345DNEINAIR@notinair.com', 'S' );

# import!
ok( my $importer = AIR2::Importer::Lyris->new(
        reader => Lyris::DB::Message->fetch_all_iterator(
            query => [
                msg_ml_id  => $mlist->ml_id,
                msg_date   => { ge => $message_date },
            ],
        ),
        debug        => $DEBUG,
        atomic       => 1,
        max_errors   => 1,
        user         => $user,
        email_notify => $EMAIL_NOTIFY,
    ),
    "new Lyris Importer"
);
ok( $importer->run(), "importer->run()" );
is( $importer->completed, 1, "1 completed" );
is( $importer->skipped,   0, "0 skipped" );
is( $importer->emails,    1, "1 emails" );

# the source should have 2 activities: 1 Export To Lyris and 1 Query Sent
is( $source1->has_related('activities'), 2, "source has 2 activities" );
for my $sact ( @{ $source1->activities } ) {
    ok( $sact, "got activity" );
    #diag( 'Activity: ' . $sact->activitymaster->actm_name );
    if ( $sact->sact_actm_id == 25 ) {
        ok( $sact, "got Export to Email Provider activity" );
    }
    elsif ( $sact->sact_actm_id == 13 ) {
        ok( $sact, "got Sent Query activity" );
    }
}
is( $source1->has_related('inquiries'),  1,   "source has 1 related inquiry" );
is( $source1->inquiries->[0]->si_status, 'C', "src_inquiry.status == C" );

$message->load();
is( $message->msg_status, 'I', 'message is marked complete' );
is( $message->email_messages->[0]->em_status,
    'I', "email_message marked complete" );

my $exports = AIR2::SrcExport->fetch_all(
    query => [
        se_name   => $bin->bin_name,
        se_type   => 'L',                  # Lyris
        se_status => 'C',
    ]
);
my $export;
if ( $exports and @$exports ) {
    if ( @$exports > 1 ) {
        fail(     "Too many matching SrcExport records for se_name='"
                . $bin->bin_name
                . "' and se_type=L" );
    }
    else {
        pass("Found one src_export");
    }
    $export = $exports->[0];
}

# check src_export counts
if ( !$export ) {
    fail("Cannot find src_export");
}
else {
    pass("Found src_export");
    is( $export->get_meta('initial_count'), 5, 'initial 5' );
    is( $export->get_meta('export_count'),  5, 'export 5' );
    is( $export->get_meta('lyris_emails'),  1, 'lyris sent 1 email' );
    is( $export->get_meta('lyris_dne_air'),  1, 'lyris missed 1 dne' );
}

# check the email_message status
$lyris1->[0]->load();
$lyris2->[0]->load();
$lyris3->[0]->load();
$lyris4->[0]->load();
$lyris5->[0]->load();
$lyris6->[0]->load();
is( $lyris1->[0]->em_status, 'I', 'em1 status' );
is( $lyris2->[0]->em_status, 'N', 'em2 status' );
is( $lyris3->[0]->em_status, 'N', 'em3 status' );
is( $lyris4->[0]->em_status, 'I', 'em4 status' );
is( $lyris5->[0]->em_status, 'K', 'em5 status' );
is( $lyris6->[0]->em_status, 'K', 'em6 status' );

# flip status, and re-import the rest
$lyris2->[0]->em_status('S');
$lyris2->[0]->save();
$lyris3->[0]->em_status('S');
$lyris3->[0]->save();

ok( my $importer2 = AIR2::Importer::Lyris->new(
        reader => Lyris::DB::Message->fetch_all_iterator(
            query => [
                msg_ml_id  => $mlist->ml_id,
                msg_date   => { ge => $message_date },
            ],
        ),
        debug        => $DEBUG,
        atomic       => 1,
        max_errors   => 1,
        user         => $user,
        email_notify => $EMAIL_NOTIFY,
    ),
    "new Lyris Importer"
);
ok( $importer2->run(), "importer2->run()" );
is( $importer2->completed, 1, "1 completed" );
is( $importer2->skipped,   0, "0 skipped" );
is( $importer2->emails,    2, "2 emails" );

# re-check counts
$export->load();
if ( !$export ) {
    fail("Cannot find src_export");
}
else {
    is( $export->get_meta('lyris_emails'),  3, 'lyris sent 3 email' );
}
