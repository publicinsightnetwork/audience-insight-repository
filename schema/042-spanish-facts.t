#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib/perl';
use Test::More;
use AIR2::DBManager;
use AIR2::SearchUtils;
use AIR2::Config;
use AIR2::Fact;
use AIR2::TranslationMap;
use JSON;
use File::Slurp;
use Data::Dump qw( dump );

# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

#
# add facts for any missing spanish translations
#

my $QUESTION_TEMPLATES
    = decode_json(
    scalar read_file( AIR2::Config::get_constant('AIR2_QB_TEMPLATES_FILE') )
    );

#dump $QUESTION_TEMPLATES;

my $facts = AIR2::SearchUtils::all_facts_by_id();

my %table;
for my $fact_id ( sort { $a <=> $b } keys %$facts ) {
    my $fact = $facts->{$fact_id};
    $table{ $fact->fact_identifier }->{fact_id} = $fact_id;
    for my $fact_value (
        @{ $fact->find_fact_values( sort_by => 'fv_seq ASC' ) } )
    {
        next if $fact_value->fv_status ne 'A';
        my $label = $fact_value->fv_value;
        my $pk    = $fact_value->fv_id;
        $table{ $fact->fact_identifier }->{$label} = $pk;
    }
}

#dump \%table;

sub check_mapping {

    # verify we have a translation map entry for params
    my %arg      = @_;
    my $es_US    = delete $arg{to};
    my $mappings = AIR2::TranslationMap->fetch_all( query => [%arg], );
    if ( $mappings->[0] ) {
        pass("mapping for $es_US exists");
        return;
    }
    my $map = AIR2::TranslationMap->new(%arg)->save();
    pass("mapping for $es_US created");

}

# loop over english, look for spanish

# political
my $i = 0;
for my $v ( @{ $QUESTION_TEMPLATES->{political}->{ques_choices}->{en_US} } ) {
    my $en_US = $v->{value};
    my $es_US
        = $QUESTION_TEMPLATES->{political}->{ques_choices}->{es_US}->[ $i++ ]
        ->{value};

    diag("en_US=$en_US es_US=$es_US");

    if ( !exists $table{political_affiliation}->{$en_US} ) {
        warn "No fact exists for $en_US";
        next;
    }

    if ( !$es_US ) {
        next;
    }

    if ( exists $table{'political_affiliation'}->{$es_US} ) {
        pass("$es_US already exists");

        # make sure we have mapping too
        check_mapping(
            xm_fact_id        => $table{political_affiliation}->{fact_id},
            xm_xlate_from     => lc($es_US),
            xm_xlate_to_fv_id => $table{'political_affiliation'}->{$en_US},
            to                => $en_US
        );
        next;
    }

    my $en_fact = AIR2::FactValue->new(
        fv_id => $table{political_affiliation}->{$en_US} )->load();
    my $es_fact = AIR2::FactValue->new(
        fv_fact_id => $table{political_affiliation}->{fact_id},
        fv_seq     => $en_fact->fv_seq,
        fv_value   => $es_US,
        fv_loc_id  => 72,
    );
    $es_fact->save();
    pass("$es_US created");
    check_mapping(
        xm_fact_id        => $table{political_affiliation}->{fact_id},
        xm_xlate_from     => lc($es_US),
        xm_xlate_to_fv_id => $en_fact->fv_id,
        to                => $en_US
    );
}

# education
$i = 0;
for my $v ( @{ $QUESTION_TEMPLATES->{education}->{ques_choices}->{en_US} } ) {
    my $en_US = $v->{value};
    my $es_US
        = $QUESTION_TEMPLATES->{education}->{ques_choices}->{es_US}->[ $i++ ]
        ->{value};

    diag("en_US=$en_US es_US=$es_US");

    if ( !exists $table{education_level}->{$en_US} ) {
        warn "No fact exists for $en_US";
        next;
    }

    if ( !$es_US ) {
        next;
    }

    if ( exists $table{'education_level'}->{$es_US} ) {
        pass("$es_US already exists");
        check_mapping(
            xm_fact_id        => $table{education_level}->{fact_id},
            xm_xlate_from     => lc($es_US),
            xm_xlate_to_fv_id => $table{'education_level'}->{$en_US},
            to                => $en_US
        );
        next;
    }

    my $en_fact
        = AIR2::FactValue->new( fv_id => $table{education_level}->{$en_US} )
        ->load();
    my $es_fact = AIR2::FactValue->new(
        fv_fact_id => $table{education_level}->{fact_id},
        fv_seq     => $en_fact->fv_seq,
        fv_value   => $es_US,
        fv_loc_id  => 72,
    );
    $es_fact->save();
    pass("$es_US created");
    check_mapping(
        xm_fact_id        => $table{education_level}->{fact_id},
        xm_xlate_from     => lc($es_US),
        xm_xlate_to_fv_id => $en_fact->fv_id,
        to                => $en_US
    );
}

done_testing();
