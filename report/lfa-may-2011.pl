#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Carp;
use AIR2::Config;
use AIR2::Source;
use Text::CSV_XS;
use Data::Dump qw( dump );

#$Rose::DB::Object::Manager::Debug = 1;

my $csv = Text::CSV_XS->new( { always_quote => 1 } );
my $sources = AIR2::Source->fetch_all_iterator(
    query => [ src_status => [qw(A E)] ],
    @ARGV
);

while ( my $src = $sources->next ) {
    next unless $src->get_primary_email;
    my @fields;
    push @fields, $src->src_uuid;
    push @fields, $src->get_primary_email->sem_email;
    push @fields, $src->get_anchor_newsroom;
    push @fields, $src->get_ethnicity;
    push @fields, $src->get_income;
    push @fields, $src->get_edu_level;
    push @fields, $src->get_pol_affiliation;
    push @fields, $src->get_dob;
    push @fields, $src->get_gender;
    push @fields, $src->src_cre_dtim;
    push @fields, $src->query_activity_count;
    push @fields, $src->avg_query_rate;
    push @fields, $src->response_sets_count;
    push @fields, $src->src_has_acct;

    if ( !$csv->combine(@fields) ) {
        croak "Failed to CSV->combine fields: "
            . $csv->error_input() . " : "
            . dump( \@fields );
    }
    print $csv->string() . "\r\n";

}

