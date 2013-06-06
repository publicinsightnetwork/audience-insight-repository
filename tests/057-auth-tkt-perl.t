#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib/perl';
use lib 'tests/search/models';
use Test::More tests => 10;
use AIR2::Utils;
use AIR2Test::User;
use AIR2Test::Organization;
use Data::Dump qw( dump );
use JSON;

ok( my $org = AIR2Test::Organization->new(
        org_default_prj_id => 1,
        org_name           => 'i-am-a-test-org',
        )->load_or_save(),
    "create test org"
);
ok( my $user = AIR2Test::User->new(
        user_username   => 'i-am-a-test-user',
        user_first_name => 'i',
        user_last_name  => 'test',
    ),
    "new test user"
);
ok( $user->organizations($org), "add org to user" );
ok( $user->load_or_save(),      "save test user" );
ok( $user->set_role_for_org( 'R', $org->org_id ),
    "set user to Reader in org" );

ok( my $tkt = $user->create_tkt(),          "create auth tkt" );
ok( my $at  = $user->get_new_air2_auth_tkt, "get AIR2::AuthTkt object" );
ok( $at->valid_ticket($tkt), "ticket is valid" );
ok( my $authz = AIR2::Utils::unpack_authz(
        decode_json( $at->parse_ticket($tkt)->{data} )->{authz}
    ),
    "get authz"
);
my $user_authz = $user->get_authz;

#diag( dump $user_authz );
#diag( dump $authz );
is_deeply( $authz, $user_authz, "authz roundtrip struct" );

#diag( dump $at->parse_ticket($tkt) );
