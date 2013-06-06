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

my $reader = bless( {}, 'MyReader' );
my $user = AIR2::User->new( user_id => 1 )->load;

use_ok('AIR2::Importer');
ok( my $importer = AIR2::Importer->new(
        atomic     => 1,
        max_errors => 1,
        reader     => $reader,
        user       => $user,
    ),
    "new Importer"
);
ok( $importer->run(), "run()" );
is( $importer->completed, 100, "100 completely exported" );
ok( my $report = $importer->report, "get report" );
ok( !$importer->errored, "no errors" );

