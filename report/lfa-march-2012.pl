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
my @headers = qw(
    src_uuid
    primary_email
    anchor_newsroom
    ethnicity
    income
    edu_level
    pol_affiliation
    dob
    gender
    last_experience_what
    last_experience_where
    last_interest
    src_cre_dtim
    query_activity_count
    avg_query_rate
    response_sets_count
    src_has_acct
);
$csv->combine(@headers);
print $csv->string() . "\r\n";

my $sources = AIR2::Source->fetch_all_iterator(
    query => [
        src_status   => [qw(A E)],
        src_cre_dtim => {lt => '2012-01-01 00:00:00'},
    ],
    @ARGV
);

while ( my $src = $sources->next ) {
    next unless $src->get_primary_email;

    # remove newlines in these funny fields
    my $interest = $src->last_interest;
    $interest =~ s/\r|\n//g if $interest;
    my $what = $src->last_experience_what;
    $what =~ s/\r|\n//g if $what;
    my $where = $src->last_experience_where;
    $where =~ s/\r|\n//g if $where;

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
    push @fields, $what;
    push @fields, $where;
    push @fields, $interest;
    push @fields, "".$src->src_cre_dtim;
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

