#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Carp;
use Data::Dump qw( dump );
use AIR2::DBManager;
use AIR2::Source;

# perform sanity check on non-primary tables to make sure
# foreign key constraints are being enforced

my %source_classes = (
    'AIR2::SrcActivity'    => 'sact_src_id',
    'AIR2::SrcResponse'    => 'sr_src_id',
    'AIR2::SrcResponseSet' => 'srs_src_id',

    # TODO other related tables?
);

my %seen_sources;

for my $class ( sort keys %source_classes ) {

    my $column = $source_classes{$class};

    warn "checking $class for $column\n";

    my $objs = $class->fetch_all_iterator( inject_results => 1, );
    while ( my $o = $objs->next ) {
        my $src_id = $o->$column;
        if ( exists $seen_sources{$src_id} ) {
            if ( !$seen_sources{$src_id} ) {
                warn "No source for $class with $column=$src_id\n";
                $o->delete;
            }
            next;
        }
        my $source = AIR2::Source->new( src_id => $src_id )->load_speculative;
        if ( !$source or $source->not_found ) {
            warn "No source for $class with $column=$src_id\n";
            $o->delete;
            $seen_sources{$src_id} = 0;
        }
        else {
            $seen_sources{$src_id} = 1;
        }
    }

}

warn "checking AIR2::SrcResponse for valid Question\n";

my $responses = AIR2::SrcResponse->fetch_all_iterator( inject_results => 1 );
while ( my $resp = $responses->next ) {

    # does question really exist?
    if ( !$resp->question ) {
        warn "No Question for sr_ques_id " . $resp->sr_ques_id . "\n";
    }

}

# TODO other non-source entities?
