#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw( dump );
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Getopt::Long;
use Text::CSV::Slurp;
use AIR2::SrcFact;
use AIR2::TranslationMap;
use AIR2::FactValue;
use Carp;

my $fact_value;
my $fact_id;
my $check_mapped;
my $file = $ARGV[0] or die "usage: $0 file.csv\n";

my $data = Text::CSV::Slurp->load( file => $file );
for my $row (@$data) {
    $fact_value = AIR2::FactValue->fetch_all_iterator(
        query => [
            'fv_fact_id' => $row->{'fact_id'},
            'fv_value'   => $row->{'translated_value'},
        ]
    );
    my $already_mapped = '';
    if ( $row->{'translated_value'} ne '' ) {
        $check_mapped = AIR2::TranslationMap->fetch_all_iterator(
            query => [ 'xm_xlate_from' => $row->{'source_value'}, ] );
        $already_mapped = $check_mapped->next;
        if ( $already_mapped ne 0 && $already_mapped ne '') {
            dump(
                "$already_mapped->{ 'xm_xlate_from' } has already been mapped. Skipping."
            );
        }
    }
    my $fv_id;
    if ( $row->{'translated_value'} ne ''
        && ($already_mapped eq '' || $already_mapped eq 0))
    {
        while ( my $fv = $fact_value->next ) {
            $fv_id = $fv->fv_id;
        }

        if( $fv_id ne '' ) {
            my $translation_map = AIR2::TranslationMap->new(
                xm_fact_id        => $row->{'fact_id'},
                xm_xlate_from     => $row->{'source_value'},
                xm_xlate_to_fv_id => $fv_id,
            );
            eval {
                $translation_map->save();
            };
            if ( $@ ) {
                dump ("Exception thrown when mapping $row->{'source_value'} to $row->{'translated_value'}");
            }
        }
        else {
            dump ("Could not map $row->{'source_value'} to $row->{'translated_value'}, translated value is not a valid fact value");
        }
    }
}

