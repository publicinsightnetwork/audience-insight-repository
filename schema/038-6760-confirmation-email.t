#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib/perl';
use Test::More tests => 2;
use AIR2::DBManager;
use AIR2::ActivityMaster;
use Data::Dump qw( dump );

#
# Redmine #6760
#

ok( my $actm = AIR2::ActivityMaster->new( actm_id => 48 ),
    "new activity master object" );
if ( $actm->load_speculative ) {
    pass("record exists");
}
else {
    $actm->actm_name('Submission confirmation email sent');
    $actm->actm_type('R');
    $actm->actm_table_type('S');
    $actm->actm_contact_rule_flag(0);
    ok( $actm->save(), "record created" );
}
