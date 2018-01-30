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
use Test::More tests => 80;
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

# shortcut
sub compare_list { MailchimpUtils::compare_list(@_) }

my $random_str = $$;

# create a distinct source for each test case
my @test_sources  = ();
my %test_statuses = ();

# status codes (in this order)
# SO_STATUS  => A - D - F - X
# SEM_STATUS => G - B - U - C
# SOE_STATUS => A - B - U - E (initially pushed remote value)
my @status_codes = qw(
    AG?
    DG?
    AU?
    AGA
    FGU
    AGU
    DGA
    AUA
    AGU
    AGU
    FGA
    ?GA
);

my $i = 0;
for my $code (@status_codes) {
    my $email = "testsource$i.$random_str\@nosuchemail.org";
    push @test_sources, $email;
    $test_statuses{$email} = $code;
    $i++;
}

#
# setup an org with some src_org_emails
#
ok( my $org = MailchimpUtils::test_org(), "create test org" );
$org->org_sys_id(
    [ { osid_type => 'M', osid_xuuid => MailchimpUtils::list_id() } ] );
ok( $org->save, "create test org_sys_id" );
ok( my $chimp = MailchimpUtils::client( org => $org ), "create api adaptor" );

# clean slate (delete all these emails from mailchimp)
MailchimpUtils::clear_list();

# setup sources (and some quick lookup arrays)
my $idx = -1;
my @sources;
my @src_orgs;
my @src_emails;
my @src_org_emails;
for my $e (@test_sources) {
    my $src = AIR2Test::Source->new( src_username => $e )->load_or_save;
    $sources[ ++$idx ] = $src;

    # statuses
    my $so_status  = substr( $test_statuses{$e}, 0, 1 );
    my $sem_status = substr( $test_statuses{$e}, 1, 1 );
    my $soe_status = substr( $test_statuses{$e}, 2, 1 );

    # add src_orgs
    if ( $so_status ne '?' ) {
        my $so = { so_org_id => $org->org_id, so_status => $so_status };
        $src->add_src_orgs( [$so] );
        $src->save();
        $src_orgs[$idx] = $src->src_orgs->[-1];
    }

    # add src_emails
    if ( $sem_status ne '?' ) {
        $src->add_emails(
            [ { sem_email => $e, sem_status => $sem_status } ] );
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
        $src_emails[$idx]->add_src_org_emails( [$soe] );
        $src_emails[$idx]->save();
        $src_org_emails[$idx] = $src_emails[$idx]->src_org_emails->[-1];
    }

    # manually send status to mailchimp (to make sure unsubs exist there!)
    if ( $soe_status ne '?' ) {
        $chimp->subscribe( [$e] );
        if ( $soe_status ne 'A' ) {
            if ( $soe_status eq 'U' ) {
                $chimp->unsubscribe( [$e] );
            }
            else {
                $chimp->delete( [$e] );
            }
        }
    }
}

#
# TESTS where mailchimp DNE
#
my $res;

# 0) active in AIR, DNE in mailchimp
#    setup:  so_status(A) + sem_status(G) + soe_status(?)
#    expect: soe_status(A) created, MC-subscribed
is( $src_emails[0]->src_org_emails_count,
    0, '0 mailchimp DNE - soe_count before' );

$res = $chimp->sync_list( source => $sources[0] );
$src_emails[0]->load( with => 'src_org_emails' );
is_deeply(
    $res,
    { cleaned => 0, ignored => 0, subscribed => 1 },
    "one subscribed"
);
is( $src_emails[0]->src_org_emails_count,
    1, '0 mailchimp DNE - soe_count after' );
is( $src_emails[0]->src_org_emails->[0]->soe_status,
    'A', '0 mailchimp DNE - soe_status after' );

# 1) inactive in AIR, DNE in mailchimp
#    setup:  so_status(D) + sem_status(G) + soe_status(?)
#    expect: soe_status(U) created, MC-ignored
is( $src_emails[1]->src_org_emails_count,
    0, '1 mailchimp DNE - soe_count before' );

$res = $chimp->sync_list( source => $sources[1] );
$src_emails[1]->load( with => 'src_org_emails' );

is( $res->{subscribed},   0, '1 mailchimp DNE - 0 subscribed' );
is( $res->{unsubscribed}, 0, '1 mailchimp DNE - 0 unsubscribed' );
is( $res->{ignored},      1, '1 mailchimp DNE - 1 ignored' );
is( scalar @{ $src_emails[1]->src_org_emails },
    1, '1 mailchimp DNE - soe_count after' );
