#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 4;
use lib 'tests/search';
use AIR2TestUtils;
use AIR2::SearchUtils;
use Data::Dump qw( dump );
use Rose::DBx::TestDB;

my $db  = Rose::DBx::TestDB->new;
my $dbh = $db->retain_dbh;

# create temp table
$dbh->do('create table test ( id integer )') or die $dbh->errstr;

# seed temp table
for my $i ( 1 .. 1000 ) {
    $dbh->do("insert into test (id) values ($i)") or die $dbh->errstr;
}

# run the pool calculator.
ok( my $pools = AIR2::SearchUtils::get_pool_offsets(
        n_pools => 4,
        column  => 'id',
        table   => 'test',
        dbh     => $dbh,
    ),
    "get pools"
);

is_deeply(
    $pools,
    { total => 1000, limit => 250, offsets => [ 1, 251, 501, 751 ] },
    "got expected pools"
);

# more temp data, skipping some
for my $i ( 2000 .. 2050, 3000 .. 3500, 4500 .. 6000 ) {
    $dbh->do("insert into test (id) values ($i)") or die $dbh->errstr;
}

# run the pool calculator.
ok( my $scattered_pools = AIR2::SearchUtils::get_pool_offsets(
        n_pools => 4,
        column  => 'id',
        table   => 'test',
        dbh     => $dbh,
    ),
    "get scattered pools"
);

#diag( dump $scattered_pools );

is_deeply(
    $scattered_pools,
    { limit => 763, offsets => [ 1, 764, 3475, 5237 ], total => 3053 },
    "got expected pools"
);
