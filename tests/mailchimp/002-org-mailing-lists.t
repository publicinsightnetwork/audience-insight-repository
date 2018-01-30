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
use Test::More tests => 35;
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

# work around mailchimp throttling for frequent sub/unsub changes.
# this is necessary mostly during development when we are re-running often.
my $random_tag = $$;

# SEM_STATUS => G - B - U - C (confirmed-bad)
# SOE_STATUS => A - B - U - E (error)
# src_email.sem_status|src_org_email.soe_status
my %test_statuses = (
    "testsource0.$random_tag\@nosuchemail.org" => 'GA',
    "testsource1.$random_tag\@nosuchemail.org" => 'UU',
    "testsource2.$random_tag\@nosuchemail.org" => 'GB',
    "testsource3.$random_tag\@nosuchemail.org" => 'GA',
    "testsource4.$random_tag\@nosuchemail.org" => 'GA',
);

my @test_sources = sort keys %test_statuses;

#
# setup some src_org_emails
#
ok( my $org = MailchimpUtils::test_org(), "create test org" );

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

ok( my $chimp = MailchimpUtils::client(
        interval => 1,      # speed up tests a little
        org      => $org,
    ),
    "create api adaptor"
);

# clean slate (deactivate all test list emails from mailchimp)
MailchimpUtils::clear_list();

# shortcut
sub compare_list { MailchimpUtils::compare_list(@_) }

MailchimpUtils::debug
    and diag('======================= PUSH TESTS =========================');

my $res;

# initial push of these sources
$res = $chimp->push_list( source => \@sources );
MailchimpUtils::debug and diag dump $res;
is_deeply( $res,
    { cleaned => 0, ignored => 2, subscribed => 3, unsubscribed => 0 },
    "initial push" );

compare_list(
    {   $test_sources[0] => 'subscribed',
        $test_sources[3] => 'subscribed',
        $test_sources[4] => 'subscribed',
    },
    'initial push list_members'
);

# re-subscribe a source
$res = $chimp->push_list( source => $sources[0] );
is( $res->{subscribed}, 1, 're-subscribe - 1' );
compare_list(
    {   $test_sources[0] => 'subscribed',
        $test_sources[3] => 'subscribed',
        $test_sources[4] => 'subscribed',
    },
    "re-subscribe already subscribed source"
);

# unsubscribe a source
$src_org_emails[0]->soe_status('U');
$src_org_emails[0]->save;
$res = $chimp->push_list( source => $sources[0] );
is( $res->{unsubscribed}, 1, 'unsubscribe - 1 unsubscribed' );
compare_list(
    {   $test_sources[3] => 'subscribed',
        $test_sources[4] => 'subscribed',
    },
    "unsubscribe subscribed source"
);

# re-unsubscribe a source
$res = $chimp->push_list( email => $test_sources[0] );
is( $res->{unsubscribed}, 0, "already unsubscribed $test_sources[0]" );
compare_list(
    {   $test_sources[3] => 'subscribed',
        $test_sources[4] => 'subscribed',
    },
    "re-unsubscribe source"
);

# subscribe unsub'd and a bounced
$src_org_emails[0]->soe_status('A');
$src_org_emails[0]->save;
$src_org_emails[2]->soe_status('A');
$src_org_emails[2]->save;
$res = $chimp->push_list( source => [ $sources[0], $sources[2] ] );
MailchimpUtils::debug and diag dump $res;
is_deeply( $res, { cleaned => 0, ignored => 0, subscribed => 2 },
    "2 subscribed" );
compare_list(
    {   $test_sources[0] => 'subscribed',
        $test_sources[2] => 'subscribed',
        $test_sources[3] => 'subscribed',
        $test_sources[4] => 'subscribed',
    },
    "re-subscribe sources"
);

# bounce a source
# NOTE bounces (i.e. cleaned) are treated like unsubscribes at Mailchimp
# except that bounces cannot be re-subscribed.
$src_org_emails[2]->soe_status('B');
$src_org_emails[2]->save;
$res = $chimp->push_list( source => [ $sources[0], $sources[2] ] );
MailchimpUtils::debug and diag dump $res;
is_deeply(
    $res,
    { unsubscribed => 1, ignored => 0, subscribed => 1, cleaned => 0 },
    "push list with bounced $test_sources[2]"
);
compare_list(
    {   $test_sources[0] => 'subscribed',
        $test_sources[3] => 'subscribed',
        $test_sources[4] => 'subscribed',
    },
    "re-subscribe sources"
);