is( $src_emails[1]->src_org_emails->[0]->soe_status,
    'U', '1 mailchimp DNE - soe_status after' );

# 2) email inactive in AIR, DNE in mailchimp
#    setup:  so_status(A) + sem_status(U) + soe_status(?)
#    expect: MC-ignored
is( scalar @{ $src_emails[2]->src_org_emails },
    0, '2 mailchimp DNE - soe_count before' );

$res = $chimp->sync_list( source => $sources[2] );
$src_emails[2]->load( with => 'src_org_emails' );

is( $res->{subscribed},   0, '2 mailchimp DNE - 0 subscribed' );
is( $res->{unsubscribed}, 0, '2 mailchimp DNE - 0 unsubscribed' );
is( $res->{ignored},      1, '2 mailchimp DNE - 1 ignored' );
is( $src_emails[2]->src_org_emails_count,
    1, '2 mailchimp DNE - soe_count after' );
is( $src_emails[2]->src_org_emails->[0]->soe_status,
    'U', '2 mailchimp DNE - soe_status after' );

#
# TESTS where no conflicts
#

# 3) active in AIR, subscribed in mailchimp
#    setup:  so_status(A) + sem_status(G) + soe_status(A)
#    expect: MC-ignored
$res = $chimp->sync_list( source => $sources[3] );
$src_emails[3]->load();
$src_orgs[3]->load();
$src_org_emails[3]->load();

compare_list(
    {   $test_sources[0]  => 'subscribed',
        $test_sources[3]  => 'subscribed',
        $test_sources[4]  => 'unsubscribed',
        $test_sources[5]  => 'unsubscribed',
        $test_sources[6]  => 'subscribed',
        $test_sources[7]  => 'subscribed',
        $test_sources[8]  => 'unsubscribed',
        $test_sources[9]  => 'unsubscribed',
        $test_sources[10] => 'subscribed',
        $test_sources[11] => 'subscribed'
    },
    "3 all-active list"
);
is_deeply(
    $res,
    { cleaned => 0, ignored => 0, subscribed => 1 },
    "$test_sources[3] subscribed again"
);
is( $src_emails[3]->sem_status,     'G', '3 all-active - sem_status' );
is( $src_orgs[3]->so_status,        'A', '3 all-active - so_status' );
is( $src_org_emails[3]->soe_status, 'A', '3 all-active - soe_status' );

# 4) inactive in AIR, unsubscribed in mailchimp
#    setup:  so_status(F) + sem_status(G) + soe_status(U)
#    expect: MC-ignored (ACTUALLY, it's deleted since our setup step actually
#            added the unsub to MC, and we actively nuke unsubs from MC)
$res = $chimp->sync_list( source => $sources[4] );
$src_emails[4]->load();
$src_orgs[4]->load();
$src_org_emails[4]->load();

is( $res->{subscribed},             0,   '4 all-inactive - 0 subscribed' );
is( $res->{unsubscribed},           1,   '4 all-inactive - 1 unsubscribed' );
is( $res->{ignored},                0,   '4 all-inactive - 0 ignored' );
is( $src_emails[4]->sem_status,     'G', '4 all-inactive - sem_status' );
is( $src_orgs[4]->so_status,        'F', '4 all-inactive - so_status' );
is( $src_org_emails[4]->soe_status, 'U', '4 all-inactive - soe_status' );

#
# TESTS where conflicts exist
#

# 5) unsubscribe happened in mailchimp
#    setup:  so_status(A) + sem_status(G) + soe_status(U)
#            soe_status_dtim > so_upd_dtim
#    expect: so_status(A), sem_status(U), MC-delete/unsub
$src_emails[5]->sem_upd_dtim( $src_emails[5]->sem_upd_dtim->epoch() - 200 );
$src_emails[5]->set_admin_update(1);
$src_emails[5]->save();
$src_orgs[5]->so_upd_dtim( $src_orgs[5]->so_upd_dtim->epoch() - 200 );
$src_orgs[5]->set_admin_update(1);
$src_orgs[5]->save();
$res = $chimp->sync_list( source => $sources[5] );
$src_emails[5]->load();
$src_orgs[5]->load();
$src_org_emails[5]->load();

