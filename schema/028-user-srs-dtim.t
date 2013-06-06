#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib/perl';
use Test::More tests => 3;
use AIR2::DBManager;
use Data::Dump qw( dump );
use Rose::DB::Object;
use Rose::DB::Object::Metadata;

# "our" to share between packages
our $DB = AIR2::DBManager->new_or_cached();

#############################################
# user_org

{

    package DummyUserSrs;
    @DummyUserSrs::ISA = ('Rose::DB::Object');

    sub init_db {
        return $main::DB;
    }
}

ok( my $user_meta = Rose::DB::Object::Metadata->new(
        table => 'user_srs',
        class => 'DummyUserSrs',
    ),
    "new user_meta"
);
$user_meta->auto_initialize();

my $has_cre_dtim = 0;
my $has_upd_dtim = 0;
for my $col ( @{ $user_meta->columns } ) {
    if ( $col->name eq "usrs_cre_dtim" ) {
        $has_cre_dtim = 1;
    }
    if ( $col->name eq "usrs_upd_dtim" ) {
        $has_upd_dtim = 1;
    }
}

if ( !$has_cre_dtim ) {
    ok( $DB->dbh->do(
            "alter table user_srs add column usrs_cre_dtim datetime not null"
        ),
        "add usrs_cre_dtim datetime"
    );
}
else {
    pass("usrs_cre_dtim already exists");
}

if ( !$has_upd_dtim ) {
    ok( $DB->dbh->do(
            "alter table user_srs add column usrs_upd_dtim datetime"
        ),
        "add usrs_upd_dtim datetime"
    );
}
else {
    pass("usrs_upd_dtim already exists");
}
