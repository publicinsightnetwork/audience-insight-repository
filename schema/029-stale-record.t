#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib/perl';
use Test::More tests => 1;
use AIR2::DBManager;
use Data::Dump qw( dump );

my $db  = AIR2::DBManager->new->get_write_handle();
my $dbh = $db->dbh;

sub check_for_table {
    my $sth = $dbh->prepare('show tables');
    $sth->execute;
    my $has_table;
    while ( my $r = $sth->fetch ) {
        if ( $r->[0] eq 'stale_record' ) {
            $has_table = 1;
        }
    }
    return $has_table;
}

if ( check_for_table() ) {
    pass("stale_record table exists");
}
else {
    my $sql = <<SQL;

create table stale_record (
    str_xid         integer not null,
    str_upd_dtim    datetime not null,
    str_type        char(1) not null,
    PRIMARY KEY(str_xid,str_type)
)
SQL

    #diag($sql);
    $dbh->do($sql);
    ok( check_for_table(), "table created" );
}

