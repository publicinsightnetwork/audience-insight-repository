#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw( dump );
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use lib 'tests/search/models';
use Test::More tests => 26;

use AIR2::Bin;
use AIR2::SrcEmail;
use AIR2Test::Source;
use AIR2Test::User;
use AIR2Test::Organization;
use AIR2Test::Inquiry;
use AIR2Test::Email;
use AIR2::SrcOrgCache;
use AIR2::Exporter::Mailchimp;

my $TEST_LIST_ID = '8992dc9e18';
my @SRC_EMAILS  = qw(
    cavisr+mctest1@gmail.com
    cavisr+mctest2@gmail.com
    cavisr+mctest3@gmail.com
);
my $USER_EMAIL = 'cavisr+mcuser@gmail.com';

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
    org_sys_id => [ { osid_type => 'M', osid_xuuid => $TEST_LIST_ID } ],
);
ok( $user->load_or_save(), "setup - test user" );
ok( $org->load_or_save(), "setup - test org" );

# create an email record
my $inq1 = AIR2Test::Inquiry->new( inq_title => 'ima-inquiry1' )->load_or_save;
my $inq2 = AIR2Test::Inquiry->new( inq_title => 'ima-inquiry2' )->load_or_save;
$user->add_signatures( [ { usig_text => 'blah blah blah' } ] );
$user->save();
my $email = AIR2Test::Email->new(
    email_org_id        => $org->org_id,
    email_usig_id       => $user->signatures->[-1]->usig_id,
    email_campaign_name => 'Test Importer 009-mailchimp',
    email_from_name     => $user->user_username,
    email_from_email    => 'pijdev@mpr.org',
    email_subject_line  => 'Test Importer 009-mailchimp',
    email_headline      => 'Test Importer 009-mailchimp',
    email_body          => 'This is the body of the email',
    email_type          => 'Q',
    email_status        => 'A',
    email_cre_user      => $user->user_id,
    email_upd_user      => $user->user_id,
)->save();
$email->add_email_inquiries( { einq_inq_id => $inq1->inq_id } );
$email->add_email_inquiries( { einq_inq_id => $inq2->inq_id } );
$email->save();

# test bins that clean themselves up
{
    package MyBin;
    @MyBin::ISA = ('AIR2::Bin');
    sub DESTROY { my $self = shift; $self->delete(); }
}
my $bin = MyBin->new( bin_name => 'test-mc-bin', user => $user );
ok( $bin->load_or_save(), "setup - test bin" );

# create sources and add to bins
sub create_source {
    my $e = shift;
    my $src = AIR2Test::Source->new( src_username => $e )->load_or_save;
    $src->add_src_orgs( [ { so_org_id => $org->org_id, so_status => 'A' } ] );
    $src->add_emails( [ { sem_email => $e, sem_status => 'G' } ] );
    $src->save();
    AIR2::SrcOrgCache::refresh_cache($src);
    my $soe = {
        soe_org_id      => $org->org_id,
        soe_status      => 'A',
        soe_status_dtim => time(),
        soe_type        => 'M',
    };
    $src->emails->[-1]->add_src_org_emails( [ $soe ] );
    $src->emails->[-1]->save();
    $src->save();
    return $src;
}
my @sources;
for my $e ( @SRC_EMAILS ) {
    my $src = create_source( $e );
    push @sources, $src;
    $bin->add_sources( { bsrc_src_id => $src->src_id } );
}
ok( $bin->save(), "setup - add sources to test bin" );
is( scalar @{ $bin->sources }, 3, "setup - test bin_source count" );

#
# MORE SETUP - run the exporter (ACTUALLY SENDS CAMPAIGN)
#
ok( my $exporter = AIR2::Exporter::Mailchimp->new(
        debug        => 0,
        dry_run      => 0,
        no_export    => 0,
        no_bcc       => 1,
        strict       => 1,
        reader       => $bin->get_exportable_emails($org),
        export_email => $email,
        export_bin   => $bin,
        user         => $user,
    ),
    "test export - exporter"
);
ok( defined $exporter->run(), "test export - run()" );
is( $exporter->completed, 3, "test export - completed" );
is( $exporter->errored, 0, "test export - errored" );
is( $exporter->skipped, 0, "test export - skipped" );
# diag( $exporter->report );

# reference src_exports (for cleanup)
my %src_exports;
for my $src ( @sources ) {
    $src->load();
    for my $si ( @{ $src->inquiries } ) {
        is( $si->si_status, 'P', 'test export - si_status pending' );
        $src_exports{ $si->src_export->se_id }++;
    }
}
is( scalar keys %src_exports, 1, "test export - 1 src_export" );

my $seid = (keys %src_exports)[0];
my $src_export = AIR2::SrcExport->new( se_id => $seid )->load;
is( $src_export->se_status, 'Q', 'test export - se_status queued' );

#
# check periodically to see if the campaign is sent
#
$| = 1;
for ( my $i = 0; $i < 10; $i++) {
    sleep 5;
    if ( my $resp = AIR2::Mailchimp->campaign( $src_export->se_name ) ) {
        last if ( $resp->{status} eq 'sent' );
    }
}

#
# run the importer!
#
my $perl     = $^X;
my $app_root = AIR2::Config->get_app_root();
my $import   = $app_root->file("bin/mailchimp-import");
my $output   = `$perl $import --debug`;
# diag($output);

$src_export->load;
is( $src_export->se_status, 'C', 'test import - se_status complete' );
is( $src_export->get_meta('mailchimp_emails'), 3, 'test import - mailchimp_emails count' );
for my $src ( @sources ) {
    $src->load(with => 'inquiries');
    for my $si ( @{ $src->inquiries } ) {
        is( $si->si_status, 'C', 'test import - si_status complete' );
    }
}

#
# cleanup campaigns/segments (optional, but nice)
#
my $tres = $exporter->{api}->{api}->listStaticSegments(id => $TEST_LIST_ID);
for my $ss ( @{ $tres } ) {
    if ( $ss->{name} =~ /Test-Importer-009-mailchimp/ ) {
        # diag("* cleaning up $ss->{name}\n");
        $exporter->{api}->{api}->listStaticSegmentDel(id => $TEST_LIST_ID, seg_id => $ss->{id});
    }
}
$tres = $exporter->{api}->{api}->campaigns(filters => {list_id => $TEST_LIST_ID});
for my $cc ( @{ $tres->{data} } ) {
    if ( $cc->{subject} =~ /Test Importer 009-mailchimp/ ) {
        # diag("* cleaning up $cc->{subject}\n");
        $exporter->{api}->{api}->campaignDelete(cid => $cc->{id});
    }
}
for my $se_id ( keys %src_exports ) {
    # diag("* cleaning up src_export($se_id)\n");
    AIR2::SrcExport->new( se_id => $se_id )->load->delete();
}
