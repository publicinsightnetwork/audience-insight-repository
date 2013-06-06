#!/usr/bin/env perl
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use Test::More tests => 15;
use lib 'lib/perl';
use lib 'tests/search/models';
use AIR2Test::User;

my $user = AIR2Test::User->new(
    user_username   => 'joebobtester',
    user_first_name => 'joebob',
    user_last_name  => 'tester'
);
ok( $user->save, "save test user" );

ok( !$user->set_password('foo'), "can't set too-short password" );
is( $user->error, 'must be minimum of 8 characters', "got expected error" );
ok( !$user->set_password('FOO'), "can't set too-short password" );
is( $user->error, 'must be minimum of 8 characters', "got expected error" );
ok( !$user->set_password('FOObar'), "can't set too-short password" );
is( $user->error, 'must be minimum of 8 characters', "got expected error" );
ok( !$user->set_password('foobar123?'), "require UPPER" );
is( $user->error, 'must contain UPPER case', "got expected error" );
ok( !$user->set_password('Foobarabc'), "require symbol" );
is( $user->error, 'must contain punctuation', "got expected error" );
ok( !$user->set_password('FOOBAR123?'), "require lower" );
is( $user->error, 'must contain lower case', "got expected error" );

ok( $user->set_password('fooBar123?'),   "set valid password" );
ok( $user->check_password('fooBar123?'), "check password" );

