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
use AIR2::Source;
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

umask(0007);    # group rw, world null

my $help      = 0;
my $quiet     = 0;
my $mod_since = 0;
my $debug     = 0;
my $base_dir  = AIR2::Config->get_search_xml->subdir('sources');
my $pk_filelist;
my $offset;
my $limit;
my $column_name = 'src_id';
my $dry_run;
GetOptions(
    'help'             => \$help,
    'modified_since=s' => \$mod_since,
    'debug'            => \$debug,
    'quiet'            => \$quiet,
    'base_dir=s'       => \$base_dir,
    'from_file=s'      => \$pk_filelist,
    'offset=i'         => \$offset,
    'limit=i'          => \$limit,
    'use_column=s'     => \$column_name,
    'dry_run'          => \$dry_run,
) or pod2usage(2);
pod2usage(1) if $help;

$Rose::DB::Object::Debug          = $debug;
$Rose::DB::Object::Manager::Debug = $debug;

=pod

=head1 NAME

sources2xml.pl - convert db records to XML for indexing

=head1 SYNOPSIS

 sources2xml.pl [opts] [src_idN .. src_idNN]
    --help
    --modified_since y-m-d
    --from_file filename
    --use_column colname
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
    AIR2::Utils::logger("Determining which Source records to serialize...\n");
}

my $pks = AIR2::SearchUtils::get_pks_to_index(
    lock_file   => $lock_file,
    class       => 'AIR2::Source',
    column      => $column_name,
    mod_since   => $mod_since,
    quiet       => $quiet,
    debug       => $debug,
    pk_filelist => $pk_filelist,
    argv        => \@ARGV,
    offset      => $offset,
    limit       => $limit,
    dry_run     => $dry_run,
);
my $progress      = Term::ProgressBar::Simple->new( $pks->{total_expected} );
my $count         = 0;
my $organizations = AIR2::SearchUtils::all_organizations_by_id();
my $facts         = AIR2::SearchUtils::all_facts_by_id();
my $fact_values   = AIR2::SearchUtils::all_fact_values_by_id();
my $activity_master = AIR2::SearchUtils::get_activity_master();

for my $src_id ( @{ $pks->{ids} } ) {

    my $source
        = AIR2::Source->new( $column_name => $src_id )->load_speculative();
    if ( !$source or $source->not_found ) {
        warn "No Source found where $column_name=$src_id. Skipping.\n";
        next;
    }

    $dry_run or make_xml($source);
    unless ($quiet) {
        $progress++;
    }

}

$lock_file->unlock;
unless ($quiet) {
    AIR2::Utils::logger("Done.\n");
}

sub make_xml {
    my $source = shift;
    my $pk     = $source->src_uuid;

    $debug and warn "serializing source object $pk";

    my $xml = $source->as_xml(
        {   base_dir        => $base_dir,
            fact_values     => $fact_values,
            facts           => $facts,
            organizations   => $organizations,
            activity_master => $activity_master,
            debug           => $debug,
        }
    );

    AIR2::SearchUtils::write_xml_file(
        debug    => $debug,
        pk       => $pk,
        base     => $base_dir,
        xml      => $xml,
        pretty   => 0,
        compress => 0,
    );

}
