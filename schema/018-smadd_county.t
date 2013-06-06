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
# src_mail_address

{

    package DummySMA;
    @DummySMA::ISA = ('Rose::DB::Object');

    sub init_db {
        return $main::DB;
    }
}

ok( my $sma_meta = Rose::DB::Object::Metadata->new(
        table => 'src_mail_address',
        class => 'DummySMA',
    ),
    "new sma_meta"
);
$sma_meta->auto_initialize();

my $has_smadd_county = 0;
for my $col ( @{ $sma_meta->columns } ) {

    #diag( $col->name );
    if ( $col->name eq "smadd_county" ) {
        $has_smadd_county = 1;
    }
}

if ( !$has_smadd_county ) {
    ok( $DB->dbh->do(
            "alter table src_mail_address add column smadd_county varchar(128)"
        ),
        "add smadd_county to src_mail_address"
    );
}
else {
    pass("smadd_county already exists");
}

