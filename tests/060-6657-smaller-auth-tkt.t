#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib/perl';
use lib 'tests/search/models';
use Test::More tests => 19;
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
ok( my $child_org = AIR2Test::Organization->new(
        org_default_prj_id => 1,
        org_name           => 'i-am-a-test-org-child',
        org_parent_id      => $org->org_id,
        )->load_or_save(),
    "create test child org"
);
ok( my $grandchild_org = AIR2Test::Organization->new(
        org_default_prj_id => 1,
        org_name           => 'i-am-a-test-org-grandchild',
        org_parent_id      => $child_org->org_id,
        )->load_or_save(),
    "create test grandchild org"
);

ok( my $user = AIR2Test::User->new(
        user_username   => 'i-am-a-test-user',
        user_first_name => 'i',
        user_last_name  => 'test',
    ),
    "new test user"
);
ok( $user->organizations($child_org), "add child_org to user" );
ok( $user->load_or_save(),            "save test user" );
ok( $user->set_role_for_org( 'R', $child_org->org_id ),
    "set user to Reader in org" );

#diag( "org:" . $org->org_id );
#diag( "child_org:" . $child_org->org_id );
#diag( "grandchild_org:" . $grandchild_org->org_id );

#$user->clear_authz_caches();
#AIR2Test::Organization->clear_caches();

ok( my $grandchild_parents
        = AIR2::Organization::get_org_parents( $grandchild_org->org_id ),
    "get grandchild ancestors"
);

is_deeply( $grandchild_parents, [ $child_org->org_id, $org->org_id ],
    "ancestors ok" );

ok( my $tkt       = $user->create_tkt(),  "create auth tkt" );
ok( my $small_tkt = $user->create_tkt(1), "create small auth tkt" );
ok( my $at = $user->get_new_air2_auth_tkt, "get AIR2::AuthTkt object" );
ok( $at->valid_ticket($tkt),       "ticket is valid" );
ok( $at->valid_ticket($small_tkt), "small ticket is valid" );
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

ok( my $small_authz = AIR2::Utils::unpack_authz(
        decode_json( $at->parse_ticket($small_tkt)->{data} )->{authz}
    ),
    "get authz"
);
my $small_user_authz = $user->get_explicit_authz;
is_deeply( $small_authz, $small_user_authz, "small authz roundtrip struct" );

#diag( dump $small_user_authz );
#diag( dump $small_authz );

cmp_ok( length($small_tkt), '<', length($tkt), "small ticket is smaller" );