is( $res->{subscribed},             0,   '5 MC-unsub - 0 subscribed' );
is( $res->{unsubscribed},           1,   '5 MC-unsub - 1 unsub/deleted' );
is( $res->{ignored},                0,   '5 MC-unsub - 0 ignored' );
is( $src_emails[5]->sem_status,     'U', '5 MC-unsub - sem_status' );
is( $src_org_emails[5]->soe_status, 'U', '5 MC-unsub - soe_status' );
is( $src_emails[5]->sem_upd_dtim,
    $src_org_emails[5]->soe_status_dtim,
    '5 MC-unsub - sem_upd_dtim'
);

# NOTE: a mc-unsub only sets the sem_status - so_status stays the same
is( $src_orgs[5]->so_status, 'A', '5 MC-unsub - so_status' );
isnt(
    $src_orgs[5]->so_upd_dtim,
    $src_org_emails[5]->soe_status_dtim,
    '5 MC-unsub - so_upd_dtim'
);

# 6) src_org deactivated manually in AIR
#    setup:  so_status(D) + sem_status(G) + soe_status(A)
#            so_upd_dtim > soe_status_dtim
#    expect: soe_status(U), MC-unsubscribed
$src_orgs[6]->so_upd_dtim( $src_orgs[6]->so_upd_dtim->epoch() + 200 );
$src_orgs[6]->set_admin_update(1);
$src_orgs[6]->save();
$res = $chimp->sync_list( source => $sources[6] );
$src_emails[6]->load();
$src_orgs[6]->load();
$src_org_emails[6]->load();

is( $res->{subscribed},             0,   '6 AIR-deact - 0 subscribed' );
is( $res->{unsubscribed},           1,   '6 AIR-deact - 1 unsub/deleted' );
is( $res->{ignored},                0,   '6 AIR-deact - 0 ignored' );
is( $src_emails[6]->sem_status,     'G', '6 AIR-deact - sem_status' );
is( $src_orgs[6]->so_status,        'D', '6 AIR-deact - so_status' );
is( $src_org_emails[6]->soe_status, 'U', '6 AIR-deact - soe_status' );

# 7) src_email unsubscribed manually in AIR
#    setup:  so_status(A) + sem_status(U) + soe_status(A)
#            sem_upd_dtim > soe_status_dtim
#    expect: soe_status(U), MC-unsubscribed
$src_emails[7]->sem_upd_dtim( $src_emails[7]->sem_upd_dtim->epoch() + 200 );
$src_emails[7]->set_admin_update(1);
$src_emails[7]->save();
$res = $chimp->sync_list( email => $src_emails[7]->sem_email );
$src_emails[7]->load();
$src_orgs[7]->load();
$src_org_emails[7]->load();

is( $res->{subscribed},             0,   '7 AIR-unsub - 0 subscribed' );
is( $res->{unsubscribed},           1,   '7 AIR-unsub - 1 unsub/deleted' );
is( $res->{ignored},                0,   '7 AIR-unsub - 0 ignored' );
is( $src_emails[7]->sem_status,     'U', '7 AIR-unsub - sem_status' );
is( $src_orgs[7]->so_status,        'A', '7 AIR-unsub - so_status' );
is( $src_org_emails[7]->soe_status, 'U', '7 AIR-unsub - soe_status' );

# 8) src_email manually set to good in AIR
#    setup:  so_status(A) + sem_status(G) + soe_status(U)
#            sem_upd_dtim > soe_status_dtim
#    expect: soe_status(A), MC-subscribed
$src_emails[8]->sem_upd_dtim( $src_emails[8]->sem_upd_dtim->epoch() + 200 );
$src_emails[8]->set_admin_update(1);
$src_emails[8]->save();
$res = $chimp->sync_list( source => $sources[8] );
$src_emails[8]->load();
$src_orgs[8]->load();
$src_org_emails[8]->load();
is_deeply(
    $res,
    { cleaned => 0, ignored => 0, subscribed => 1 },
    "$test_sources[8] subscribed via manual change in AIR"
);
compare_list(
    {   $test_sources[0]  => 'subscribed',
        $test_sources[3]  => 'subscribed',
        $test_sources[8]  => 'subscribed',
        $test_sources[9]  => 'unsubscribed',
        $test_sources[10] => 'subscribed',
        $test_sources[11] => 'subscribed'
    },
    "8 $test_sources[8] subscribed via manual change in AIR"
);
is( $src_emails[8]->sem_status,     'G', '8 AIR-re-good - sem_status' );
is( $src_orgs[8]->so_status,        'A', '8 AIR-re-good - so_status' );
is( $src_org_emails[8]->soe_status, 'A', '8 AIR-re-good - soe_status' );

