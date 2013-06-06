#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use Test::More;
use Data::Dump qw( dump );
use AIR2::Organization;
use JSON;

use_ok('AIR2::Reporter::Org');
ok( my $reporter = AIR2::Reporter::Org->new(), "new reporter" );
ok( $reporter->prepare_app, "prepare_app" );

my $orgs = AIR2::Organization->fetch_all;

# SHHHHHHHHHH!
$ENV{AIR2_QUIET} = 1;

for my $org (@$orgs) {
    ok( my $result = $reporter->do_report(
            { ignore_cache => 1, org_name => $org->org_name }
        ),
        "do_report for " . $org->org_name
    );

    # diag( dump $result );
    is( $result->total,       1,       "one total" );
    is( ref $result->results, 'ARRAY', "results is an ARRAY ref" );
}

done_testing( 3 + ( scalar(@$orgs) * 3 ) );
