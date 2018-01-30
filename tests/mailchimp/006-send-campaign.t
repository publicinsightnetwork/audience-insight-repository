#!/usr/bin/env perl
###########################################################################
#
#   Copyright 2010 American Public Media Group
#
#   This file is part of AIR2.
#
#   AIR2 is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   AIR2 is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
#
###########################################################################

use strict;
use warnings;
use Test::More tests => 21;
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use lib "$FindBin::Bin/../search/models";
use lib "$FindBin::Bin";
use JSON;
use Data::Dump qw( dump );
use Date::Parse;
use DateTime;

use AIR2::Config;
use AIR2::Mailchimp;
use AIR2::Utils;

use AIR2Test::User;
use AIR2Test::Organization;
use AIR2Test::Source;
use AIR2Test::Email;

use MailchimpUtils;

# test sources
my @test_sources = ();
my %seen         = ();
while ( scalar(@test_sources) < 3 ) {

    # all the pin0-99 @pinsight.org addresses are forwarded to the same
    # email address, so pick a random number in that range.
    # we randomize so as not to run afoul of MC throttling.
    my $random = 0 + int( rand(99) );
    my $email  = "pin${random}\@pinsight.org";
    push @test_sources, $email unless $seen{$email}++;
}

#
# setup an org with some src_org_emails
#
ok( my $user = AIR2Test::User->new(
        user_username   => 'i-am-a-test-user',
        user_first_name => 'i',
        user_last_name  => 'test',
        )->load_or_save(),
    "new test user"
);
ok( my $org = MailchimpUtils::test_org(), "create test org" );
$org->org_sys_id(
    [ { osid_type => 'M', osid_xuuid => MailchimpUtils::list_id } ] );
ok( $org->save, "create test org_sys_id" );
ok( my $chimp = MailchimpUtils::client( org => $org ), "create api adaptor" );

# start clean
MailchimpUtils::clear_campaigns;
MailchimpUtils::clear_segments;
MailchimpUtils::clear_list;

# setup sources
my @sources;
for my $e (@test_sources) {
    my $src = AIR2Test::Source->new( src_username => $e )->load_or_save;
    push @sources, $src;

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
    $src->emails->[-1]->add_src_org_emails( [$soe] );
    $src->emails->[-1]->save();
}

# make sure mailchimp is on the same page
my $res = $chimp->sync_list( source => \@sources );
is_deeply(
    $res,
    { cleaned => 0, ignored => 0, subscribed => 3 },
    "setup complete"
);

# test email
$user->add_signatures( [ { usig_text => 'blah blah blah' } ] );
$user->save();
my $email = AIR2Test::Email->new(
    email_org_id        => $org->org_id,
    email_usig_id       => $user->signatures->[-1]->usig_id,
    email_campaign_name => 'Test 006-send-campaign',
    email_from_name     => $user->user_username,
    email_from_email    => 'pijdev@mpr.org',
    email_subject_line  => 'Test 006-send-campaign',
    email_headline      => 'Test 006-send-campaign',
    email_body          => 'This is the body of the email',
    email_status        => 'A',
)->save();

#
# YE OLDE TESTS
#

# setup segment
my $seg_base = '006-send-campaign';
$res = $chimp->make_segment( source => \@sources, name => $seg_base );
is( $res->{added},   3, 'segment setup - 3 added' );
is( $res->{skipped}, 0, 'segment setup - 0 skipped' );
my $segid = $res->{id};

# create campaign
$res = $chimp->make_campaign( template => $email, segment => $segid );
ok( $res->{id}, 'campaign created' );
is( $res->{count}, 3, 'campaign shows 3 in segment' );
my $campid = $res->{id};

# schedule to run in the future (check timezone conversions)
my $delay_my_tz = DateTime->now( time_zone => $AIR2::Config::TIMEZONE );
$delay_my_tz = $delay_my_tz->add( minutes => 10 );
$res = $chimp->send_campaign( campaign => $campid, delay => $delay_my_tz );
is( $res->{code}, '204', 'campaign will be sent later' );

# check the scheduling
$res = $chimp->api->campaign( campaign_id => $campid );
ok( my $camp = $res->{content}, 'campaign delay - api response' );
is( $camp->{id},          $campid,    'campaign delay - api match' );
is( $camp->{emails_sent}, 0,          'campaign delay - emails sent' );
is( $camp->{status},      'schedule', 'campaign delay - status' );
ok( $camp->{send_time}, 'campaign delay - send time' );
cmp_ok( str2time( $camp->{send_time}, 'UTC' ),
    '>=', $delay_my_tz->epoch(), 'campaign delay - epochs align' );
ok( $res = $chimp->api->unschedule_campaign( campaign_id => $campid ),
    'campaign delay - unschedule' );

# run one now
if ( $ENV{MAILCHIMP_TEST_SEND} ) {
    $res = $chimp->send_campaign( campaign => $campid );
    is( $res->{code}, '204', 'campaign send - success' );

    my $campaign;

    # check periodically to see if we've sent them
    for ( my $i = 0; $i < 10; $i++ ) {
        sleep 5;
        $campaign = $chimp->campaign($campid);

        diag dump $campaign;

        if ( $campaign->{status} eq 'sent' ) {
            last;
        }
        elsif ( $campaign->{status} ne 'sending' ) {
            diag("*STATUS ERROR: $campaign->{status}");
            last;
        }
    }

    # now the status should be correct
    is( $campaign->{emails_sent}, 3,      'campaign send - emails sent' );
    is( $campaign->{status},      'sent', 'campaign send - status' );
    ok( $campaign->{send_time}, 'campaign send - send time' );
}
else {
    pass('campaign send - success **SKIPPED');
    pass('campaign send - emails sent **SKIPPED');
    pass('campaign send - status **SKIPPED');
    pass('campaign send - send time **SKIPPED');
}

$org = undef;

