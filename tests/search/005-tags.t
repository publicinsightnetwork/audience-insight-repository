#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use lib 'tests/search';
use AIR2TestUtils;    # sets lib path
use Data::Dump qw( dump );
use AIR2::Inquiry;

SKIP: {

    if ( !AIR2TestUtils::search_env_ok() ) {
        skip "The search env does not look sane. Skipping all tests", 3; 
    }

    ok( my $inq = AIR2::Inquiry->new( inq_id => 12 )->load, "load Inquiry" );
    ok( my $tags = $inq->get_tags, "get_tags" );
    is( scalar @$tags, 1, "one tag" );

    #dump( [ map { $_->get_name } @$tags ] );

}
