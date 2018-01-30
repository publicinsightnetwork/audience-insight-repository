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
use AIR2::Inquiry;
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
my $base_dir  = AIR2::Config->get_search_xml->subdir('inquiries');
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
) or pod2usage(2);
pod2usage(1) if $help;

=pod

=head1 NAME

inq2xml.pl - convert db records to XML for indexing

=head1 SYNOPSIS

 inq2xml.pl [opts] [src_idN .. src_idNN]
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
        "Determining which Inquiry records to serialize...\n");
}

my $pks = AIR2::SearchUtils::get_pks_to_index(
    lock_file   => $lock_file,
    class       => 'AIR2::Inquiry',
    column      => 'inq_id',
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
my $sources  = AIR2::SearchUtils::get_source_id_uuid_matrix();

for my $inq_id ( @{ $pks->{ids} } ) {

    my $inq
        = AIR2::Inquiry->new( inq_id => $inq_id )->load( speculative => 1 );
    if ( !$inq or $inq->not_found ) {
        warn "No Inquiry found where inq_id=$inq_id. Skipping.\n";
        next;
    }

    if (    $inq->inq_type ne AIR2::Inquiry::TYPE_FORMBUILDER
        and $inq->inq_type ne AIR2::Inquiry::TYPE_QUERYBUILDER
        and $inq->inq_type ne AIR2::Inquiry::TYPE_NONJOURN )
    {
        if ($debug) {
            AIR2::Utils::logger( "Inquiry $inq_id has type "
                    . $inq->inq_type
                    . " not allowed in search index. Skipping.\n" );
        }

        # if this was a stale record, zap the stale record
        $inq->db->get_write_handle->dbh->do(
            "delete from stale_record where str_type = 'I' and str_xid = ?",
            {}, $inq->inq_id );
        next;
    }

    make_xml($inq);
    unless ($quiet) {
        $progress++;
    }

}

$lock_file->unlock;
unless ($quiet) {
    AIR2::Utils::logger("Done.\n");
}

sub make_xml {
    my $inq = shift;
    my $pk  = $inq->inq_uuid;
    $debug and warn "serializing Inquiry object $pk";

    my $xml = $inq->as_xml(
        {   debug    => $debug,
            base_dir => $base_dir,
            sources  => $sources,
        }
    );

    AIR2::SearchUtils::write_xml_file(
        pk   => $pk,
        base => $base_dir,
        xml  => $xml,
        compress => 1,
    );

    # if this was a stale record, zap the stale record
    $inq->db->get_write_handle->dbh->do(
        "delete from stale_record where str_type = 'I' and str_xid = ?",
        {}, $inq->inq_id );
}
