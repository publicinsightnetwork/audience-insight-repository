#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib/perl';
use Test::More tests => 2;
use AIR2::DBManager;
use Data::Dump qw( dump );
use Dezi::Stats::DBI;
use SQL::Translator;

my $db  = AIR2::DBManager->new->get_write_handle();
my $dbh = $db->dbh;

sub check_for_dezi_stats_table {
    my $sth = $dbh->prepare('show tables');
    $sth->execute;
    my $has_dezi_stats;
    while ( my $r = $sth->fetch ) {
        if ( $r->[0] eq 'dezi_stats' ) {
            $has_dezi_stats = 1;
        }
    }
    return $has_dezi_stats;
}

sub check_for_dezi_stats_total {
    my $sth = $dbh->prepare('describe dezi_stats');
    $sth->execute;
    my $has_total_column = 0;
    while ( my $r = $sth->fetch ) {

        #dump( $r );
        if ( $r->[0] eq 'total' ) {
            $has_total_column = 1;
        }
    }
    return $has_total_column;
}

if ( check_for_dezi_stats_table() ) {
    pass("dezi_stats table exists");
}
else {
    my $sql        = Dezi::Stats::DBI::schema();
    my $translator = SQL::Translator->new(

        #debug             => 1,
        show_warnings     => 1,
        validate          => 1,
        quote_identifiers => 1,
        no_comments       => 1,
    );
    my $mysql = $translator->translate(
        from       => 'SQLite',
        to         => 'MySQL',
        datasource => \$sql
    ) or die $translator->error;

    # Translator adds extra statements that do() can't handle.
    $mysql =~ s/^.*(CREATE TABLE .+?\));.*$/$1/s;

    #diag($mysql);
    $dbh->do($mysql);
    ok( check_for_dezi_stats_table(), "dezi_stats table created" );
}

if ( check_for_dezi_stats_total() ) {
    pass("dezi_stats has total column");
}
else {
    $dbh->do('alter table dezi_stats add column total integer');
    ok( check_for_dezi_stats_total(), "dezi_stats.total column added" );
}

