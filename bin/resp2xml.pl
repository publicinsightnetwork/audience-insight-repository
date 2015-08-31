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
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Carp;
use AIR2::DBManager;
use AIR2::SrcResponseSet;
use AIR2::Utils;
use AIR2::SearchUtils;
use AIR2::Config;
use Rose::DBx::Object::Indexed::Indexer;
use File::Slurp;
use Path::Class;
use Data::Dump qw( dump );
use Term::ProgressBar::Simple;
use Getopt::Long;
use Pod::Usage;
use Search::Tools::XML;
use Parallel::Forker;
use List::MoreUtils qw( part );

umask(0007);    # group rw, world null

my $help        = 0;
my $quiet       = 0;
my $mod_since   = 0;
my $debug       = 0;
my $base_dir    = AIR2::Config->get_search_xml->subdir('responses');
my $nprocs      = AIR2::Config->get_profile_val('nprocs') || 1;
my $column_name = 'srs_id';
my $pk_filelist;
my $offset;
my $limit;
GetOptions(
    'help'             => \$help,
    'modified_since=s' => \$mod_since,
    'debug'            => \$debug,
    'quiet'            => \$quiet,
    'base_dir=s'       => \$base_dir,
    'from_file=s'      => \$pk_filelist,
    'offset=i'         => \$offset,
    'limit=i'          => \$limit,
    'nprocs=i'         => \$nprocs,
    'use_column=s'     => \$column_name,
) or pod2usage(2);
pod2usage(1) if $help;

$Rose::DB::Object::Debug          = $debug;
$Rose::DB::Object::Manager::Debug = $debug;

=pod

=head1 NAME

resp2xml.pl - convert db records to XML for indexing

=head1 SYNOPSIS

 resp2xml.pl [opts] [srs_idN .. srs_idNN]
    --help
    --modified_since y-m-d
    --from_file filename
    --debug
    --quiet
    --base_dir path/to/xml
    --offset N
    --limit N

=cut

$base_dir = Path::Class::dir($base_dir);
$base_dir->mkpath(1);

my $lock_file = AIR2::SearchUtils::get_lockfile_on_xml_dir($base_dir);

if ( $mod_since eq 'last_mod' ) {
    $mod_since = "$lock_file";
}

unless ($quiet) {
    AIR2::Utils::logger(
        "Determining which SrcResponseSet records to serialize...\n");
}

my $pks = AIR2::SearchUtils::get_pks_to_index(
    lock_file   => $lock_file,
    class       => 'AIR2::SrcResponseSet',
    column      => $column_name,
    mod_since   => $mod_since,
    quiet       => $quiet,
    debug       => $debug,
    pk_filelist => $pk_filelist,
    argv        => \@ARGV,
    offset      => $offset,
    limit       => $limit,
);
my $organizations = AIR2::SearchUtils::all_organizations_by_id();

# if nprocs > 1, we split the ids into $nprocs groups
# and fork a child for each group.
if ( $nprocs > 1 ) {
    my $manager = Parallel::Forker->new( use_sig_child => 1 );

    # signal handling (propagate death)
    $SIG{CHLD} = sub { Parallel::Forker::sig_child($manager) };
    $SIG{TERM} = sub {
        if ( $manager && $manager->in_parent ) {
            $manager->kill_tree_all('TERM');
            die "Quitting...\n";
        }
    };

    # divide up the PKs into pools
    my $i = 0;
    my @pk_pools = part { $i++ % $nprocs } @{ $pks->{ids} };

    # don't spawn empty workers
    if ( $nprocs > scalar @pk_pools ) {
        $nprocs = scalar @pk_pools;
    }

    # spawn workers, one per pool
    my $max_procs = $nprocs - 1;    # zero-based to match pk_pools

WORKER: for my $worker_n ( ( 0 .. $max_procs ) ) {

        my $process = $manager->schedule(
            name => sprintf( "worker %2s", $worker_n ),    # unique
            run_on_start => sub {
                my $proc  = shift;
                my $pool  = $pk_pools[$worker_n];
                my $n_pks = scalar @$pool;
                $quiet
                    or AIR2::Utils::logger(
                    sprintf(
                        "Starting %s with %s records\n",
                        $proc->name, $n_pks
                    )
                    );
                my $progress = Term::ProgressBar::Simple->new(
                    { count => $n_pks, name => $proc->name } );
                for my $srs_id (@$pool) {
                    write_xml($srs_id);
                    $quiet or $progress++;
                }
            },
            run_on_finish => sub {
                my ( $proc, $exit_status ) = @_;
                $quiet
                    or
                    AIR2::Utils::logger( sprintf "Child %s exited with %s\n",
                    $proc->name, $exit_status );
            },
        );
        $process->ready();
    }

    $manager->poll();        # start ready workers
    $manager->wait_all();    # block till we're done
}
else {

    my $progress = Term::ProgressBar::Simple->new( $pks->{total_expected} );
for my $srs_id ( @{ $pks->{ids} } ) {
        write_xml($srs_id);
        $quiet or $progress++;
    }

}

$lock_file->unlock;
unless ($quiet) {
    AIR2::Utils::logger("Done.\n");
}

sub write_xml {
    my ($srs_id) = @_;

    my $set = AIR2::SrcResponseSet->new( $column_name => $srs_id )
        ->load( speculative => 1 );
    if ( !$set or $set->not_found ) {
        warn
            "No SrcResponseSet found where $column_name=$srs_id . Skipping.\n";
        return;
    }
    make_xml($set);

    # if running incremental update, flag its parent as stale.
    # that way the count of total submissions get corrected.
    # see redmine #4275
    if ($mod_since) {
        my $inq = $set->inquiry;
        AIR2::SearchUtils::touch_stale($inq);
    }

    # if this was a stale record, zap the stale record
    $set->db->get_write_handle->dbh->do(
        "delete from stale_record where str_type = 'R' and str_xid = ?",
        {}, $set->srs_id );
}

sub make_xml {
    my $set = shift;
    my $pk  = $set->srs_uuid;

    $debug and warn "serializing object for $pk";

    my $xml = $set->as_xml(
        {   base_dir => $base_dir,
            debug    => $debug,
        }
    );

    AIR2::SearchUtils::write_xml_file(
        pk       => $pk,
        base     => $base_dir,
        xml      => $xml,
        pretty   => 0,
        compress => 0,
        debug    => $debug,
    );

}
