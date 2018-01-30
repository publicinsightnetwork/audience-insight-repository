#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib/perl';
use Test::More;
#use AIR2::DBManager;
use AIR2::SearchUtils;
use AIR2::Config;
use AIR2::Fact;
use Data::Dump qw( dump );

# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

#
# add facts for missing religions
#

my $facts = AIR2::SearchUtils::all_fact_values_map();

#dump $facts;

if ( exists $facts->{religion}->{Islam}
    and !exists $facts->{religion}->{Muslim} )
{
    my $islam
        = AIR2::FactValue->new( fv_id => $facts->{religion}->{Islam} )->load;
    $islam->fv_value('Muslim');
    ok( $islam->save(), "update Islam -> Muslim" );
}
else {
    pass("Islam already -> Muslim");
}

if ( !exists $facts->{religion}->{"Christian (Mormon)"} ) {
    my $mormon = AIR2::FactValue->new(
        fv_value   => "Christian (Mormon)",
        fv_fact_id => $facts->{religion}->{fact_id}
    );
    ok( $mormon->save(), "create Christian (Mormon)" );
}
else {
    pass("Christian (Mormon) already exists");
}

done_testing();
