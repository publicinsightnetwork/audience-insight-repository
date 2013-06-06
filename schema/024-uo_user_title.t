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
# user_org

{

    package DummyUO;
    @DummyUO::ISA = ('Rose::DB::Object');

    sub init_db {
        return $main::DB;
    }
}

ok( my $uo_meta = Rose::DB::Object::Metadata->new(
        table => 'user_org',
        class => 'DummyUO',
    ),
    "new uo_meta"
);
$uo_meta->auto_initialize();

for my $col ( @{ $uo_meta->columns } ) {

    #diag( $col->name );
    if ( $col->name eq "uo_user_title" ) {
        if ( $col->length eq '64' ) {
            ok( $DB->dbh->do(
                    "alter table user_org modify uo_user_title varchar(255)"
                ),
                "alter uo_user_title to varchar(255)"
            );
        }
        else {
            pass("uo_user_title already varchar(255)");
        }
    }
}

