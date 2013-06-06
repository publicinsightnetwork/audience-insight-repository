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
use Test::More tests => 8;
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

my $TEST_LIST_ID = '8992dc9e18';

# SEM_STATUS => G - B - U - C (confirmed-bad)
# SOE_STATUS => A - B - U - E (error)
# email => src_email.sem_status|src_org_email.soe_status
my %test_sources = qw(
  testsource1@nosuchemail.org  GA
  testsource2@nosuchemail.org  UU
  testsource3@nosuchemail.org  GA
  testsource4@nosuchemail.org  GA
  testsource5@nosuchemail.org  GA
);

#
# setup an org with some src_org_emails
#
ok(
    my $org = AIR2Test::Organization->new(
        org_default_prj_id => 1,
        org_name           => 'mailchimp-test-org',
      )->load_or_save(),
    "create test org"
);

my @sources;
for my $e ( keys %test_sources ) {
    my $src = AIR2Test::Source->new( src_username => $e )->load_or_save;
    push @sources, $src;

    # statuses
    my $sem_status = substr( $test_sources{$e}, 0, 1 );
    my $soe_status = substr( $test_sources{$e}, 1, 1 );

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
    }
}

#
# adaptor setup
#
throws_ok(
    sub { my $chimp = AIR2::Mailchimp->new( org => $org ) },
    qr/no mailchimp org_sys_id/,
    'no org_sys_id exception thrown'
);

$org->org_sys_id( [ { osid_type => 'M', osid_xuuid => $TEST_LIST_ID } ] );
ok( $org->save, "create test org_sys_id" );

ok( my $chimp = AIR2::Mailchimp->new( org => $org ), "create api adaptor" );

# clean slate (delete all these emails from mailchimp)
$chimp->api->listBatchUnsubscribe(
    id            => $TEST_LIST_ID,
    emails        => [ keys %test_sources ],
    delete_member => 1,
    send_goodbye  => 0,
    send_notify   => 0,
);

#
# YE OLDE TESTS
#
my $res;

# initial push of these sources
$res = $chimp->push_list( source => \@sources );
is( $res->{subscribed},   4, 'init - 4 subscribed' );
is( $res->{unsubscribed}, 0, 'init - 0 unsubscribed' );
is( $res->{ignored},      1, 'init - 1 ignored' );

# re-subscribe a source
$res = $chimp->push_list( source => $sources[0] );
is( $res->{ignored}, 1, 're-subscribe - 1 ignored' );
