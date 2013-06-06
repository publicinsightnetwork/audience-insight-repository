#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib/perl';
use Test::More tests => 4;
use AIR2::DBManager;
use Data::Dump qw( dump );
use Rose::DB::Object;
use Rose::DB::Object::Metadata;

# "our" to share between packages
our $DB = AIR2::DBManager->new_or_cached();

#############################################
# tank_response_set

{

    package DummyTRS;
    @DummyTRS::ISA = ('Rose::DB::Object');

    sub init_db {
        return $main::DB;
    }
}

ok( my $trs_meta = Rose::DB::Object::Metadata->new(
        table => 'tank_response_set',
        class => 'DummyTRS',
    ),
    "new trs_meta"
);
$trs_meta->auto_initialize();

my $has_srs_uuid = 0;
for my $col ( @{ $trs_meta->columns } ) {

    #diag( $col->name );
    if ( $col->name eq "srs_uuid" ) {
        $has_srs_uuid = 1;
    }
}

if ( !$has_srs_uuid ) {
    ok( $DB->dbh->do(
            "alter table tank_response_set add column srs_uuid char(12)"),
        "add srs_uuid to tank_response_set"
    );
}
else {
    pass("srs_uuid already exists");
}

###################################################
# tank_response

{

    package DummyTR;
    @DummyTR::ISA = ('Rose::DB::Object');

    sub init_db {
        return $main::DB;
    }
}
ok( my $tr_meta = Rose::DB::Object::Metadata->new(
        table => 'tank_response',
        class => 'DummyTR',
    ),
    "new tr_meta"
);
$tr_meta->auto_initialize();

my $has_sr_uuid = 0;
for my $col ( @{ $tr_meta->columns } ) {

    #diag( $col->name );
    if ( $col->name eq "sr_uuid" ) {
        $has_sr_uuid = 1;
    }
}

if ( !$has_sr_uuid ) {
    ok( $DB->dbh->do("alter table tank_response add column sr_uuid char(12)"),
        "add sr_uuid to tank_response" );
}
else {
    pass("sr_uuid already exists");
}
