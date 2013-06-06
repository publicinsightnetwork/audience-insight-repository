#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib/perl';
use Test::More tests => 10;
use AIR2::DBManager;
use Data::Dump qw( dump );

#
# Redmine #4954
#

my $db  = AIR2::DBManager->new->get_write_handle();
my $dbh = $db->dbh;

my @yes_actm_ids = qw(
    16
    17
    18
    30
    46
);

my @no_actm_ids = qw(
    1
    4
    6
    8
    10
);

for my $actm_id (@yes_actm_ids) {
    ok( $dbh->do(
            "UPDATE activity_master SET actm_contact_rule_flag=1 WHERE actm_id=$actm_id"
        ),
        "update actm_id $actm_id = 1"
    );
}

for my $actm_id (@no_actm_ids) {
    ok( $dbh->do(
            "UPDATE activity_master SET actm_contact_rule_flag=0 WHERE actm_id=$actm_id"
        ),
        "update actm_id $actm_id = 0"
    );
}
