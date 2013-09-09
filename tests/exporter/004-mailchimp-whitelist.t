#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw( dump );
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use lib 'tests/search/models';
use Test::More tests => 14;
use Test::Exception;

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
my @TEST_EMAILS = qw(
    rcavis@mpr.org
    haroldblah@nosuchemail.org
    nobodynothing@blah.gov
);
my $USER_EMAIL = 'cavisr+mcuser@gmail.com';

# setup user
my $user = AIR2Test::User->new(
    user_username   => 'i-am-a-test-user',
    user_first_name => 'i',
    user_last_name  => 'test',
);
$user->user_email_address( [ { uem_address => $USER_EMAIL } ] );
ok( $user->load_or_save(), "setup - test user" );

# signature
$user->add_signatures( [ { usig_text => 'blah blah blah' } ] );
$user->save();

# setup org
my $org = AIR2Test::Organization->new(
    org_default_prj_id => 1,
    org_name           => 'mailchimp-test-org',
    org_sys_id => [ { osid_type => 'M', osid_xuuid => $TEST_LIST_ID } ],
);
ok( $org->load_or_save(), "setup - test org" );

# create email record
my $email = AIR2Test::Email->new(
    email_org_id        => $org->org_id,
    email_usig_id       => $user->signatures->[-1]->usig_id,
    email_campaign_name => 'Test Exporter 004-mailchimp-whitelist',
    email_from_name     => $user->user_username,
    email_from_email    => 'pijdev@mpr.org',
    email_subject_line  => 'Test Exporter 004-mailchimp-whitelist',
    email_headline      => 'Test Exporter 004-mailchimp-whitelist',
    email_body          => 'This is the body of the email',
    email_status        => 'A',
    email_type          => 'O',
    email_cre_user      => $user->user_id,
    email_upd_user      => $user->user_id,
)->save();
$email->save();

# test bins that clean themselves up
{
    package MyBin;
    @MyBin::ISA = ('AIR2::Bin');
    sub DESTROY { my $self = shift; $self->delete(); }
}
my $test_bin = MyBin->new( bin_name => 'test-mc-bin', user => $user );
ok( $test_bin->load_or_save(), "setup - test bin" );

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
my @test_sources;
for my $e ( @TEST_EMAILS ) {
    my $src = create_source( $e );
    push @test_sources, $src;
    $test_bin->add_sources( { bsrc_src_id => $src->src_id } );
}
ok( $test_bin->save(), "setup - add sources to test bin" );

#
# Bin exporter test
#
ok( my $test_exp = AIR2::Exporter::Mailchimp->new(
        debug        => 0,
        dry_run      => 1,
        no_export    => 1,
        strict       => 1,
        reader       => $test_bin->get_exportable_emails($org),
        export_email => $email,
        export_bin   => $test_bin,
        user         => $user,
    ),
    "test export - exporter"
);
ok( defined $test_exp->run(), "test export - run()" );
is( $test_exp->completed, 1, "test export - completed" );
is( $test_exp->errored, 0, "test export - errored" );
is( $test_exp->skipped, 2, "test export - skipped" );
# diag( $test_exp->report );

# check the reasons
is( $test_exp->{was_checked}->{ $TEST_EMAILS[1] }, 'N', 'nosuchemail ignored' );
is( $test_exp->{was_checked}->{ $TEST_EMAILS[2] }, 'W', 'whitelist ignored' );

#
# single emailer test
#
throws_ok(
    sub { $email->send_single( $TEST_EMAILS[1] ) },
    qr/is not a real email address/,
    'single email - nosuchemail exception'
);
throws_ok(
    sub { $email->send_single( $TEST_EMAILS[2] ) },
    qr/from a non-prod environment/,
    'single email - whitelist exception'
);

# try a static-context call
throws_ok(
    sub { AIR2::Email->send_single( $email->email_id, $TEST_EMAILS[2] ) },
    qr/from a non-prod environment/,
    'single email static - whitelist exception'
);

#
# cleanup
#
$email->delete();
$org->delete();
