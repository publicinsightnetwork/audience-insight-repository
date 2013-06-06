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

    package DummyTranslationMap;
    @DummyTranslationMap::ISA = ('Rose::DB::Object');

    sub init_db {
        return $main::DB;
    }
}

ok( my $translation_meta = Rose::DB::Object::Metadata->new(
        table => 'translation_map',
        class => 'DummyTranslationMap',
    ),
    "new translation_meta"
);
$translation_meta->auto_initialize();

my $has_cre_time = 0;
for my $col ( @{ $translation_meta->columns } ) {
    if ( $col->name eq "xm_cre_dtim" ) {
        $has_cre_time = 1;
    }
}

if ( !$has_cre_time ) {
ok( $DB->dbh->do(
        "alter table translation_map add column xm_cre_dtim datetime"
    ),
    "add xm_cre_dtim datetime"
);
} 
else {
    pass("xm_cre_dtim already exists");
}