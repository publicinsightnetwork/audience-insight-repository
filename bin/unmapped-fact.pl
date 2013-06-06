#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw( dump );
use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use Getopt::Long;
use Text::CSV_XS;
use AIR2::SrcFact;
use AIR2::TranslationMap;
use AIR2::FactValue;
use Carp;
sub logger { AIR2::Utils::logger(@_) }

# in case we are printing UTF8 characters,
# avoid the 'wide character' warning
binmode(STDOUT, ":utf8");

my $air2_db  = AIR2::DBManager->new()->get_write_handle;
my $air2_dbh = $air2_db->retain_dbh;

my $csv = Text::CSV_XS->new( { always_quote => 1 } );
my @headers = qw(
    fact_id
    fact_name
    source_value
    translated_value
);
$csv->combine(@headers);
print $csv->string() . "\r\n";

my $source_facts = AIR2::SrcFact->fetch_all_iterator(
    require_objects => [qw( fact )],
    query => [ 'fact.fact_identifier' => [qw(gender ethnicity religion)], ]
);

my $fact_id           = 0;
my $value             = '';
my $translation_fv_id = 0;
my %seen_values       = ();
while ( my $source_fact = $source_facts->next ) {
    $fact_id = $source_fact->sf_fact_id;
    $value   = $source_fact->sf_src_value;
    if ( $value and !$seen_values{$value}++ ) {
        $translation_fv_id
            = AIR2::TranslationMap->find_translation( $fact_id, $value );
        if ( !$translation_fv_id || $translation_fv_id == 0 ) {

            my @fields;
            push @fields, $fact_id;
            push @fields, $source_fact->fact->fact_identifier;
            push @fields, $value;

            if ( !$csv->combine(@fields) ) {
                croak "Failed to CSV->combine fields: "
                    . $csv->error_input() . " : "
                    . dump( \@fields );
            }
            print $csv->string() . "\r\n";

        }
    }

}
