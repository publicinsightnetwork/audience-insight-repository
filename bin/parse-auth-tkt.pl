#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Data::Dump qw( dump );
use AIR2::Config;
use AIR2::AuthTkt;
use JSON;
use AIR2::Utils;

my $AUTHTKT_CONF
    = AIR2::Config::get_app_root->subdir('etc')->file('auth_tkt.conf');

my $at = AIR2::AuthTkt->new(
    conf      => $AUTHTKT_CONF,
    ignore_ip => 1,
    debug     => 1,
);

for my $tkt (@ARGV) {
    dump( $at->parse_ticket($tkt) );
    my $authz = AIR2::Utils::unpack_authz(
        decode_json( $at->parse_ticket($tkt)->{data} )->{authz} );
    dump($authz);
}
