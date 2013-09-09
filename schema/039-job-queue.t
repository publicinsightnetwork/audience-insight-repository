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
# job_queue

{

    package DummyJQ;
    @DummyJQ::ISA = ('Rose::DB::Object');

    sub init_db {
        return $main::DB;
    }
}

ok( my $jq_meta = Rose::DB::Object::Metadata->new(
        table => 'job_queue',
        class => 'DummyJQ',
    ),
    "new jq_meta"
);
$jq_meta->auto_initialize();

my $has_jq_start_after_dtim = 0;
my $has_jq_type             = 0;
my $has_jq_xid              = 0;
for my $col ( @{ $jq_meta->columns } ) {

    #diag( $col->name );
    if ( $col->name eq "jq_start_after_dtim" ) {
        $has_jq_start_after_dtim = 1;
    }
    if ( $col->name eq 'jq_type' ) {
        $has_jq_type = 1;
    }
    if ( $col->name eq 'jq_xid' ) {
        $has_jq_xid = 1;
    }

}

if ( !$has_jq_start_after_dtim ) {

    ok( $DB->dbh->do(
            "alter table job_queue add column jq_start_after_dtim datetime"
        ),
        "add jq_start_after_dtim to job_queue"
    );
}
else {
    pass("jq_start_after_dtim already exists");
}

if ( !$has_jq_type ) {

    ok( $DB->dbh->do( "alter table job_queue add column jq_type char(1)" ),
        "add jq_type to job_queue" );
}
else {
    pass("jq_type already exists");
}

if ( !$has_jq_xid ) {

    ok( $DB->dbh->do( "alter table job_queue add column jq_xid integer" ),
        "add jq_xid to job_queue" );
}
else {
    pass("jq_xid already exists");
}
