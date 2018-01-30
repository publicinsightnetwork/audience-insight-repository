#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw( dump );
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use lib 'tests/mailchimp';
use lib 'tests/search/models';
use Test::More tests => 50;

use AIR2::Bin;
use AIR2::SrcEmail;
use AIR2Test::Source;
use AIR2Test::User;
use AIR2Test::Organization;
use AIR2Test::Inquiry;
use AIR2Test::Email;
use AIR2::SrcOrgCache;

use MailchimpUtils;

use_ok('AIR2::Exporter::Mailchimp');

my $EMAIL_NOTIFY = $ENV{MAILCHIMP_NOTIFY} || $ENV{USER} . '@mpr.org';
my $DEBUG        = $ENV{MAILCHIMP_DEBUG}  || 0;
my @TEST_EMAILS = map {"tempuser_$_\@mpr.org"} 1 .. 100;
my @LIVE_EMAILS = ();
my %seen        = ();
while ( scalar(@LIVE_EMAILS) < 3 ) {

    # all the pin0-99 @pinsight.org addresses are forwarded to the same
    # email address, so pick a random number in that range.
    # we randomize so as not to run afoul of MC throttling.
    my $random = 0 + int( rand(99) );
    my $email  = "pin${random}\@pinsight.org";
    push @LIVE_EMAILS, $email unless $seen{$email}++;
}
diag("LIVE EMAILS: " . dump(\@LIVE_EMAILS));

my $USER_EMAIL = 'pijdev@mpr.org';

# start clean
{
    my $u = AIR2::User->new( user_username => 'i-am-a-test-user' )
        ->load_speculative;
    $u->delete if $u;
}

# setup an org with some src_org_emails
my $user = AIR2Test::User->new(
    user_username   => 'i-am-a-test-user',
    user_first_name => 'i',
    user_last_name  => 'test',
);
$user->user_email_address( [ { uem_address => $USER_EMAIL } ] );
my $org = AIR2Test::Organization->new(
    org_default_prj_id => 1,
    org_name           => 'mailchimp-test-org',
    org_sys_id =>
        [ { osid_type => 'M', osid_xuuid => MailchimpUtils::list_id } ],
);
ok( $user->load_or_save(), "setup - test user" );
ok( $org->load_or_save(),  "setup - test org" );

# assumption: all sources in the APMPIN org since that org owns the mailing lists.
my $apmpin_org
    = AIR2::Organization->new( org_id => AIR2::Config::get_apmpin_org_id() )
    ->load;

# create an email record
my $inq1
    = AIR2Test::Inquiry->new( inq_title => 'ima-inquiry1', )->load_or_save;
my $inq2
    = AIR2Test::Inquiry->new( inq_title => 'ima-inquiry2', )->load_or_save;
$user->add_signatures( [ { usig_text => 'blah blah blah' } ] );
$user->save();
my $email = AIR2Test::Email->new(
    email_org_id        => $org->org_id,
    email_usig_id       => $user->signatures->[-1]->usig_id,
    email_campaign_name => 'Test Exporter 003-mailchimp',
    email_from_name     => $user->user_username,
    email_from_email    => 'pijdev@mpr.org',
    email_subject_line  => 'Test Exporter 003-mailchimp',
    email_headline      => 'Test Exporter 003-mailchimp',
    email_body          => 'This is the body of the email',
    email_type          => 'Q',
    email_status        => 'A',
    email_cre_user      => $user->user_id,
    email_upd_user      => $user->user_id,
)->save();
$email->add_email_inquiries( { einq_inq_id => $inq1->inq_id } );
$email->add_email_inquiries( { einq_inq_id => $inq2->inq_id } );
$email->save();

diag('email saved');

# test bins that clean themselves up
{

    package MyBin;
    @MyBin::ISA = ('AIR2::Bin');
    sub DESTROY { my $self = shift; $self->delete(); }
}
my $test_bin = MyBin->new( bin_name => 'test-fake-mc-bin', user => $user );
my $live_bin = MyBin->new( bin_name => 'test-live-mc-bin', user => $user );
ok( $test_bin->load_or_save(), "setup - test bin" );
ok( $live_bin->load_or_save(), "setup - live bin" );

