#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use Test::More tests => 6;
use AIR2::User;

# mock Reader class
{

    package MyReader;
    my $count = 0;
    sub next { return ( $count++ < 100 ) }
}

my $reader = bless({}, 'MyReader');
my $user   = AIR2::User->new( user_id => 1 )->load;

use_ok('AIR2::Exporter');
ok( my $exporter = AIR2::Exporter->new(
        atomic     => 1,
        max_errors => 1,
        reader     => $reader,
        user       => $user,
    ),
    "new Exporter"
);
ok( $exporter->run(), "run()" );
is( $exporter->completed, 100, "100 completely exported" );
ok( my $report = $exporter->report, "get report" );
ok( !$exporter->errored, "no errors" );

