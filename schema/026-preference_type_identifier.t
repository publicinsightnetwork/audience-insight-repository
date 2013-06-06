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

    package DummyPreferenceType;
    @DummyPreferenceType::ISA = ('Rose::DB::Object');

    sub init_db {
        return $main::DB;
    }
}

ok( my $preference_type_meta = Rose::DB::Object::Metadata->new(
        table => 'preference_type',
        class => 'DummyPreferenceType',
    ),
    "new preference_type_meta"
);
$preference_type_meta->auto_initialize();

my $has_pt_identifier = 0;
for my $col ( @{ $preference_type_meta->columns } ) {
    if ( $col->name eq "pt_identifier" ) {
        $has_pt_identifier = 1;
    }
}

if ( !$has_pt_identifier ) {
ok( $DB->dbh->do(
        "alter table preference_type add column pt_identifier  varchar(128)"
    ),
    "add pt_identifier varchar(128)"
);
} 
else {
    pass("pt_identifier already exists");
}
