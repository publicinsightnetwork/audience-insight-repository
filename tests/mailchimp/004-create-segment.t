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
use Test::More tests => 16;
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

# test sources
my @test_sources = qw(
    testsource0@nosuchemail.org
    testsource1@nosuchemail.org
    testsource2@nosuchemail.org
    testsource3@nosuchemail.org
    testsource4@nosuchemail.org
    testsource5@nosuchemail.org
);

# status codes (in this order)
# SO_STATUS  => A - D - F - X
# SEM_STATUS => G - B - U - C
# SOE_STATUS => A - B - U - E (initially pushed remote value)
my %test_statuses = qw(
    testsource0@nosuchemail.org   AGA
    testsource1@nosuchemail.org   AGA
    testsource2@nosuchemail.org   AGA
    testsource3@nosuchemail.org   AGA
    testsource4@nosuchemail.org   ABB
    testsource5@nosuchemail.org   DGU
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
$org->org_sys_id( [ { osid_type => 'M', osid_xuuid => $TEST_LIST_ID } ] );
ok( $org->save, "create test org_sys_id" );
ok( my $chimp = AIR2::Mailchimp->new( org => $org ), "create api adaptor" );

# setup sources (and some quick lookup arrays)
my $idx = -1;
my @sources;
my @src_orgs;
my @src_emails;
my @src_org_emails;
for my $e ( @test_sources ) {
    my $src = AIR2Test::Source->new( src_username => $e )->load_or_save;
    $sources[++$idx] = $src;

    # statuses
    my $so_status  = substr( $test_statuses{$e}, 0, 1 );
    my $sem_status = substr( $test_statuses{$e}, 1, 1 );
    my $soe_status = substr( $test_statuses{$e}, 2, 1 );

    # add src_orgs
    if ( $so_status ne '?' ) {
        my $so = { so_org_id => $org->org_id, so_status => $so_status };
        $src->add_src_orgs( [ $so ] );
        $src->save();
        $src_orgs[$idx] = $src->src_orgs->[-1];
    }

    # add src_emails
    if ( $sem_status ne '?' ) {
        $src->add_emails( [ { sem_email => $e, sem_status => $sem_status } ] );
        $src->save();
        $src_emails[$idx] = $src->emails->[-1];
    }
    AIR2::SrcOrgCache::refresh_cache($src);

    # add src_org_emails
    if ( $soe_status ne '?' ) {
        my $soe = {
            soe_org_id      => $org->org_id,
            soe_status      => $soe_status,
            soe_status_dtim => time(),
            soe_type        => 'M',
        };
        $src_emails[$idx]->add_src_org_emails( [ $soe ] );
        $src_emails[$idx]->save();
        $src_org_emails[$idx] = $src_emails[$idx]->src_org_emails->[-1];
    }
}

# make sure mailchimp is on the same page
my $res = $chimp->sync_list( source => \@sources );
my $tot = $res->{ignored} + $res->{subscribed} + $res->{unsubscribed};
is( $tot, 6, 'setup - 6 total' );

#
# YE OLDE TESTS
#

# segment with everything
my $seg_base = '004-create-segment';
$res = $chimp->make_segment( source => \@sources, name => $seg_base );
my %skipped = map { $_->src_id => 1 } @{ $res->{skip_list} };
my $seg1_name = $res->{name};
my $seg1_id = $res->{id};

is( $res->{added}, 4, 'segment all - 4 added' );
is( $res->{skipped}, 2, 'segment all - 2 skipped' );
is( scalar keys %skipped, 2, 'segment all - 2 skip_list' );
ok( $skipped{ $sources[4]->src_id }, 'segment all - skipped source 4' );
ok( $skipped{ $sources[5]->src_id }, 'segment all - skipped source 5' );

# run another segment with same name
$res = $chimp->make_segment( source => $sources[0], name => $seg_base );
is( $res->{added}, 1, 'segment single - 1 added' );
is( $res->{skipped}, 0, 'segment single - 0 skipped' );
isnt( $res->{id}, $seg1_id, 'segment single - id changed' );
isnt( $res->{name}, $seg1_name, 'segment single - name changed' );

# try adding a segment with a really long name
my $long_name = "$seg_base with enough text to push this over 50 characters";
$res = $chimp->make_segment( source => $sources[0], name => $long_name );

is( $res->{added}, 1, 'segment single - 1 added' );
is( $res->{skipped}, 0, 'segment single - 0 skipped' );
ok( length($long_name) > length($res->{name}), 'long name - name truncated' );

#
# cleanup (optional, but nice)
#
$res = $chimp->api->listStaticSegments(id => $TEST_LIST_ID);
for my $ss ( @{ $res } ) {
    if ( $ss->{name} =~ /^004-create-segment/ ) {
        # diag("* cleaning up $ss->{name}\n");
        $chimp->api->listStaticSegmentDel(id => $TEST_LIST_ID, seg_id => $ss->{id});
    }
}
