#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib/perl';
use Test::More tests => 5;
use AIR2::DBManager;
use Data::Dump qw( dump );

ok( my $db_slave = AIR2::DBManager->new_or_cached(), "new db slave" );
$ENV{AIR2_USE_MASTER} = 1;
ok( my $db_master = AIR2::DBManager->new_or_cached(), "new db master" );
is( $db_master->domain,
    AIR2::DBManager->get_master_domain_for( $db_slave->domain ),
    "master domain"
);

#$db_slave->logger('ima slave');
#$db_master->logger('ima master');

# test slave failure auto-rollover to master
$ENV{AIR2_USE_MASTER} = 0;
ok( my $db = AIR2::DBManager->new_or_cached( domain => 'nosuchdbhost' ),
    "get db handle for non-existent slave" );
#$db->logger('ima master posing as slave');
is( $db->domain, 'nosuchdbhost_master', "got master domain" );
