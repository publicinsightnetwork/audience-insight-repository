#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use AIR2::Utils;

for my $word (qw( YES Y yes yEs SI si Sí )) {
    ok( AIR2::Utils::looks_like_yes($word), "$word" );
}

