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
use AIR2::Project;
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
use Rose::DateTime::Parser;
use Search::Tools::XML;

umask(0007);    # group rw, world null

my $help      = 0;
my $quiet     = 0;
my $mod_since = 0;
my $debug     = 0;
my $base_dir  = AIR2::Config->get_search_xml->subdir('projects');
my $pk_filelist;
my $offset;
my $limit;
my $touch_stale_kids;
GetOptions(
    'help'             => \$help,
    'modified_since=s' => \$mod_since,
    'debug'            => \$debug,
    'quiet'            => \$quiet,
    'base_dir=s'       => \$base_dir,
    'from_file=s'      => \$pk_filelist,
    'offset=i'         => \$offset,
    'limit=i'          => \$limit,
    'touch_stale_kids' => \$touch_stale_kids,
) or pod2usage(2);
pod2usage(1) if $help;

=pod

=head1 NAME

projects2xml.pl - convert db records to XML for indexing

=head1 SYNOPSIS

 projects2xml.pl [opts] [src_idN .. src_idNN]
    --help
    --modified_since y-m-d
    --from_file filename
    --debug
    --quiet
    --base_dir path/to/xml
    --offset N
    --limit N
    --touch_stale_kids

=cut

$base_dir = Path::Class::dir($base_dir);
$base_dir->mkpath(1);

my $lock_file = AIR2::SearchUtils::get_lockfile_on_xml_dir($base_dir);
if ( $mod_since eq 'last_mod' ) {
    $mod_since = "$lock_file";
}

unless ($quiet) {
    AIR2::Utils::logger(
        "Determining which Project records to serialize...\n");
}

my $pks = AIR2::SearchUtils::get_pks_to_index(
    lock_file   => $lock_file,
    class       => 'AIR2::Project',
    column      => 'prj_id',
    mod_since   => $mod_since,
    quiet       => $quiet,
    debug       => $debug,
    pk_filelist => $pk_filelist,
    argv        => \@ARGV,
    offset      => $offset,
    limit       => $limit,
);
my $progress = Term::ProgressBar::Simple->new( $pks->{total_expected} );
my $count    = 0;

for my $proj_id ( @{ $pks->{ids} } ) {

    my $proj
        = AIR2::Project->new( prj_id => $proj_id )->load( speculative => 1 );
    if ( !$proj or $proj->not_found ) {
        warn "No Project found where prj_id=$proj_id. Skipping.\n";
        next;
    }

    make_xml($proj);

    # optionally flag all its children as stale,
    # e.g., it is possible that authz changed.
    if ($touch_stale_kids) {
        my $inqs = $proj->inquiries_iterator;
        while ( my $inq = $inqs->next ) {
            AIR2::SearchUtils::touch_stale($inq);
            my $resps = $inq->src_response_sets_iterator;
            while ( my $r = $resps->next ) {
                AIR2::SearchUtils::touch_stale($r);
            }
        }
    }

    unless ($quiet) {
        $progress++;
    }

}

$lock_file->unlock;
unless ($quiet) {
    AIR2::Utils::logger("Done.\n");
}

sub make_xml {
    my $proj = shift;
    my $pk   = $proj->prj_uuid;
    $debug and warn "serializing Project object $pk";

    my $xml = $proj->as_xml(
        {   base_dir => $base_dir,
            debug    => $debug,
        }
    );

    AIR2::SearchUtils::write_xml_file(
        pk   => $pk,
        base => $base_dir,
        xml  => $xml,
    );

    # if this was a stale record, zap the stale record
    $proj->db->get_write_handle->dbh->do(
        "delete from stale_record where str_type = 'P' and str_xid = ?",
        {}, $proj->prj_id );
}
