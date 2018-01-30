#!/usr/bin/env perl
use strict;
use warnings;
use lib 'tests/search';
use AIR2TestUtils;
use Data::Dump qw( dump );
use Test::More tests => 8;
use AIR2::Source;

use_ok('AIR2::SearchUtils');

is( AIR2::SearchUtils::xml_path_for( '1234   ', Path::Class::dir('foo/bar') ),
    "foo/bar/1/2/1234.xml", "xml_path_for"
);
is( AIR2::SearchUtils::dtim_string_to_ymd('2010-03-29 06:30:45'),
    '20100329', "dtim_string_to_ymd" );

my $authz = {
    '1234' => 1,
    '5678' => 7,
    '9087' => 512,
    296    => 3_995_214_370,    # bigger than pack size n (unsigned short)
};

ok( my $authz_packed = AIR2::SearchUtils::pack_authz($authz), "pack_authz" );
is_deeply( $authz, AIR2::SearchUtils::unpack_authz($authz_packed),
    "unpack_authz" );

#diag( dump $authz );
#diag( $authz_packed );

my $debug     = 0;
my $quiet     = 1;
my $tmpdir    = AIR2::Config::get_tmp_dir->subdir('search');
$tmpdir->mkpath($debug);
my $lock_file = AIR2::SearchUtils::get_lockfile_on_xml_dir($tmpdir);
ok( my $pks = AIR2::SearchUtils::get_pks_to_index(
        lock_file => $lock_file,
        class     => 'AIR2::Source',
        column    => 'src_id',
        quiet     => $quiet,
        debug     => $debug,
        argv      => [qw( 1 2 3 4 5 6 7 8 9 10 11 12 )],
        offset    => 4,
        limit     => 7,
    ),
    "get_pks_to_index"
);

is_deeply( $pks->{ids}, [qw( 4 5 6 7 8 9 10 )], "got correct slice of ids" );
is( $pks->{total_expected}, 7, "got expected slice count" );

$lock_file->unlock();
