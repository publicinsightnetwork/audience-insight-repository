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
use Test::More tests => 30;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use lib "$FindBin::Bin/../search/models";
use JSON;
use Data::Dump qw( dump );
use WWW::Mailchimp;

use AIR2::Config;
use AIR2::Mailchimp;
use AIR2::Utils;

use AIR2Test::User;
use AIR2Test::Organization;
use AIR2Test::Source;

my $TEST_LIST_ID = '8992dc9e18';    # TODO get AIR2_EMAIL_LIST_ID ?

my @test_sources = qw(
    testsource1@nosuchemail.org
    testsource2@nosuchemail.org
    testsource3@nosuchemail.org
    testsource4@nosuchemail.org
    testsource5@nosuchemail.org
);

# SEM_STATUS => G - B - U - C (confirmed-bad)
# SOE_STATUS => A - B - U - E (error)
# src_email.sem_status|src_org_email.soe_status
my %test_statuses = qw(
    testsource1@nosuchemail.org  GA
    testsource2@nosuchemail.org  UU
    testsource3@nosuchemail.org  GB
    testsource4@nosuchemail.org  GA
    testsource5@nosuchemail.org  GA
);

#
# setup some src_org_emails
#
ok( my $org = AIR2Test::Organization->new(
        org_default_prj_id => 1,
        org_name           => 'mailchimp-test-org',
        )->load_or_save(),
    "create test org"
);

my @sources;
my @src_org_emails;
for my $e (@test_sources) {
    my $src = AIR2Test::Source->new( src_username => $e )->load_or_save;
    push @sources, $src;

    # statuses
    my $sem_status = substr( $test_statuses{$e}, 0, 1 );
    my $soe_status = substr( $test_statuses{$e}, 1, 1 );

    # add emails
    $src->add_emails( [ { sem_email => $e, sem_status => $sem_status } ] );
    $src->add_organizations( [$org] );
    $src->save();
    AIR2::SrcOrgCache::refresh_cache($src);

    # add src_org_emails
    my $soe = {
        soe_org_id      => $org->org_id,
        soe_status      => $soe_status,
        soe_status_dtim => time(),
        soe_type        => 'M',
    };
    for my $sem ( @{ $src->emails } ) {
        $sem->add_src_org_emails( [$soe] );
        $sem->save();
        push @src_org_emails, $sem->src_org_emails->[-1];
    }
}

#
# adaptor setup
#

ok( my $chimp = AIR2::Mailchimp->new( org => $org, ), "create api adaptor" );

# clean slate (delete all these emails from mailchimp)
$chimp->api->listBatchUnsubscribe(
    id            => $TEST_LIST_ID,
    emails        => [@test_sources],
    delete_member => 1,
    send_goodbye  => 0,
    send_notify   => 0,
);

#
# YE OLDE PUSH_LIST TESTS
#
my $res;

# initial push of these sources
$res = $chimp->push_list( source => \@sources );
is( $res->{subscribed},   3, 'init - 3 subscribed' );
is( $res->{unsubscribed}, 0, 'init - 0 unsubscribed' );
is( $res->{ignored},      2, 'init - 2 ignored' );

# re-subscribe a source
$res = $chimp->push_list( source => $sources[0] );
is( $res->{ignored}, 1, 're-subscribe - 1 ignored' );

# unsubscribe a source
$src_org_emails[0]->soe_status('U');
$src_org_emails[0]->save;
$res = $chimp->push_list( source => $sources[0] );
is( $res->{unsubscribed}, 1, 'unsubscribe - 1 unsubscribed' );

# re-unsubscribe a source
$res = $chimp->push_list( email => $test_sources[0] );
is( $res->{ignored}, 1, 're-unsubscribe - 1 ignored' );

# subscribe unsub'd and a bounced
$src_org_emails[0]->soe_status('A');
$src_org_emails[0]->save;
$src_org_emails[2]->soe_status('A');
$src_org_emails[2]->save;
$res = $chimp->push_list( source => [ $sources[0], $sources[2] ] );
is( $res->{subscribed}, 2, 'subscribe - 2 subscribed' );

# bounce a source
$src_org_emails[2]->soe_status('B');
$src_org_emails[2]->save;
$res = $chimp->push_list( source => [ $sources[0], $sources[2] ] );
is( $res->{unsubscribed}, 1, 'bounce - 1 unsubscribed' );
is( $res->{ignored},      1, 'bounce - 1 ignored' );

#
# YE OLDE PULL_LIST TESTS
#

# status should be up-to-date
$res = $chimp->pull_list( source => \@sources );
is( $res->{subscribed},   0, 'check - 0 subscribed' );
is( $res->{unsubscribed}, 0, 'check - 0 unsubscribed' );
is( $res->{ignored},      5, 'check - 5 ignored' );

# but that should delete stale soe records
ok( $src_org_emails[0]->load_speculative,  'check - subscribed record okay' );
ok( !$src_org_emails[1]->load_speculative, 'check - unsub record deleted' );
ok( !$src_org_emails[2]->load_speculative, 'check - bounced record deleted' );

# simulate unsub through mailchimp (they don't delete)
$chimp->api->listUnsubscribe(
    id            => $TEST_LIST_ID,
    email_address => $test_sources[0],
    delete_member => 0,
    send_goodbye  => 0,
    send_notify   => 0,
);
$res = $chimp->pull_list( email => $test_sources[0] );
is( $res->{unsubscribed}, 1, 'mailchimp unsub - 1 unsubscribed' );
ok( $src_org_emails[0]->load_speculative, 'mailchimp unsub - reload' );
is( $src_org_emails[0]->soe_status, 'U', 'mailchimp unsub - soe_status' );

# now try to resubscribe the source
$src_org_emails[0]->soe_status('A');
$src_org_emails[0]->save;
$res = $chimp->push_list( email => $test_sources[0] );
is( $res->{subscribed}, 1, 'mailchimp unsub - resub works' );

#
# ADVANCED PARAMETERS
#

# push everything
# NOTE: above tests deleted 2 src_org_email records, so now only 3
$src_org_emails[0]->soe_status('U');
$src_org_emails[0]->save;
$res = $chimp->push_list( all => 1 );
is( $res->{subscribed},   0, 'push all - 0 subscribed' );
is( $res->{unsubscribed}, 1, 'push all - 1 unsubscribed' );
is( $res->{ignored},      2, 'push all - 2 ignored' );

# pull everything
# TODO: may need to refactor this if test mailing list gets too bloated
$chimp->api->listSubscribe(
    id                => $TEST_LIST_ID,
    email_address     => $test_sources[1],
    double_optin      => 0,
    update_existing   => 1,
    replace_interests => 0,
    send_welcome      => 0,
);
$res = $chimp->pull_list( all => 1 );
ok( $res->{subscribed} >= 1,   'pull all - >= 1 subscribed' );
ok( $res->{unsubscribed} >= 0, 'pull all - >= 0 unsubscribed' );
ok( $res->{ignored} >= 3,      'pull all - >= 3 ignored' );

# pull changes since a timestamp
$chimp->api->listUnsubscribe(
    id            => $TEST_LIST_ID,
    email_address => $test_sources[4],
    delete_member => 0,
    send_goodbye  => 0,
    send_notify   => 0,
);
$res = $chimp->pull_list( since => 1 );
is( $res->{subscribed},   1, 'pull timestamp - 1 subscribed' );
is( $res->{unsubscribed}, 1, 'pull timestamp - 1 unsubscribed' );
is( $res->{ignored},      0, 'pull timestamp - 0 ignored' );
