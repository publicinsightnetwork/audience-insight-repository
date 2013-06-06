#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib/perl';
use Test::More tests => 6;
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

my $has_srs_xuuid = 0;
for my $col ( @{ $trs_meta->columns } ) {

    #diag( $col->name );
    if ( $col->name eq "srs_xuuid" ) {
        $has_srs_xuuid = 1;
    }
}

if ( !$has_srs_xuuid ) {
    ok( $DB->dbh->do(
            "alter table tank_response_set add column srs_xuuid varchar(255)"
        ),
        "add srs_xuuid to tank_response_set"
    );
}
else {
    pass("srs_xuuid already exists");
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

$has_srs_xuuid = 0;
for my $col ( @{ $srs_meta->columns } ) {

    #diag( $col->name );
    if ( $col->name eq "srs_xuuid" ) {
        $has_srs_xuuid = 1;
    }
}

if ( !$has_srs_xuuid ) {
    ok( $DB->dbh->do(
            "alter table src_response_set add column srs_xuuid varchar(255)"
        ),
        "add srs_xuuid to src_response_set"
    );
}
else {
    pass("srs_xuuid already exists");
}

# add index on srs_xuuid and srs_type
my $dbh = $DB->retain_dbh;
my $sth = $dbh->prepare('show indexes from src_response_set');
$sth->execute;
my $has_srs_xuuid_idx;
my $has_srs_type_idx;
while ( my $idx = $sth->fetchrow_hashref ) {

    #diag( dump $idx );
    if ( $idx->{Key_name} eq 'srs_xuuid_idx' ) {
        $has_srs_xuuid_idx = 1;
    }
    if ( $idx->{Key_name} eq 'srs_type_idx' ) {
        $has_srs_type_idx = 1;
    }
}
if ($has_srs_xuuid_idx) {
    pass("has srs_xuuid_idx");
}
else {
    ok( $dbh->do(
            "alter table src_response_set add index srs_xuuid_idx (srs_xuuid)"
        ),
        "add srs_xuuid_idx"
    );
}
if ($has_srs_type_idx) {
    pass("has srs_type_idx");
}
else {
    ok( $dbh->do(
            "alter table src_response_set add index srs_type_idx (srs_type)"
        ),
        "add srs_typ_idx"
    );
}
