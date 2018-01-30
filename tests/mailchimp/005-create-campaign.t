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
use Test::More tests => 10;
use Test::Exception;
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
use AIR2Test::Email;

use MailchimpUtils;

# test sources
my $random_str   = $$;
my $i            = 0;
my @test_sources = ();
while ( $i < 3 ) {
    push @test_sources, "testsource${i}.$random_str\@nosuchemail.org";
    $i++;
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
    { ignored => 0, subscribed => 3, cleaned => 0, },
    "setup subscribers"
);

# test email
$user->add_signatures( [ { usig_text => 'blah blah blah' } ] );
$user->save();
my $email = AIR2Test::Email->new(
    email_org_id        => $org->org_id,
    email_usig_id       => $user->signatures->[-1]->usig_id,
    email_campaign_name => 'Test 005-create-campaign',
    email_from_name     => $user->user_username,
    email_from_email    => 'pijdev@mpr.org',
    email_subject_line  => 'Test 005-create-campaign',
    email_headline      => 'Test 005-create-campaign',
    email_body          => 'This is the body of the email',
)->save();

#
# YE OLDE TESTS
#

# setup segment
my $seg_base = '005-create-campaign';
$res = $chimp->make_segment( source => \@sources, name => $seg_base );
is( $res->{added},   3, 'segment setup - 3 added' );
is( $res->{skipped}, 0, 'segment setup - 0 skipped' );
my $segid = $res->{id};

# create from draft email
throws_ok(
    sub { $chimp->make_campaign( template => $email, segment => $segid ) },
    qr/Email not active/,
    'from draft - throws exception'
);
$email->email_status('A');
$email->save();

# create campaign
$res = $chimp->make_campaign( template => $email, segment => $segid );
ok( $res->{id}, 'campaign created' );
is( $res->{count}, 3, 'campaign shows 3 in segment' );

