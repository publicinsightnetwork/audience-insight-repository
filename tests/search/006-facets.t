#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use lib 'tests/search';
use AIR2TestUtils;    # sets lib path
use Data::Dump qw( dump );
use AIR2::Search::Engine::Sources;
use AIR2::Config;

###########################################
##    dates
###########################################
my $tz = AIR2::Config::get_tz();
my $now_dt = DateTime->now( time_zone => $tz );

sub days_ago {
    my $days = shift;
    return $now_dt->clone->subtract( days => $days )->ymd('');
}

my $today     = days_ago(0);
my $seven     = days_ago(7);
my $eight     = days_ago(8);
my $fifteen   = days_ago(15);
my $sixteen   = days_ago(16);
my $thirty    = days_ago(30);
my $thirtyone = days_ago(31);
my $sixty     = days_ago(60);
my $sixtyone  = days_ago(61);
my $ninety    = days_ago(90);
my $hundred   = days_ago(100);
my $raw_dates = [
    {   term  => $sixteen,
        count => 5,
    },
    {   term  => $fifteen,
        count => 6,
    },
    {   term  => $seven,
        count => 3,
    },
    {   term  => $thirty,
        count => 10,
    },
    {   term  => $sixty,
        count => 20,
    },
    {   term  => $ninety,
        count => 40,
    },
    {   term  => $hundred,
        count => 70,
    },
];

my $expected = [
    {   count => 3,
        label => "0..7 days",
        term  => "($seven..$today)"
    },
    {   count => 6,
        label => "8..15 days",
        term  => "($fifteen..$eight)"
    },
    {   count => 15,
        label => "16..30 days",
        term  => "($thirty..$sixteen)"
    },
    {   count => 20,
        label => "31..60 days",
        term  => "($sixty..$thirtyone)"
    },
    {   count => 40,
        label => "61..90 days",
        term  => "($ninety..$sixtyone)"
    },
    {   count => 70,
        label => "90+ days",
        term  => "(19000101.." . ( $ninety - 1 ) . ")",
    },
];

ok( my $baked_dates
        = AIR2::Search::Engine->_do_date_range_summary($raw_dates),
    "date_range_summary"
);

#dump($expected);
#dump($baked_dates);

is_deeply( $baked_dates, $expected, "date range facets baked correctly" );

#############################
## zip codes
#############################

my $zips = [
    {   term  => '12345',
        count => 10,
    },
    {   term  => '12346',
        count => 5,
    },
    {   term  => '56789',
        count => 1,
    },
    {   term  => '56780',
        count => 100,
    },
];

ok( my $baked_zips
        = AIR2::Search::Engine::Sources->_summarize_smadd_zip($zips),
    "summarize zips"
);

#dump($baked_zips);

my $expected_zips = [
    undef,
    {   count  => 15,
        threes => {
            123 => {
                count => 15,
                fives =>
                    { 12345 => { count => 10 }, 12346 => { count => 5 } },
            },
        },
    },
    undef, undef, undef,
    {   count  => 101,
        threes => {
            567 => {
                count => 101,
                fives => {
                    56780 => { count => 100 },
                    56789 => { count => 1 }
                },
            },
        },
    },
];

is_deeply( $baked_zips, $expected_zips, "expected zips" );