#############################################################################
# helper: create sources and add to bins
sub create_source {
    my $e = shift;

    #$Rose::DB::Object::Debug = 1;
    my $src = AIR2Test::Source->new( src_username => $e )->load_or_save;
    $src->src_orgs(
        [   { so_org_id => $org->org_id,        so_status => 'A' },
            { so_org_id => $apmpin_org->org_id, so_status => 'A' }
        ]
    );
    $src->emails( [ { sem_email => $e, sem_status => 'G' } ] );
    $src->save();
    AIR2::SrcOrgCache::refresh_cache($src);
    my $soe = {
        soe_org_id      => $apmpin_org->org_id,
        soe_status      => 'A',
        soe_status_dtim => time(),
        soe_type        => 'M',
    };
    my $email = $src->emails->[0];
    $email->src_org_emails( [$soe] );
    $email->save();

    #$Rose::DB::Object::Debug = 0;
    return $src;
}
############################################################################

my ( @test_sources, @live_sources );
for my $e (@TEST_EMAILS) {
    my $src = create_source($e);
    push @test_sources, $src;
    $test_bin->add_sources( { bsrc_src_id => $src->src_id } );
}
diag("Adding LIVE_EMAILS to Bin");
for my $e (@LIVE_EMAILS) {
    my $src = create_source($e);
    push @live_sources, $src;
    $live_bin->add_sources( { bsrc_src_id => $src->src_id } );
}
ok( $test_bin->save(), "setup - add sources to test bin" );
ok( $live_bin->save(), "setup - add sources to live bin" );
is( scalar @{ $test_bin->sources }, 100, "setup - test bin_source count" );
is( scalar @{ $live_bin->sources }, 3,   "setup - live bin_source count" );

#
# TEST THE FIRST - DRY_RUN with 100 sources
#

# trigger some misc "gotchas"
$test_sources[10]->src_status('D');
$test_sources[10]->update();
my $ss = AIR2::SrcStat->new(
    sstat_export_dtim => time(),
    source            => $test_sources[11]
);
$ss->save();
$test_sources[12]->emails->[0]->sem_email('tempuser_13@nosuchemail.org');
$test_sources[12]->emails->[0]->save();
$test_sources[13]->emails->[0]->sem_status('B');
$test_sources[13]->emails->[0]->save();
$test_sources[14]->src_orgs->[0]->so_status('D');
$test_sources[14]->src_orgs->[0]->save();
AIR2::SrcOrgCache::refresh_cache( $test_sources[14] );

# raw exportable count
my $test_it = $test_bin->get_exportable_mailchimp_emails($org);
my $count   = 0;
my %uniq;
while ( my $e = $test_it->next ) {
    $uniq{ $e->{sem_email} }++;
    $count++;
}
is( $count,               100, "test export - exportable_emails count" );
is( scalar( keys %uniq ), 100, "test export - exportable_emails unique" );

ok( my $test_exp = AIR2::Exporter::Mailchimp->new(
        debug        => $DEBUG,
        dry_run      => 1,
        no_export    => 1,
        strict       => 1,
        reader       => $test_bin->get_exportable_mailchimp_emails($org),
        export_email => $email,
        export_bin   => $test_bin,
        user         => $user,
    ),
    "test export - exporter"
);
ok( defined $test_exp->run(), "test export - run()" );
is( $test_exp->completed, 95, "test export - completed" );
is( $test_exp->errored,   0,  "test export - errored" );
is( $test_exp->skipped,   5,  "test export - skipped" );
diag( $test_exp->report );

#
# TEST THE SECOND - live NO_EXPORT with 3 sources
#

# make sure mailchimp won't be able to subscribe one of these
diag("subscribe all live emails");
$test_exp->{api}->subscribe( [@LIVE_EMAILS] );

