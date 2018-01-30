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
use Test::More tests => 7;
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

# how big of a test do you want to run?
#   - 100 goes fast (default for smoketests)
#   - 1000 will take about 120 seconds
#   - 10000 will take about 1200 seconds
# TODO: optimize speed! why is this linear?
my $TEST_SIZE = 100;
if ( $ENV{MAILCHIMP_TEST_SIZE} ) {
    $TEST_SIZE = $ENV{MAILCHIMP_TEST_SIZE};
}

# lots of test sources
my $random_str = $$;
my @test_sources;
for ( my $i = 0; $i < $TEST_SIZE; $i++ ) {
    push @test_sources, "stresstest$i.$random_str\@nosuchemail.org";
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
ok( my $chimp = MailchimpUtils::client(
        org           => $org,
        api_page_size => $ENV{MAILCHIMP_PAGE_SIZE},
    ),
    "create api adaptor"
);

# start clean
diag("clear campaigns");
MailchimpUtils::clear_campaigns;
diag("clear segments");
MailchimpUtils::clear_segments;
diag("clear list");
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
pass('setup - sources created');

#
# Sync them all!
#
diag("starting sync_list");
my $start = time;
my $res   = $chimp->sync_list(
    source  => \@sources,
    timings => 1,
);
diag dump $res;
my $dur = time - $start;
diag("sync_list took $dur seconds");

my $timings = delete $res->{timings};

my $okay_dur = int( $TEST_SIZE / 5 );
cmp_ok( $dur, '<=', $okay_dur,
    "sync list - executed in <= $okay_dur seconds" );
is_deeply(
    $res,
    { cleaned => 0, ignored => 0, subscribed => $TEST_SIZE },
    "subscribed every user in test"
);

diag("calling sync_list for 2nd time");
my $res2 = $chimp->sync_list(
    source  => \@sources,
    timings => 1,
    since   => 1,
);
diag dump $res2;

$org->delete;    # clean manually to avoid DESTROY order bug