MailchimpUtils::debug
    and
    diag('======================== PULL TESTS ===========================');

# status should be up-to-date
$res = $chimp->pull_list( source => \@sources );
MailchimpUtils::debug and diag dump $res;
is_deeply(
    $res,
    { ignored => 5, subscribed => 0, unsubscribed => 0 },
    "initial state of pull tests"
);
compare_list(
    {   $test_sources[0] => 'subscribed',
        $test_sources[3] => 'subscribed',
        $test_sources[4] => 'subscribed',
    },
    "initial state of member list for pull tests"
);

# but that should delete stale soe records
ok( $src_org_emails[0]->load_speculative,  'check - subscribed record okay' );
ok( !$src_org_emails[1]->load_speculative, 'check - unsub record deleted' );
ok( !$src_org_emails[2]->load_speculative, 'check - bounced record deleted' );

# simulate unsub through mailchimp (they don't delete)
$chimp->unsubscribe( [ $test_sources[0] ] );
$res = $chimp->pull_list( email => $test_sources[0] );
MailchimpUtils::debug and diag dump $res;
is( $res->{unsubscribed}, 1, 'mailchimp unsub - 1 unsubscribed' );
ok( $src_org_emails[0]->load_speculative, 'mailchimp unsub - reload' );
is( $src_org_emails[0]->soe_status, 'U', 'mailchimp unsub - soe_status' );

# now try to resubscribe the source
$src_org_emails[0]->soe_status('A');
$src_org_emails[0]->save;
$res = $chimp->push_list( email => $test_sources[0] );
MailchimpUtils::debug and diag dump $res;
is( $res->{subscribed}, 1, 'mailchimp unsub - resub works' );

#
# ADVANCED PARAMETERS
#

# push everything
# NOTE: above tests deleted 2 src_org_email records, so now only 3
$src_org_emails[0]->soe_status('U');
$src_org_emails[0]->save;
$res = $chimp->push_list( all => 1 );
MailchimpUtils::debug and diag dump $res;
is_deeply( $res,
    { subscribed => 2, unsubscribed => 1, ignored => 0, cleaned => 0 },
    "push all" );
is( $res->{subscribed},   2, 'push all - 2 subscribed' );
is( $res->{unsubscribed}, 1, 'push all - 1 unsubscribed' );
is( $res->{ignored},      0, 'push all - 0 ignored' );
compare_list(
    {   $test_sources[3] => 'subscribed',
        $test_sources[4] => 'subscribed',
    },
    "unsubscribed $test_sources[0]"
);

# pull everything
$chimp->subscribe( [ $test_sources[1] ] );
$res = $chimp->pull_list( all => 1 );
MailchimpUtils::debug and diag dump $res;
is_deeply( $res, { subscribed => 1, ignored => 2, unsubscribed => 0 },
    "pull all" );
compare_list(
    {   $test_sources[1] => 'subscribed',
        $test_sources[3] => 'subscribed',
        $test_sources[4] => 'subscribed',
    },
    "subscribed $test_sources[1]"
);

# pull changes since a timestamp
$chimp->unsubscribe( [ $test_sources[4] ] );
$res = $chimp->pull_list( since => 1 );
MailchimpUtils::debug and diag dump $res;
is_deeply(
    $res,
    { ignored => 1, subscribed => 0, unsubscribed => 1 },
    "out-of-band unsubscribe pulled, recent subscribe ignored (already synced)"
);
is( $res->{subscribed},   0, 'pull timestamp - 0 subscribed' );
is( $res->{unsubscribed}, 1, 'pull timestamp - 1 unsubscribed' );
is( $res->{ignored},      1, 'pull timestamp - 1 ignored' );
compare_list(
    {   $test_sources[1] => 'subscribed',
        $test_sources[3] => 'subscribed',
        $test_sources[4] => 'unsubscribed',
    },
    "unsubscribed $test_sources[4]"
);