diag( "Mailchimp should unsubscribe " . $LIVE_EMAILS[0] );
$test_exp->{api}->unsubscribe( [ $LIVE_EMAILS[0] ] );

# build a new exporter
diag("Creating live exporter with no_export=>1");
ok( my $live_exp = AIR2::Exporter::Mailchimp->new(
        debug        => $DEBUG,
        dry_run      => 0,
        no_export    => 1,
        strict       => 1,
        reader       => $live_bin->get_exportable_mailchimp_emails($org),
        export_email => $email,
        export_bin   => $live_bin,
        user         => $user,
    ),
    "live export - exporter"
);
ok( defined $live_exp->run(), "live export - run()" );
is( $live_exp->completed, 2, "live export - completed" );
is( $live_exp->errored,   1, "live export - errored" );
is( $live_exp->skipped,   0, "live export - skipped" );
diag("Live export report: ");
diag( $live_exp->report );

# check logging
my %src_exports;

# register cleanup routine
END {
    for my $se_id ( keys %src_exports ) {
        AIR2::SrcExport->new( se_id => $se_id )->load->delete();
    }
}

for my $src (@live_sources) {
    $src->load();

    diag( "checking source for export: " . $src->src_username );

    if ( $src->src_username eq $LIVE_EMAILS[0] ) {
        is( $src->has_related('activities'), 1, "1 activity created" );
        is( $src->has_related('inquiries'),  0, "no src_inquiry created" );

        for my $sact ( @{ $src->activities } ) {
            like(
                $sact->sact_desc,
                qr/status changed to unsubscribed/i,
                "unsub sact logged"
            );
        }
    }
    else {
        is( $src->has_related('activities'), 1, "one activity created" );
        is( $src->has_related('inquiries'),  2, "two src_inquiry created" );

        for my $sact ( @{ $src->activities } ) {
            like(
                $sact->sact_desc,
                qr/emailed {XID} to source/,
                "got sact logged"
            );
        }

        my $campid = $live_exp->{campaign_id};
        for my $si ( @{ $src->inquiries } ) {
            is( $si->si_sent_by,          $campid, "sent_by==campaign_id" );
            is( $si->src_export->se_name, $campid, "se_name==filter_name" );
            is( $si->si_cre_dtim, $src->last_export_dtim,
                "last_export_dtim==si_cre_dtim" );
            $src_exports{ $si->src_export->se_id }++;
        }
    }
}

# check the metadata about the export
is( scalar keys %src_exports, 1, 'single src_export record' );
my $my_se_id = ( keys %src_exports )[-1];

#diag("my_se_id = $my_se_id");
#diag( dump \%src_exports );
if ($my_se_id) {
    my $se = AIR2::SrcExport->new( se_id => $my_se_id )->load;
    is( $se->se_type,     'M',               "src_export type 'Mailchimp'" );
    is( $se->se_xid,      $live_bin->bin_id, "src_export bin_id" );
    is( $se->se_ref_type, 'I',               "src_export ref_type 'Bin'" );
    is( $se->se_email_id, $email->email_id,  "src_export email_id" );
    is( $se->get_meta('initial_count'), 3, "src_export initial count" );
    is( $se->get_meta('export_count'),  2, "src_export export count" );
    my $bccd = { map { $_ => 1 } split( /\s*,\s*/, $se->get_meta('bcc') ) };
    is_deeply(
        $bccd,
        { 'pij-mail-qa@mpr.org' => 1, $USER_EMAIL => 1 },
        "src_export bcc emails"
    );
}
else {
    fail("src_export type 'Mailchimp'");
    fail("src_export bin_id");
    fail("src_export ref_type 'Bin'");
    fail("src_export email_id");
    fail("src_export initial count");
    fail("src_export export count");
    fail("src_export bcc emails");
}

# force org to clean itself up, rather than waiting for global clean up.
# this works around db refcount bug in tests only.
$org = undef;
