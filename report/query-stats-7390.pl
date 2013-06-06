#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Carp;
use AIR2::Config;
use AIR2::Inquiry;
use Text::CSV_XS;
use Data::Dump qw( dump );

#$Rose::DB::Object::Manager::Debug = 1;

my $csv = Text::CSV_XS->new( { always_quote => 1 } );
my @headers = qw(
    uuid
    title
    date
    org
    submissions
    emails
);
$csv->combine(@headers);
print $csv->string() . "\r\n";

my $inqs = AIR2::Inquiry->fetch_all_iterator(
    query => [],
    @ARGV
);

while ( my $inq = $inqs->next ) {

    my @fields;
    push @fields, $inq->inq_uuid;
    push @fields, $inq->get_title();
    push @fields, $inq->get_published_dtim();
    push @fields, join( ';', map { $_->org_name } @{ $inq->organizations } );
    push @fields, $inq->has_related('src_response_sets');
    push @fields, $inq->has_related('src_inquiries');

    if ( !$csv->combine(@fields) ) {
        croak "Failed to CSV->combine fields: "
            . $csv->error_input() . " : "
            . dump( \@fields );
    }
    print $csv->string() . "\r\n";

}

