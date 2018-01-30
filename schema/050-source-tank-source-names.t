#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib/perl';
use schema::helpers;
use Test::More;
use Data::Dump qw( dump );

sub alter_varchar_255 {
    my $table_name = shift;
    my $colname    = shift;
    my $ddl        = shift;

    #dump [ split( /\n/, $ddl ) ];
    if ( $ddl =~ m/`$colname` varchar\(255\)/ ) {
        return 1;
    }
    my ($statement) = ( $ddl =~ m/(`$colname` varchar\(\d+\) .+),/ );
    $statement =~ s/varchar\(\d+\)/varchar(255)/;
    diag($statement);

    $schema::helpers::db->dbh->do(
        "alter table $table_name modify $statement");
}

ok( my $source_ddl = schema::helpers::get_table_def('source'),
    "get source DDL" );

ok( my $tank_source_ddl = schema::helpers::get_table_def('tank_source'),
    "get tank_source DDL" );

ok( alter_varchar_255( 'source', 'src_first_name', $source_ddl ),
    "source.src_first_name" );
ok( alter_varchar_255( 'source', 'src_last_name', $source_ddl ),
    "source.src_last_name" );
ok( alter_varchar_255( 'tank_source', 'src_first_name', $tank_source_ddl ),
    "tank_source.src_first_name" );
ok( alter_varchar_255( 'tank_source', 'src_last_name', $tank_source_ddl ),
    "tank_source.src_last_name" );

done_testing();