# 9) MC-unsub timestamp tie (with margin-of-error)
#    setup:  so_status(A) + sem_status(G) + soe_status(U)
#            so_upd_dtim =~ soe_status_dtim
#    expect: so_status(A), sem_status(U), mc-delete
#            (Mailchimp wins the tie, in the case of unsubscribe)
$res = $chimp->sync_list( source => $sources[9] );
$src_emails[9]->load();
$src_orgs[9]->load();
$src_org_emails[9]->load();

is( $res->{subscribed},         0,   '9 MC-wins-tie - 0 subscribed' );
is( $res->{unsubscribed},       1,   '9 MC-wins-tie - 1 unsub/deleted' );
is( $res->{ignored},            0,   '9 MC-wins-tie - 0 ignored' );
is( $src_emails[9]->sem_status, 'U', '9 MC-wins-tie - sem_status' );
is( $src_orgs[9]->so_status,    'A', '9 MC-wins-tie - so_status unchanged' );
is( $src_org_emails[9]->soe_status, 'U', '9 MC-wins-tie - soe_status' );

# 10) MC-unsub timestamp tie (with margin-of-error)
#    setup:  so_status(F) + sem_status(G) + soe_status(A)
#            so_upd_dtim =~ soe_status_dtim
#    expect: soe_status(U), mc-unsub
#            (AIR wins the tie, since it's not a MC-unsub)
$res = $chimp->sync_list( source => $sources[10] );
$src_emails[10]->load();
$src_orgs[10]->load();
$src_org_emails[10]->load();

is_deeply(
    $res,
    { cleaned => 0, ignored => 0, subscribed => 0, unsubscribed => 1 },
    "$test_sources[10] unsubscribed via timestamp tie"
);
compare_list(
    {   $test_sources[0]  => 'subscribed',
        $test_sources[3]  => 'subscribed',
        $test_sources[8]  => 'subscribed',
        $test_sources[11] => 'subscribed'
    },
    "10 $test_sources[10] unsubscribed via timestamp tie"
);
is( $src_emails[10]->sem_status,     'G', '10 AIR-wins-tie - sem_status' );
is( $src_orgs[10]->so_status,        'F', '10 AIR-wins-tie - so_status' );
is( $src_org_emails[10]->soe_status, 'U', '10 AIR-wins-tie - soe_status' );

# 10b) Make sure things don't change on the next sync
$res = $chimp->sync_list( source => $sources[10] );
$src_emails[10]->load( with => 'src_org_emails' );
$src_orgs[10]->load();

compare_list(
    {   $test_sources[0]  => 'subscribed',
        $test_sources[3]  => 'subscribed',
        $test_sources[8]  => 'subscribed',
        $test_sources[11] => 'subscribed'
    },
    "10b $test_sources[10] doublecheck"
);
is_deeply(
    $res,
    { cleaned => 0, ignored => 1, subscribed => 0, unsubscribed => 0 },
    "$test_sources[10] was already unsubscribed"
);
is( $src_emails[10]->sem_status, 'G', '10b doublecheck - sem_status' );
is( $src_orgs[10]->so_status,    'F', '10b doublecheck - so_status' );
is( scalar @{ $src_emails[10]->src_org_emails },
    1, '10b doublecheck - soe_count' );
is( $src_emails[10]->src_org_emails->[0]->soe_status,
    'U', '10b doublecheck - soe_status' );

#
# TESTS where insanity
#

# 11) src_org DNE, soe active
#     setup:  so_status(?) + sem_status(G) + soe_status(A)
#     expect: soe-deleted, MC-unsubscribe
is( $src_org_emails[11]->soe_status,
    'A', '11 src_org DNE - soe_status before' );
is( scalar @{ $sources[11]->src_orgs },
    0, '11 src_org DNE - so_count before' );
is( scalar @{ $src_emails[11]->src_org_emails },
    1, '11 src_org DNE - soe_count before' );

$res = $chimp->sync_list( source => $sources[11] );
$src_emails[11]->load( with => 'src_org_emails' );
$sources[11]->load( with => 'src_orgs' );

is( $res->{subscribed},   0, '11 src_org DNE - 0 subscribed' );
is( $res->{unsubscribed}, 1, '11 src_org DNE - 1 unsubscribed' );
is( $res->{ignored},      0, '11 src_org DNE - 0 ignored' );
is( scalar @{ $sources[11]->src_orgs }, 0,
    '11 src_org DNE - so_count after' );
is( scalar @{ $src_emails[11]->src_org_emails },
    0, '11 src_org DNE - soe_count after' );
