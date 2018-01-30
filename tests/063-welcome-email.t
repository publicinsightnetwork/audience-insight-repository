#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 10;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use lib 'tests/search';
use AIR2TestUtils;
use AIR2::Utils;
use AIR2Test::User;
use AIR2Test::Organization;
use AIR2Test::Source;
use AIR2::WelcomeEmail;
use Data::Dump qw( dump );

my $TEST_USERNAME = 'haroldblah';

ok( my $org = AIR2Test::Organization->new(
        org_default_prj_id => 1,
        org_name           => 'i-am-a-test-org',
        )->load_or_save(),
    "create test org"
);

ok( $org->load_or_save, "org->load_or_save" );

ok( my $source = AIR2Test::Source->new(
        src_username   => $TEST_USERNAME,
        src_first_name => "Harold",
        src_last_name  => "Bláh",
    ),
    "new source"
);
ok( $source->set_preference( { preferred_language => 'es_US' } ),
    "set source preferred language" );
ok( $source->add_emails(
        [   {   sem_email        => $TEST_USERNAME . '@nosuchemail.org',
                sem_primary_flag => 1,
            }
        ]
    ),
    "add email address"
);
ok( $source->save, "source->save" );

ok( my $welcome = AIR2::WelcomeEmail->new(
        source  => $source,
        org     => $org,
        dry_run => 1
    ),
    "WelcomeEmail->new"
);
ok( my $sent = $welcome->send, "welcome->send" );

is_deeply(
    $sent->{template_vars}->{source},
    {   email => $TEST_USERNAME . '@nosuchemail.org',
        name  => "Harold Bl\xE1h"
    },
    "template_vars->source"
);
is( $sent->{template_vars}->{locale}, "es_US", "template_vars->locale" );

#diag( dump $sent );
