#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 10;
use LWP::UserAgent;
use FindBin;
use lib "$FindBin::Bin/../../lib/perl";
use AIR2::Config;
use JSON;
use Data::Dump qw( dump );
use Path::Class;

# set up dummy files
my $uuid = '1234567890ab';    # must be 12 chars
my $querys_dir = dir( AIR2::Config::get_constant('AIR2_QUERY_DOCROOT') );
my $dummy_query_html = $querys_dir->file( $uuid . '.html' );
my $dummy_query_json = $querys_dir->file( $uuid . '.json' );
$dummy_query_html->spew('i am html');
$dummy_query_json->spew('{"test":"i am json"}');

my $url     = AIR2::Config::get_constant('AIR2_BASE_URL') . 'q';
my $browser = LWP::UserAgent->new();

# /q/<uuid> => /querys/<uuid>.html
ok( my $resp = $browser->get("$url/$uuid"), "get $url/$uuid" );
is( $resp->decoded_content, 'i am html', "got html" );

# /q/<uuid>.json => /querys/<uuid>.json
ok( $resp = $browser->get("$url/$uuid.json"), "get $url/$uuid.json" );
is_deeply(
    decode_json( $resp->decoded_content ),
    { test => 'i am json' },
    "got json"
);

# /q/<uuid>.html => /querys/<uuid>.html
ok( $resp = $browser->get("$url/$uuid.html"), "get $url/$uuid.html" );
is( $resp->decoded_content, 'i am html', "got html" );

# /q/<uuid>/some-title => /querys/<uuid>.html
ok( $resp = $browser->get("$url/$uuid/some-title-here"),
    "get $url/$uuid/some-title-here" );
is( $resp->decoded_content, 'i am html', "got html" );

# jsonp
ok( $resp = $browser->get(
        AIR2::Config::get_constant('AIR2_BASE_URL')
            . "querys/$uuid.json?callback=foo&bar=blue"
    ),
    "get querys/$uuid.json?callback"
);

#diag( dump $resp );
is( $resp->decoded_content, 'foo({"test":"i am json"})', "jsonp response" );

# clean up
$dummy_query_html->remove();
$dummy_query_json->remove();
