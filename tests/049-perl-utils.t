#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib/perl';
use lib 'tests/search';
use Test::More tests => 2;
use AIR2::Utils;
use AIR2TestUtils;
use AIR2Test::Inquiry;

is_deeply(
    AIR2::Utils::parse_phone_number('763.486.5359 (ext. 303)'),
    { number => '763.486.5359', ext => 303 },
    "parse xxx.xxx.xxxx (ext. xxx)"
);

my $inquiry = AIR2Test::Inquiry->new(
    inq_uuid  => 'i am a uuid',
    inq_title => '!@#$**&the color QUERY  ',
);
$inquiry->load_or_save();

#diag( 'AIR2_MYPIN2_URL=' . AIR2::Config::get_constant('AIR2_MYPIN2_URL') );
is( $inquiry->get_uri(),
    AIR2::Config::get_constant('AIR2_MYPIN2_URL')
        . "/en/insight/apmpin/iamauuid/the-color-query",
    "Inquiry->get_uri"
);
