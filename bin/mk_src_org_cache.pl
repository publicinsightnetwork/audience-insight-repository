#!/usr/bin/env perl
###########################################################################
#
#   Copyright 2010 American Public Media Group
#
#   This file is part of AIR2.
#
#   AIR2 is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   AIR2 is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
#
###########################################################################

use strict;
use warnings;
use Data::Dump qw( dump );
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use lib "$FindBin::Bin/../lib/shared/perl";
sub logger { AIR2::Utils::logger(@_) }

# AIR2 perl ORM
use AIR2::Config;
use AIR2::Utils;
use AIR2::Source;

use Getopt::Long;
my $usage = "Usage:\n    mk_src_org_cache.pl [-v] [srcid1 srcid2 ...]\n";
my $verbose;
GetOptions( 'verbose' => \$verbose, ) or die $usage;

# check for valid integer src_id args
for my $sid (@ARGV) {
    if ( $sid =~ /\D/ ) {
        print "Invalid src_id argument: '$sid'\n";
        print $usage;
        exit;
    }
}
my $wherein = ( scalar @ARGV ) ? join( ',', @ARGV ) : 0;

# get handles
my $dbm = AIR2::DBManager->new;
my $dbh = $dbm->get_write_handle->retain_dbh;

# run as transaction
$dbh->{AutoCommit} = 0;
$dbh->{RaiseError} = 1;

# drop existing cache table
my $drop = 'truncate src_org_cache';
if ($wherein) {
    $drop = "delete from src_org_cache where soc_src_id in ($wherein)";
}
$dbh->do($drop);

##################################
# helpers for mysql bulk inserts #
##################################
my $BULK_INSERT_SIZE = 1000;
my $bulk_size        = 0;
my %bulk_cache;

sub bulk_insert {
    my $src_id = shift or die "src_id required";
    my $org_id = shift or die "org_id required";
    my $status = shift or die "status required";

    # push onto the stack
    $bulk_size++;
    my @def = ( $org_id, $status );
    push( @{ $bulk_cache{$src_id} }, \@def );

    # insert when we hit the max size
    if ( $bulk_size >= $BULK_INSERT_SIZE ) {
        do_insert();
    }
}

sub do_insert {
    my $insert
        = "insert into src_org_cache (soc_src_id, soc_org_id, soc_status) values ";
    for my $src_id ( keys %bulk_cache ) {
        for my $def ( @{ $bulk_cache{$src_id} } ) {
            my $org_id = $def->[0];
            my $status = $def->[1];
            $insert .= "($src_id,$org_id,'$status'),";
        }
    }
    $insert = substr( $insert, 0, -1 );
    $dbh->do($insert);

    # clear cache
    $bulk_size  = 0;
    %bulk_cache = ();
}

###############################
# cache authz for all sources #
###############################
my $count  = 0;
my $select = "select src_id from source";
$select .= " where src_id in ($wherein)" if $wherein;
my $src_ids = $dbh->selectall_hashref( $select, "src_id" );

logger("Caching AIR2 Src Orgs...\n");

eval {

    for my $src_id ( keys %{$src_ids} ) {
        $count++;
        if ( $verbose && ( $count % 10000 ) == 0 ) {
            logger("Processed $count source rows\n");
        }

        my $authz_orgs = AIR2::Source::get_authz_status($src_id);
        for my $org_id ( keys %{$authz_orgs} ) {
            my $stat = $authz_orgs->{$org_id};
            bulk_insert( $src_id, $org_id, $stat );
        }
    }

    # insert any remaining
    do_insert();

    # commit all changes!
    $dbh->commit;
};

#######
# catch any errors #
#######
if ($@) {
    warn "\n!!! Transaction aborted!\n";
    warn "!!! Because: $@\n";
    warn "!!! Rolling back changes!\n";
    eval { $dbh->rollback };
}
else {
    logger("Finished $count Sources\n");
}
