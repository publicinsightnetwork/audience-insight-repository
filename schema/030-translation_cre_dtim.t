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
my $xm_xlate_from_length;
for my $col ( @{ $translation_meta->columns } ) {
    if ( $col->name eq "xm_cre_dtim" ) {
        $has_cre_time = 1;
    }
    if ( $col->name eq 'xm_xlate_from' ) {
        $xm_xlate_from_length = $col->length;
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
if ( $xm_xlate_from_length != 255 ) {
    ok( $DB->dbh->do(
            "alter table translation_map modify xm_xlate_from varchar(255) not null"
        ),
        "modify xm_xlate_from varchar(255)"
    );
}
else {
    pass("xm_xlate_from length == $xm_xlate_from_length");
}

