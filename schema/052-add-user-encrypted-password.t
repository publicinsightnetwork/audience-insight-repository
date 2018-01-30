#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib/perl';
use Test::More tests => 2;
use AIR2::DBManager;
use Data::Dump qw( dump );
use Rose::DB::Object;
use Rose::DB::Object::Metadata;

# "our" to share between packages
our $DB = AIR2::DBManager->new_or_cached();

#############################################
# user

{

    package DummyUser;
    @DummyUser::ISA = ('Rose::DB::Object');

    sub init_db {
        return $main::DB;
    }
}

ok( my $user_meta = Rose::DB::Object::Metadata->new(
        table => 'user',
        class => 'DummyUser',
    ),
    "new user_meta"
);
$user_meta->auto_initialize();

my $has_encrypted_password = 0;
for my $col ( @{ $user_meta->columns } ) {
    if ( $col->name eq "user_encrypted_password" ) {
        $has_encrypted_password = 1;
    }
}

if ( !$has_encrypted_password ) {
    ok( $DB->dbh->do(
            "alter table user add column user_encrypted_password varchar(255)"
        ),
        "add user_encrypted_password"
    );
}
else {
    pass("user_encrypted_password already exists");
}
