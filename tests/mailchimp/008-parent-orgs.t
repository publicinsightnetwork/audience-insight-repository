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
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use lib "$FindBin::Bin/../search/models";
use lib "$FindBin::Bin";
use JSON;
use Data::Dump qw( dump );

use AIR2::Config;
use AIR2::Mailchimp;
use AIR2::Utils;

use AIR2Test::User;
use AIR2Test::Organization;
use AIR2Test::Source;

use MailchimpUtils;

my $random_str   = $$;
my $i            = 0;
my @test_sources = ();
while ( $i < 3 ) {
    push @test_sources, "testsource${i}.$random_str\@nosuchemail.org";
    $i++;
}

#
# setup org and parents
#
ok( my $mega_parent = AIR2Test::Organization->new(
        org_default_prj_id => 1,
        org_name           => 'mailchimp-test-top-org',
        )->load_or_save(),
    "create test parent org"
);
ok( my $parent = AIR2Test::Organization->new(
        org_parent_id      => $mega_parent->org_id,
        org_default_prj_id => 1,
        org_name           => 'mailchimp-test-parent-org',
        )->load_or_save(),
    "create test parent org"
);
ok( my $org = MailchimpUtils::test_org( org_parent_id => $parent->org_id, ),
    "create test org" );
$org->org_sys_id(
    [ { osid_type => 'M', osid_xuuid => MailchimpUtils::list_id } ] );
ok( $org->save, "create test org_sys_id" );
ok( my $chimp = MailchimpUtils::client( org => $org ), "create api adaptor" );

# start clean
MailchimpUtils::clear_campaigns;
MailchimpUtils::clear_segments;
MailchimpUtils::clear_list;

# setup sources
my $idx = -1;
my @sources;
for my $e (@test_sources) {
    my $src = AIR2Test::Source->new( src_username => $e )->load_or_save;
    $src->add_emails( [ { sem_email => $e, sem_status => 'G' } ] );

    # pick different orgs to opt into
    my $my_org = $org->org_id;
    $my_org = $parent->org_id      if $e eq $test_sources[1];
    $my_org = $mega_parent->org_id if $e eq $test_sources[2];
    $src->add_src_orgs( [ { so_org_id => $my_org, so_status => 'A' } ] );
    $src->save();
    AIR2::SrcOrgCache::refresh_cache($src);

    # cache a reference
    $sources[ ++$idx ] = $src;
}

#
# YE OLDE TESTS
#

# make sure everybody syncs
my $res = $chimp->sync_list( source => \@sources );
is_deeply(
    $res,
    { cleaned => 0, ignored => 0, subscribed => 3 },
    "setup complete"
);

# unsubscribe somebody
$sources[1]->src_orgs->[0]->so_status('D');
$sources[1]->src_orgs->[0]->save();
AIR2::SrcOrgCache::refresh_cache( $sources[1] );

# sync again
my $res2 = $chimp->sync_list( source => \@sources );
MailchimpUtils::compare_list(
    {   $test_sources[2] => 'subscribed',
        $test_sources[0] => 'subscribed',
    },
    "unsubscribed $test_sources[1]"
);
is_deeply(
    $res2,
    { cleaned => 0, ignored => 0, subscribed => 2, unsubscribed => 1 },
    "unsubscribed $test_sources[1]"
);

