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

my $has_srs_fb_approved_flag = 0;
my $has_srs_approved_flag    = 0;
for my $col ( @{ $trs_meta->columns } ) {

    #diag( $col->name );
    if ( $col->name eq "srs_fb_approved_flag" ) {
        $has_srs_fb_approved_flag = 1;
    }

    if ( $col->name eq 'srs_approved_flag' ) {
        $has_srs_approved_flag = 1;
    }
}

if ( !$has_srs_fb_approved_flag ) {

    # remove old column name if present
    if ($has_srs_approved_flag) {
        $DB->dbh->do(
            "alter table tank_response_set drop column srs_approved_flag");
    }
    ok( $DB->dbh->do(
            "alter table tank_response_set add column srs_fb_approved_flag tinyint(1) not null default 0"
        ),
        "add srs_fb_approved_flag to tank_response_set"
    );
}
else {
    pass("srs_fb_approved_flag already exists");
}

#############################################
# srs_response_set

{

    package DummySRS;
    @DummySRS::ISA = ('Rose::DB::Object');

    sub init_db {
        return $main::DB;
    }
}

ok( my $srs_meta = Rose::DB::Object::Metadata->new(
        table => 'src_response_set',
        class => 'DummySRS',
    ),
    "new srs_meta"
);
$srs_meta->auto_initialize();

$has_srs_fb_approved_flag = 0;
$has_srs_approved_flag    = 0;
for my $col ( @{ $srs_meta->columns } ) {

    #diag( $col->name );
    if ( $col->name eq "srs_fb_approved_flag" ) {
        $has_srs_fb_approved_flag = 1;
    }

    if ( $col->name eq 'srs_approved_flag' ) {
        $has_srs_approved_flag = 1;
    }
}

if ( !$has_srs_fb_approved_flag ) {

    # remove old column name if present
    if ($has_srs_approved_flag) {
        $DB->dbh->do(
            "alter table src_response_set drop column srs_approved_flag");
    }
    ok( $DB->dbh->do(
            "alter table src_response_set add column srs_fb_approved_flag tinyint(1) not null default 0"
        ),
        "add srs_fb_approved_flag to tank_response_set"
    );
}
else {
    pass("srs_fb_approved_flag already exists");
}
