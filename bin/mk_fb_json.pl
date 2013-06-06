#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Carp;
use File::Slurp;
use Path::Class;
use Data::Dump qw( dump );
use JSON;
use AIR2::Organization;
use AIR2::Project;
use AIR2::Config;

my $org_json_file = AIR2::Config::get_shared_dir()->file('air2/json/orgs.json');
my $prj_json_file = AIR2::Config::get_shared_dir()->file('air2/json/prjs.json');

my %orgs;
my %prjs;

my $org_i
    = AIR2::Organization->fetch_all_iterator( query => [ org_status => ['A','P'] ] );
my $prj_i = AIR2::Project->fetch_all_iterator( query => [ prj_status => 'A' ] );

while ( my $o = $org_i->next ) {
    $orgs{ $o->org_uuid } = $o->org_display_name;
}

while ( my $p = $prj_i->next ) {
    $prjs{ $p->prj_uuid } = $p->prj_display_name;
}

my $json     = JSON->new;
my $org_json = $json->pretty->encode( \%orgs );
my $prj_json = $json->pretty->encode( \%prjs );

file($org_json_file)->dir->mkpath();
write_file( "$org_json_file", $org_json );
write_file( "$prj_json_file", $prj_json );

