#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib/perl';
use Test::More tests => 2;
use AIR2::DBManager;
use AIR2::ActivityMaster;
use Data::Dump qw( dump );

#
# Redmine #7820
#

ok( my $actm = AIR2::ActivityMaster->new( actm_id => 49 ),
    "new activity master object" );
if ( $actm->load_speculative ) {
    pass("record exists");
}
else {
    $actm->actm_name('Query updated');
    $actm->actm_type('A');
    $actm->actm_table_type('P');
    $actm->actm_contact_rule_flag(0);
    ok( $actm->save(), "record created" );
}
