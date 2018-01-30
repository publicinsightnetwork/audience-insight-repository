#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use lib 'tests/search';
use AIR2TestUtils;    # sets lib path
use Data::Dump qw( dump );
use AIR2::Search::Engine::Sources;
use AIR2::Config;

my $idx = $ENV{IDX} || AIR2::Config->get_search_index->subdir('sources');
ok( my $engine = AIR2::Search::Engine::Sources->new( index => ["$idx"] ),
    "new Engine" );

ok( my $resp = $engine->get_uuids_only(
        q          => 'swishlastmodified!:NULL',
        p          => 1_000_000,                   # bigger than our hit count
        u          => 2,                           # do not enforce p
        uuid_field => 'src_uuid',
    ),
    "get_uuids_only"
);

#diag( 'build_time: ' . $resp->build_time );
cmp_ok( $resp->build_time, '<', 1, 'sub-second build time' );

#diag( dump $resp );
